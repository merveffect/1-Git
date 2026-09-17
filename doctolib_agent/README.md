# Doctolib Randevu Agent'ı

Şikayetini ve müsait günlerini yazıyorsun; agent bunu aranabilir bir niyete
çeviriyor, Doctolib'i tarıyor, sana uyan slotları buluyor ve randevuyu senin
adına açıyor. Telefondan kullanmak için bir web arayüzü var.

Arama **her zaman Berlin'de** yapılır (`doctolib.yaml` içinde `location`).

```
$ doctolib-agent find "boğazım üç gündür ağrıyor, Paris'te KBB lazım, \
    salı ve perşembe öğleden sonra ya da cuma sabah müsaitim"

Anlaşılan istek
  Şikayet      : Üç gündür süren boğaz ağrısı
  Uzmanlık     : ORL (Kulak Burun Boğaz)  (orl, medecin-generaliste)
  Konum        : Paris
  Müsaitlik    : Salı, Perşembe 12:00-18:00 | Cuma 08:00-12:00
  Aciliyet     : soon

Aranıyor: orl @ paris
  18 hekim bulundu
  Dr Ada Lambert: 6 ham slot
  ...

3 uygun randevu bulundu — ORL, Paris
1. 24.09.2026 Per 15:20  Dr Ada Lambert
    ORL — 12 rue de Turbigo 75003 Paris
    Consultation ORL
    https://www.doctolib.fr/orl/paris/ada-lambert
```

## Önce şunu bilelim

- Doctolib'in kullanım şartları otomatik erişimi kısıtlar ve site Datadome bot
  koruması kullanır. Bu araç **tek kullanıcılık kişisel kullanım** için
  tasarlandı: nazik rate-limit, tur başına en fazla 1 randevu, varsayılanda son
  onay insanda. Toplu slot kapma için kullanma; hem yanlış hem de çalışmaz.
- Kullanılan JSON uçları resmi/dokümante değil. Şema değişirse tarama boş döner
  — `--dump` ile ham cevabı alıp ayrıştırmayı güncelle.
- Agent teşhis koymaz. Mesajında acil uyarı işareti görürse (göğüs ağrısı,
  ani konuşma bozukluğu vb.) randevu aramadan önce seni uyarır.

## Kurulum

```bash
pip install -r doctolib_agent/requirements.txt
playwright install chromium

cp doctolib_agent/config.example.yaml doctolib.yaml
$EDITOR doctolib.yaml

export ANTHROPIC_API_KEY=...     # ya da: ant auth login
```

Doctolib oturumunu bir kez aç — parola hiçbir zaman dosyaya yazılmaz, giriş
(2FA dahil) tarayıcıda senin elinle yapılır ve çerezler `.doctolib_state.json`
içine kaydedilir:

```bash
python -m doctolib_agent.cli login
```

## Telefondan kullanım

Sunucuyu bilgisayarında (veya bir VPS'te) çalıştırıyorsun, telefondan tarayıcıyla
bağlanıyorsun. Ekle-ana-ekrana ile uygulama gibi açılır (PWA).

```bash
# Ağa açıyorsan token zorunlu - bu sunucu Doctolib oturumunu tutuyor
export DOCTOLIB_WEB_TOKEN=$(python -c 'import secrets;print(secrets.token_urlsafe(24))')
python -m doctolib_agent.cli web --host 0.0.0.0 --port 8600
```

Telefonda `http://<bilgisayarının-yerel-ip>:8600` adresini aç, token'ı bir kez gir
(cihazda saklanır), sonra:

1. Şikayetini yaz ya da hazır etiketlerden seç (Diş ağrısı, Cilt sorunu, …).
2. Müsait günlerine ve günün saatine dokun.
3. **Randevu ara** → sonuçlar kart kart gelir.
4. **Doctolib'de aç** → Doctolib telefonda açılır, girişin zaten varsa randevuyu
   orada bitirirsin.

`booking.mode: auto` isen kartlarda ayrıca **Sunucuda al** düğmesi çıkar; onay
dahil her şeyi sunucudaki tarayıcı yapar.

Güvenlik notu: `DOCTOLIB_WEB_TOKEN` tanımlı değilse sunucu yalnızca localhost'tan
gelen istekleri kabul eder; uzak istekler 403 döner. Sunucuyu doğrudan internete
açacaksan önüne HTTPS koy (Caddy/nginx) — token düz HTTP'de açık gider.

## Komutlar

| Komut | Ne yapar |
|---|---|
| `login` | Tarayıcıda giriş yap, oturumu kaydet |
| `web` | Telefon arayüzünü başlatır (`--host 0.0.0.0` ile ağa açılır) |
| `intent "<metin>"` | Sadece isteğini çözümler, ağa çıkmaz — filtreni kontrol etmek için |
| `find "<metin>"` | Bir kez tarar, uyanları listeler, istersen rezerve eder |
| `watch "<metin>"` | Uygun slot çıkana kadar periyodik tarar |

Genel bayraklar: `-c/--config`, `--mode {notify,assist,auto}`, `-y/--yes`,
`--dump DIR`, `-v`.

```bash
# Sadece bak, rezerve etme
python -m doctolib_agent.cli --mode notify find "Berlin'de dermatolog, hafta içi sabah"

# İptal çıkana kadar bekle, bulunca onay ekranına kadar götür
python -m doctolib_agent.cli watch "Lyon'da diş hekimi, cumartesi" --max-rounds 48
```

## Rezervasyon modları

| Mod | Davranış |
|---|---|
| `notify` | Sadece haber verir. Tarayıcı hiç açılmaz. |
| `assist` | **Varsayılan.** Tarayıcıyı açar, slotu seçer, ara adımları geçer, son onay ekranında durur — son tıkı sen yaparsın. |
| `auto` | Son onayı da agent yapar. Bilinçli tercih; `doctolib.yaml` içinde açman gerekir. |

`assist` varsayılan çünkü yanlış randevu gerçek bir maliyet: gelmedin diye ücret
kesilebilir ve o slot başkasına lazımdı.

## Nasıl çalışıyor

```
telefon ─► web/app.py ─┐
komut satırı ─► cli.py ┴► intent.py ──► SearchIntent  (Claude, yapılandırılmış çıktı)
                          │
                          ▼
          client.py ──► arama → /booking/<slug>.json → /availabilities.json
                          │                            (throttle + 429 backoff)
                          ▼
          matcher.py ─► zaman penceresi / ufuk / blackout filtresi + sıralama
                          │
                          ▼
          booker.py ──► Playwright: slotu aç → adımları geç → onay
```

- **`intent.py`** — Claude Opus 5, `messages.parse` ile Pydantic şemasına
  yapılandırılmış çıktı. Şikayeti uzmanlık slug'larına, "salı öğleden sonra"yı
  `TimeWindow(weekdays=[1], 12:00-18:00)`'a çevirir.
- **`client.py`** — İki taşıma modu. `http` hızlıdır; bot korumasına takılırsan
  `transport: browser` yap, istekler Playwright oturumunun çerezleriyle gider.
  Slot ayrıştırması savunmacıdır: Doctolib slotu hem düz ISO string hem nesne
  olarak döndürebiliyor, ikisi de desteklenir, bozuk kayıt sessizce elenir.
- **`booker.py`** — DOM sık değiştiği için seçiciler aday listeleri hâlinde
  tutulur ve kod değiştirmeden `selectors.yaml` ile ezilebilir.
- **`web/`** — FastAPI + tek sayfalık mobil arayüz. Taramalar tek çalışanlı bir
  kuyrukta sıraya girer, böylece telefondan arka arkaya istek atsan bile
  Doctolib'e paralel istek gitmez.

## Doctolib DOM'u değişince

Rezervasyon akışı ortada takılırsa proje kökünde bir `selectors.yaml` aç:

```yaml
final_confirm:
  - "button[data-new-attr='confirm']"
slot_button:
  - ".yeni-slot-sinifi"
```

Seninkiler önce denenir, sonra dahili varsayılanlar. Anahtarların tam listesi
`booker.py` içindeki `SELECTORS` sözlüğünde.

## Güvenlik sınırları

Kod içine gömülü, yapılandırmayla gevşetilemeyen sınırlar:

- Tur arası bekleme ≥ 300 sn, istekler arası ≥ 1.0 sn (+ jitter).
- Tur başına en fazla 3 randevu (varsayılan 1).
- Tarama ufku en fazla 90 gün.
- 429/403 alınca üstel geri çekilme; `Retry-After` başlığına uyulur.
- Parola asla saklanmaz; sadece tarayıcı oturum durumu (`.doctolib_state.json`,
  `.gitignore`'da).

## Testler

```bash
python -m pytest doctolib_agent/tests -q
```

39 test; ağ veya API anahtarı gerektirmez.
