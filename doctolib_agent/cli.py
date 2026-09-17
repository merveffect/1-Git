"""Komut satırı arayüzü."""
from __future__ import annotations

import argparse
import contextlib
import logging
import sys

from .agent import EMERGENCY_NOTICE, book_slots, build_client, closing_client, scan_once, watch
from .booker import browser_session, login_interactive
from .config import AgentConfig
from .intent import parse_intent
from .models import SearchIntent
from .notify import format_report, send_webhook


def _progress(msg: str) -> None:
    print(msg, flush=True)


def _show_intent(intent: SearchIntent) -> None:
    print("Anlaşılan istek")
    print(f"  Şikayet     : {intent.reason_summary}")
    print(f"  Uzmanlık    : {intent.specialty_label}  ({', '.join(intent.specialty_slugs)})")
    print(f"  Konum       : {intent.location_label or intent.location}")
    print(f"  Müsaitlik   : {intent.window_summary()}")
    print(f"  Tarih aralığı: {intent.earliest_date or 'bugünden'} → {intent.latest_date or 'ufka kadar'}")
    print(f"  Aciliyet    : {intent.urgency}")
    if intent.notes:
        print(f"  Not         : {intent.notes}")
    if intent.red_flags:
        print(EMERGENCY_NOTICE.format(flags="; ".join(intent.red_flags)))


def _confirm(prompt: str) -> bool:
    try:
        return input(f"{prompt} [e/H] ").strip().lower() in ("e", "evet", "y", "yes")
    except EOFError:
        return False


@contextlib.contextmanager
def _session(cfg: AgentConfig, dump: str | None):
    """Taşıma moduna göre istemciyi (gerekirse tarayıcıyla) hazırla."""
    if cfg.transport == "browser":
        with browser_session(cfg) as page:
            page.goto(cfg.base_url, wait_until="domcontentloaded")
            yield build_client(cfg, page=page, dump_dir=dump)
    else:
        with closing_client(cfg, dump_dir=dump) as client:
            yield client


def _run_search(args: argparse.Namespace, cfg: AgentConfig, keep_watching: bool) -> int:
    intent = parse_intent(args.text, cfg)
    _show_intent(intent)
    if intent.red_flags and not args.yes and not _confirm("Yine de randevu araması yapılsın mı?"):
        return 1
    print()

    with _session(cfg, args.dump) as client:
        if keep_watching:
            matches: list = []
            for matches in watch(cfg, intent, client, max_rounds=args.max_rounds, progress=_progress):
                pass
        else:
            matches = scan_once(cfg, intent, client, progress=_progress)

    print()
    report = format_report(matches, intent)
    print(report)
    send_webhook(report)

    if not matches:
        return 2

    if cfg.booking.mode == "notify":
        print("\n(booking.mode: notify — rezervasyon denenmedi.)")
        return 0

    if not args.yes and not _confirm(f"\nEn uygun slot ({matches[0].start:%d.%m %H:%M}) için rezervasyon denensin mi?"):
        print("İptal edildi.")
        return 0

    results = book_slots(cfg, matches, progress=_progress)
    ok = any(r.ok for r in results)
    for r in results:
        if r.screenshot_path:
            print(f"  ekran görüntüsü: {r.screenshot_path}")
    return 0 if ok or cfg.booking.mode == "assist" else 3


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(
        prog="doctolib-agent",
        description="Doctolib'de senin adına uygun randevu arar ve rezerve eder.",
    )
    parser.add_argument("-c", "--config", default="doctolib.yaml", help="YAML yapılandırma yolu")
    parser.add_argument("-v", "--verbose", action="store_true")
    parser.add_argument("--dump", metavar="DIR", help="Ham JSON cevaplarını bu klasöre yaz (hata ayıklama)")
    parser.add_argument(
        "--mode", choices=("notify", "assist", "auto"),
        help="Yapılandırmadaki booking.mode değerini geçersiz kıl",
    )
    parser.add_argument("-y", "--yes", action="store_true", help="Onay sorularını atla")

    sub = parser.add_subparsers(dest="command", required=True)

    sub.add_parser("login", help="Tarayıcıda Doctolib'e giriş yap ve oturumu kaydet")

    p_web = sub.add_parser("web", help="Telefondan kullanılan web arayüzünü başlat")
    p_web.add_argument("--host", default="127.0.0.1", help="Telefondan erişim için 0.0.0.0")
    p_web.add_argument("--port", type=int, default=8600)

    p_intent = sub.add_parser("intent", help="Sadece isteği çözümle, arama yapma")
    p_intent.add_argument("text")

    p_find = sub.add_parser("find", help="Bir kez tara ve sonuçları göster")
    p_find.add_argument("text", help="ör. 'Berlin'de boğaz ağrısı için KBB, salı/perşembe öğleden sonra'")

    p_watch = sub.add_parser("watch", help="Uygun slot çıkana kadar periyodik tara")
    p_watch.add_argument("text")
    p_watch.add_argument("--max-rounds", type=int, default=None, help="Tur sayısı tavanı")

    args = parser.parse_args(argv)
    logging.basicConfig(
        level=logging.DEBUG if args.verbose else logging.INFO,
        format="%(levelname)s %(name)s: %(message)s",
    )

    try:
        cfg = AgentConfig.load(args.config)
    except FileNotFoundError as exc:
        print(exc, file=sys.stderr)
        return 1

    if args.mode:
        cfg.booking.mode = args.mode  # type: ignore[assignment]

    if args.command == "login":
        return 0 if login_interactive(cfg) else 1

    if args.command == "web":
        # fastapi/uvicorn sadece bu komut için gerekli - tembel içe aktar.
        from .web.app import main as web_main

        return web_main(["--config", args.config, "--host", args.host, "--port", str(args.port)])

    if args.command == "intent":
        _show_intent(parse_intent(args.text, cfg))
        return 0

    if not hasattr(args, "max_rounds"):
        args.max_rounds = None

    missing = cfg.profile.missing_fields()
    if missing and cfg.booking.mode != "notify":
        print(f"Uyarı: profilde eksik alanlar var ({', '.join(missing)}) — "
              f"rezervasyon formu elle doldurma isteyebilir.\n", file=sys.stderr)

    return _run_search(args, cfg, keep_watching=args.command == "watch")


if __name__ == "__main__":
    raise SystemExit(main())
