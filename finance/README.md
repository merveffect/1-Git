# My Money — a private finance tracker

Upload your bank statement each month, see exactly where your money goes, and
track a savings goal. Everything happens inside your own browser: there is no
server, no account, no sign-up, and nothing is ever uploaded anywhere.

## Start in 30 seconds

1. Download `dist/finance-tracker.html` (one file, 163 KB).
2. Double-click it. It opens in your browser and works offline.
3. Choose a passphrase. That passphrase encrypts everything from then on.
4. Export a CSV from your online banking and drop it on the import screen.

That's it. Next month, export a new statement and drop it in again — anything
that overlaps with what you already imported is detected and skipped, so you can
re-upload the same period safely.

If you'd rather run it from a local address than from a file, use
`python3 -m http.server 8080` inside this folder and open
<http://localhost:8080/>.

## How secure is it, really

The threat this app is designed around is simple: **your financial history
should never be readable by anyone but you, and it should never leave your
device.**

| Concern | How it is handled |
|---|---|
| Data leaving your device | There is no network code at all. The page ships a Content-Security-Policy with `default-src 'none'` and `connect-src 'none'`, so the browser blocks any outbound request — even one introduced by mistake. |
| Someone opening your laptop | The vault is encrypted at rest with **AES-256-GCM**. The key comes from your passphrase via **PBKDF2-SHA256, 600,000 iterations**, with a random 16-byte salt and a fresh random IV on every save. The key is non-extractable and only exists in memory while unlocked. |
| Leaving it open | The app locks itself after 10 minutes of inactivity (configurable, and there is a Lock button). Locking wipes the decrypted data and the key from memory. |
| Identifiers sitting in the data | On import, IBANs, card numbers, long account/reference numbers and e-mail addresses are **masked out of the descriptions** before anything is stored — only the last four characters are kept, so you can still tell payments apart. |
| Third-party code | There is none. No npm packages, no CDN, no fonts, no analytics, no trackers. Every line runs from the single file you downloaded. |
| Losing the passphrase | Nobody can recover it — not you, not me. That is the trade-off for there being no server. Keep an encrypted backup (Settings → Backups) and remember the passphrase. |

Two things worth being clear about, because "super secure" should not mean
"oversold":

- **Your device is the trust boundary.** If your computer is compromised by
  malware or someone is watching while the vault is unlocked, no app-level
  encryption helps.
- **Browser storage is not permanent.** Clearing site data, "reset browser", or
  some private-mode settings will delete the vault. Download an encrypted backup
  now and then — it is the same sealed blob, useless without the passphrase, so
  it is safe to keep in cloud storage or on a USB stick.

## What it tells you

- **Money in, money out, and what you kept** — per week, per month, per year.
- **Where your money goes** — spending ranked by category, and by merchant, so
  the biggest drains are the first thing you see.
- **What you kept over time** — the running total of everything you saved.
- **Regular payments** — subscriptions and other repeating charges are detected
  automatically, with their cadence, monthly cost, yearly cost and the date the
  next one is expected.
- **What changed** — the categories that moved most against your recent average.
- **Goals** — set a target and a date; it shows what you have saved since the
  goal started, what you need per month, whether you are on track, and when you
  will get there at your current pace.

Transfers between your own accounts are excluded from income and spending by
default, so moving money to savings doesn't look like income or expenditure.
You can switch that off in Settings.

## Importing statements

Accepts **CSV, TSV, OFX and QFX**. For Excel exports, save as CSV first.

The app works out for itself which column is the date, which is the description
and which carries the amount (including banks that use separate debit and credit
columns, or write spending as a positive number). It also detects whether dates
are day-first or month-first. Everything it guessed is shown on the import
screen with the first rows already parsed — correct anything that looks wrong
before confirming, and the preview updates live.

Amounts are parsed in whatever format your bank uses: `1.234,56`, `1,234.56`,
`(12.50)`, `12.50-`, `100.00 CR`, with or without currency symbols.

Every import can be undone from the import history, which removes exactly the
transactions that came from that file.

## Categories

Nearly 400 built-in keyword rules cover common merchants across several
countries. On top of that:

- Change a category on any transaction, and it stays changed.
- Press **Remember** and it becomes a rule: every past and future transaction
  from that merchant gets the same category.
- Write your own rules (contains / starts with / is exactly / regex), optionally
  limited to money in or money out.
- The **Categories** page lists what is still uncategorised, biggest first —
  sorting the top few is the fastest way to make the charts meaningful.

## Development

No build tooling and no dependencies. The `src/` folder is plain ES modules.

```bash
npm test            # 42 tests covering parsing, dedupe, categorising and analytics
python3 build.py    # bundles src/ into dist/finance-tracker.html
python3 -m http.server 8080   # serve the unbundled app during development
```

| Path | What lives there |
|---|---|
| `src/lib/` | Pure logic: CSV/OFX parsing, amount and date parsing, column detection, redaction, deduplication, categorisation, analytics |
| `src/crypto.js`, `src/storage.js` | Key derivation, encryption, and the encrypted vault in IndexedDB (falling back to localStorage where a browser blocks IndexedDB on `file://`) |
| `src/state.js` | In-memory state, actions, debounced re-encrypt-and-save, auto-lock |
| `src/charts.js` | Hand-written SVG charts, colours from CSS custom properties |
| `src/ui/` | The screens: lock, dashboard, import, transactions, goals, categories, settings |
| `build.py` | Tiny module bundler that inlines everything into one offline HTML file |
| `tests/` | Node's built-in test runner, no framework |

The chart palette is a colourblind-safe categorical set validated in both light
and dark modes; charts always carry a legend and readable values, so nothing
depends on colour alone.
