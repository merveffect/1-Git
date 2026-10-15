#!/usr/bin/env python3
"""Turn a Revolut PDF statement into a CSV the finance tracker can import.

The app reads CSV, TSV, OFX and QFX; Revolut only offers PDF for a full year, so
this bridges the two. It is a standalone script with no dependencies.

    python3 finance/tools/revolut_statement_to_csv.py statement.pdf -o statement.csv

What it is careful about
------------------------
A Revolut statement is denominated in one currency, but a card payment abroad
shows two figures: what the account paid, and what the merchant charged in the
local currency on a "Revolut Rate" line. Only the first is money that left the
account. This script puts them in separate columns -- `Money out`/`Money in`
versus `Original amount`/`Original currency` -- so nothing downstream can add a
foreign figure into a total.

It also keeps the three sections of the statement apart. `Account transactions`
are the real ledger; `Pending` has not settled and `Reverted` was refunded, and
neither is part of the closing balance. By default only the account section is
written out.

Every run reconciles the parsed rows against the statement's own balance
summary and refuses to write a CSV that does not add up, which is the only real
guarantee that the columns were read correctly.
"""

from __future__ import annotations

import argparse
import csv
import re
import sys
import zlib
from collections import defaultdict
from datetime import datetime
from pathlib import Path

# ----------------------------------------------------------------- PDF plumbing

STREAM = re.compile(rb"stream\r?\n")
BFRANGE = re.compile(rb"beginbfrange(.*?)endbfrange", re.S)
BFCHAR = re.compile(rb"beginbfchar(.*?)endbfchar", re.S)
HEX = re.compile(rb"<([0-9A-Fa-f]+)>")

# A string literal, or one of the text-positioning operators we track.
STRING = re.compile(rb"\((?:\\.|[^\\()])*\)", re.S)
OPS = re.compile(
    rb"(?P<tm>[-\d.]+\s+[-\d.]+\s+[-\d.]+\s+[-\d.]+\s+(?P<tmx>[-\d.]+)\s+(?P<tmy>[-\d.]+)\s+Tm)"
    rb"|(?P<td>(?P<tdx>[-\d.]+)\s+(?P<tdy>[-\d.]+)\s+T[dD])"
    rb"|(?P<show>(?:\[(?:[^\[\]()]|\((?:\\.|[^\\()])*\))*\]\s*TJ)"
    rb"|(?:\((?:\\.|[^\\()])*\)\s*Tj))",
    re.S,
)

ESCAPES = {0x6E: 10, 0x72: 13, 0x74: 9, 0x62: 8, 0x66: 12}


def inflate(raw: bytes) -> bytes | None:
    try:
        return zlib.decompress(raw)
    except zlib.error:
        try:
            return zlib.decompressobj().decompress(raw)
        except zlib.error:
            return None


def streams(data: bytes):
    """Every decompressed stream in the file, in order."""
    for match in STREAM.finditer(data):
        start = match.end()
        end = data.find(b"endstream", start)
        if end < 0:
            continue
        out = inflate(data[start:end])
        if out is not None:
            yield out


def unescape(raw: bytes) -> bytes:
    """Resolve PDF string escapes, including the octal ones."""
    out = bytearray()
    i = 0
    while i < len(raw):
        char = raw[i]
        if char == 0x5C and i + 1 < len(raw):
            nxt = raw[i + 1]
            if 0x30 <= nxt <= 0x37:
                j, digits = i + 1, b""
                while j < len(raw) and len(digits) < 3 and 0x30 <= raw[j] <= 0x37:
                    digits += bytes([raw[j]])
                    j += 1
                out.append(int(digits, 8) & 0xFF)
                i = j
                continue
            out.append(ESCAPES.get(nxt, nxt))
            i += 2
            continue
        out.append(char)
        i += 1
    return bytes(out)


def build_cmap(data: bytes) -> dict[int, str]:
    """Read every /ToUnicode CMap into one glyph-code to character map.

    The fonts are subsets, so the codes are meaningless without this; guessing a
    fixed offset gets ASCII right and quietly corrupts everything else, which is
    how "Kulüp Müjgan" and the euro sign turn into noise.
    """
    cmap: dict[int, str] = {}
    for stream in streams(data):
        if b"begincmap" not in stream:
            continue
        for block in BFRANGE.findall(stream):
            for line in block.splitlines():
                codes = HEX.findall(line)
                if len(codes) != 3:
                    continue
                low, high, dst = (int(c, 16) for c in codes)
                for offset in range(high - low + 1):
                    cmap[low + offset] = chr(dst + offset)
        for block in BFCHAR.findall(stream):
            codes = HEX.findall(block)
            for src, dst in zip(codes[::2], codes[1::2]):
                raw = bytes.fromhex(dst.decode())
                cmap[int(src, 16)] = raw.decode("utf-16-be", "replace")
    if not cmap:
        raise SystemExit("no /ToUnicode map found - is this a Revolut PDF statement?")
    return cmap


def decode(raw: bytes, cmap: dict[int, str]) -> str:
    """Two-byte glyph codes to text."""
    return "".join(cmap.get((raw[i] << 8) | raw[i + 1], "") for i in range(0, len(raw) - 1, 2))


def pages(data: bytes, cmap: dict[int, str]) -> list[list[dict]]:
    """Positioned text runs, grouped per content stream (one per page here)."""
    out = []
    for stream in streams(data):
        if b"Tj" not in stream and b"TJ" not in stream:
            continue
        x = y = 0.0
        items = []
        for match in OPS.finditer(stream):
            if match.group("tm"):
                x, y = float(match.group("tmx")), float(match.group("tmy"))
            elif match.group("td"):
                x += float(match.group("tdx"))
                y += float(match.group("tdy"))
            else:
                text = "".join(
                    decode(unescape(lit[1:-1]), cmap) for lit in STRING.findall(match.group("show"))
                )
                if text.strip():
                    items.append({"x": round(x, 1), "y": round(y, 1), "text": text})
        if items:
            out.append(items)
    return out


# ------------------------------------------------------------------- statement

SECTIONS = {
    "Account transactions from": "account",
    "Pending from": "pending",
    "Reverted from": "reverted",
}
COLUMNS = {"Money out": "money_out", "Money in": "money_in", "Balance": "balance"}
DATE = re.compile(r"^([A-Z][a-z]{2} \d{1,2}, \d{4})$")
DETAIL = ("Reference:", "To:", "From:", "Card:", "Fee", "Description:")
# "979.99 TRY", "$5.95", "£4.20" - the merchant's own figure.
FOREIGN = re.compile(r"^([\d,]+\.\d{2})\s*([A-Z]{3})$|^([$£])\s*([\d,]+\.\d{2})$")
SYMBOLS = {"$": "USD", "£": "GBP"}


def money(text: str, currency_symbol: str) -> float | None:
    if not text.startswith(currency_symbol):
        return None
    try:
        return float(text[len(currency_symbol):].replace(",", ""))
    except ValueError:
        return None


def foreign(text: str) -> tuple[float, str] | None:
    match = FOREIGN.match(text)
    if not match:
        return None
    if match.group(1):
        return float(match.group(1).replace(",", "")), match.group(2)
    return float(match.group(4).replace(",", "")), SYMBOLS[match.group(3)]


def detect_symbol(items: list[dict]) -> str:
    """The statement's own currency sign, taken from the balance summary."""
    for page in items:
        for item in page:
            match = re.match(r"^(\D)[\d,]+\.\d{2}$", item["text"].strip())
            if match:
                return match.group(1)
    raise SystemExit("could not work out the statement currency")


def parse(data: bytes) -> tuple[list[dict], dict]:
    cmap = build_cmap(data)
    sheets = pages(data, cmap)
    symbol = detect_symbol(sheets)

    transactions: list[dict] = []
    summary: dict = {}
    section: str | None = None

    for sheet in sheets:
        rows: dict[float, list[dict]] = defaultdict(list)
        for item in sheet:
            rows[item["y"]].append(item)

        # Column positions come from this page's own header row.
        columns: dict[str, float] = {}
        for cells in rows.values():
            for cell in cells:
                if cell["text"].strip() in COLUMNS:
                    columns[cell["text"].strip()] = cell["x"]

        for y in sorted(rows, reverse=True):
            cells = sorted(rows[y], key=lambda c: c["x"])
            line = " ".join(c["text"] for c in cells)

            for marker, name in SECTIONS.items():
                if marker in line:
                    section = name

            # "Total | €934.28 | €20,759.63 | €19,918.41 | €93.06"
            if cells[0]["text"].strip() == "Total" and not summary:
                figures = [money(c["text"].strip(), symbol) for c in cells[1:]]
                figures = [f for f in figures if f is not None]
                if len(figures) == 4:
                    summary = dict(zip(("opening", "out", "in", "closing"), figures))

            if section is None:
                continue

            match = DATE.match(cells[0]["text"].strip())
            if match:
                transaction = {
                    "section": section,
                    "date": datetime.strptime(match.group(1), "%b %d, %Y").strftime("%Y-%m-%d"),
                    "description": "",
                    "details": [],
                    "money_out": None,
                    "money_in": None,
                    "balance": None,
                    "original_amount": None,
                    "original_currency": None,
                }
                for cell in cells[1:]:
                    text = cell["text"].strip()
                    value = money(text, symbol)
                    if value is not None and columns:
                        # Nearest header decides what the figure means, so an
                        # amount can never land in the wrong direction.
                        header = min(columns, key=lambda k: abs(columns[k] - cell["x"]))
                        key = COLUMNS[header]
                        if transaction[key] is None:
                            transaction[key] = value
                            continue
                    if not transaction["description"]:
                        transaction["description"] = text
                    else:
                        transaction["details"].append(text)
                transactions.append(transaction)
                continue

            if not transactions:
                continue

            # Continuation lines: the rate line carries the foreign original.
            current = transactions[-1]
            for cell in cells:
                pair = foreign(cell["text"].strip())
                if pair and current["original_amount"] is None:
                    current["original_amount"], current["original_currency"] = pair
            text = line.strip()
            if text.startswith(DETAIL):
                current["details"].append(text)

    if not summary:
        raise SystemExit("could not find the balance summary to reconcile against")
    return transactions, summary | {"symbol": symbol}


def reconcile(transactions: list[dict], summary: dict) -> list[str]:
    """Check the parsed account section against the statement's own summary."""
    account = [t for t in transactions if t["section"] == "account"]
    out = round(sum(t["money_out"] or 0 for t in account), 2)
    money_in = round(sum(t["money_in"] or 0 for t in account), 2)
    closing = round(summary["opening"] - out + money_in, 2)

    problems = []
    if abs(out - summary["out"]) >= 0.005:
        problems.append(f"money out {out:.2f} but the statement says {summary['out']:.2f}")
    if abs(money_in - summary["in"]) >= 0.005:
        problems.append(f"money in {money_in:.2f} but the statement says {summary['in']:.2f}")
    if abs(closing - summary["closing"]) >= 0.005:
        problems.append(f"closing balance {closing:.2f} but the statement says {summary['closing']:.2f}")
    return problems


# "Notes" is deliberately not called "Details": the app treats a second
# description-ish column as part of the description, and folding "To: ...  Card:
# ..." into every merchant name wrecks merchant grouping and recurring detection.
# The column is here to be read in a spreadsheet; the importer ignores it.
HEADER = [
    "Date", "Description", "Notes", "Money out", "Money in", "Balance",
    "Currency", "Original amount", "Original currency", "Section",
]


def write_csv(path: Path | None, transactions: list[dict], currency: str) -> None:
    handle = sys.stdout if path is None else path.open("w", newline="", encoding="utf-8")
    try:
        writer = csv.writer(handle)
        writer.writerow(HEADER)
        for t in transactions:
            writer.writerow([
                t["date"],
                t["description"],
                " · ".join(t["details"]),
                "" if t["money_out"] is None else f"{t['money_out']:.2f}",
                "" if t["money_in"] is None else f"{t['money_in']:.2f}",
                "" if t["balance"] is None else f"{t['balance']:.2f}",
                currency,
                "" if t["original_amount"] is None else f"{t['original_amount']:.2f}",
                t["original_currency"] or "",
                t["section"],
            ])
    finally:
        if handle is not sys.stdout:
            handle.close()


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    parser.add_argument("pdf", type=Path, help="the Revolut PDF statement")
    parser.add_argument("-o", "--out", type=Path, help="CSV to write (default: stdout)")
    parser.add_argument("--currency", default=None,
                        help="account currency code, e.g. EUR (default: read from the PDF)")
    parser.add_argument("--all", action="store_true",
                        help="also write the pending and reverted sections, which are not "
                             "part of the closing balance")
    args = parser.parse_args()

    data = args.pdf.read_bytes()
    transactions, summary = parse(data)

    symbol_codes = {"€": "EUR", "$": "USD", "£": "GBP"}
    currency = args.currency or symbol_codes.get(summary["symbol"])
    if not currency:
        return print(f"unknown currency sign {summary['symbol']!r}; pass --currency") or 2

    problems = reconcile(transactions, summary)
    if problems:
        print("refusing to write a CSV that does not reconcile:", file=sys.stderr)
        for problem in problems:
            print(f"  - {problem}", file=sys.stderr)
        return 1

    chosen = transactions if args.all else [t for t in transactions if t["section"] == "account"]
    write_csv(args.out, chosen, currency)

    counts = defaultdict(int)
    for t in transactions:
        counts[t["section"]] += 1
    foreign_rows = [t for t in chosen if t["original_currency"]]
    by_currency = defaultdict(float)
    for t in foreign_rows:
        by_currency[t["original_currency"]] += t["original_amount"]

    report = [
        f"{len(chosen)} rows written in {currency}",
        f"reconciled: out {summary['out']:.2f}, in {summary['in']:.2f}, "
        f"closing {summary['closing']:.2f}",
        "sections: " + ", ".join(f"{name} {count}" for name, count in sorted(counts.items())),
    ]
    if foreign_rows:
        charged = ", ".join(f"{total:,.2f} {code}" for code, total in sorted(by_currency.items()))
        cost = sum((t["money_out"] or 0) - (t["money_in"] or 0) for t in foreign_rows)
        report.append(f"{len(foreign_rows)} rows charged abroad ({charged}) "
                      f"cost {cost:,.2f} {currency}")
    print("\n".join(report), file=sys.stderr)
    return 0


if __name__ == "__main__":
    sys.exit(main())
