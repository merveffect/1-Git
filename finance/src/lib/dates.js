/** Date parsing (bank exports are inconsistent) and period bucketing. */

const MONTH_NAMES = {
  jan: 1, ocak: 1, janvier: 1, ene: 1,
  feb: 2, şub: 2, sub: 2, fev: 2, fevrier: 2, février: 2,
  mar: 3, mart: 3, mars: 3, marz: 3, märz: 3,
  apr: 4, nis: 4, avr: 4, abr: 4,
  may: 5, mai: 5, mayıs: 5, mayis: 5, mayo: 5,
  jun: 6, haz: 6, juin: 6, jun_: 6,
  jul: 7, tem: 7, juil: 7,
  aug: 8, ağu: 8, agu: 8, aout: 8, août: 8, ago: 8,
  sep: 9, eyl: 9, set: 9,
  oct: 10, eki: 10, okt: 10, out: 10,
  nov: 11, kas: 11, nou: 11,
  dec: 12, ara: 12, dez: 12, dic: 12,
};

function pad(n) {
  return String(n).padStart(2, '0');
}

function iso(year, month, day) {
  if (!year || !month || !day) return null;
  if (month < 1 || month > 12 || day < 1 || day > 31) return null;
  let fullYear = year;
  if (fullYear < 100) fullYear += fullYear > 70 ? 1900 : 2000;
  if (fullYear < 1900 || fullYear > 2200) return null;
  const date = new Date(Date.UTC(fullYear, month - 1, day));
  if (date.getUTCMonth() !== month - 1 || date.getUTCDate() !== day) return null;
  return `${fullYear}-${pad(month)}-${pad(day)}`;
}

/**
 * Parse a date cell to `YYYY-MM-DD`.
 * `order` disambiguates numeric dates: 'DMY' (default) or 'MDY'.
 */
export function parseDate(raw, order = 'DMY') {
  if (raw === null || raw === undefined) return null;
  if (raw instanceof Date) return iso(raw.getUTCFullYear(), raw.getUTCMonth() + 1, raw.getUTCDate());

  const text = String(raw).trim().replace(/ /g, ' ');
  if (text === '') return null;

  // Strip a trailing time component: "2024-03-01 14:22:10", "01/03/2024T00:00"
  const core = text.split(/[T ]/)[0].trim() || text;

  let m = core.match(/^(\d{4})[-/.](\d{1,2})[-/.](\d{1,2})$/);
  if (m) return iso(+m[1], +m[2], +m[3]);

  m = core.match(/^(\d{1,2})[-/.](\d{1,2})[-/.](\d{2,4})$/);
  if (m) {
    const a = +m[1];
    const b = +m[2];
    const year = +m[3];
    if (a > 12 && b <= 12) return iso(year, b, a);
    if (b > 12 && a <= 12) return iso(year, a, b);
    return order === 'MDY' ? iso(year, a, b) : iso(year, b, a);
  }

  m = core.match(/^(\d{8})$/);
  if (m) return iso(+m[1].slice(0, 4), +m[1].slice(4, 6), +m[1].slice(6, 8));

  // "12 Mar 2024", "12-Mar-24", "Mar 12, 2024"
  m = text.match(/^(\d{1,2})[\s-]*([\p{L}]{3,})\.?[\s-]*(\d{2,4})$/u);
  if (m) {
    const month = MONTH_NAMES[m[2].slice(0, 3).toLowerCase()];
    if (month) return iso(+m[3], month, +m[1]);
  }
  m = text.match(/^([\p{L}]{3,})\.?[\s-]*(\d{1,2}),?[\s-]*(\d{2,4})$/u);
  if (m) {
    const month = MONTH_NAMES[m[1].slice(0, 3).toLowerCase()];
    if (month) return iso(+m[3], month, +m[2]);
  }
  return null;
}

/**
 * Look at a whole column of dates and decide whether they are day-first or
 * month-first. Returns 'DMY', 'MDY' or null when it cannot be told apart.
 */
export function detectDateOrder(samples) {
  let dayFirst = 0;
  let monthFirst = 0;
  for (const sample of samples) {
    const m = String(sample ?? '').trim().split(/[T ]/)[0].match(/^(\d{1,2})[-/.](\d{1,2})[-/.](\d{2,4})$/);
    if (!m) continue;
    const a = +m[1];
    const b = +m[2];
    if (a > 12 && b <= 12) dayFirst += 1;
    else if (b > 12 && a <= 12) monthFirst += 1;
  }
  if (dayFirst > monthFirst) return 'DMY';
  if (monthFirst > dayFirst) return 'MDY';
  return null;
}

export function isValidISODate(value) {
  return typeof value === 'string' && /^\d{4}-\d{2}-\d{2}$/.test(value);
}

export function toUTCDate(isoDate) {
  const [y, m, d] = isoDate.split('-').map(Number);
  return new Date(Date.UTC(y, m - 1, d));
}

export function monthKey(isoDate) {
  return isoDate.slice(0, 7);
}

export function yearKey(isoDate) {
  return isoDate.slice(0, 4);
}

/** ISO-8601 week key, e.g. `2024-W09`. `weekStart` is 1 (Mon) or 0 (Sun). */
export function weekKey(isoDate, weekStart = 1) {
  const date = toUTCDate(isoDate);
  const day = (date.getUTCDay() - weekStart + 7) % 7;
  date.setUTCDate(date.getUTCDate() - day + 3); // Thursday of this week
  const year = date.getUTCFullYear();
  const firstThursday = new Date(Date.UTC(year, 0, 4));
  const firstDay = (firstThursday.getUTCDay() - weekStart + 7) % 7;
  firstThursday.setUTCDate(firstThursday.getUTCDate() - firstDay + 3);
  const week = 1 + Math.round((date - firstThursday) / (7 * 24 * 3600 * 1000));
  return `${year}-W${String(week).padStart(2, '0')}`;
}

export function periodKey(isoDate, granularity, weekStart = 1) {
  if (granularity === 'week') return weekKey(isoDate, weekStart);
  if (granularity === 'year') return yearKey(isoDate);
  return monthKey(isoDate);
}

/** Start date (inclusive) of a period key, used for sorting and ranges. */
export function periodStart(key, weekStart = 1) {
  if (/^\d{4}$/.test(key)) return `${key}-01-01`;
  if (/^\d{4}-\d{2}$/.test(key)) return `${key}-01`;
  const m = key.match(/^(\d{4})-W(\d{2})$/);
  if (m) {
    const year = +m[1];
    const week = +m[2];
    const firstThursday = new Date(Date.UTC(year, 0, 4));
    const offset = (firstThursday.getUTCDay() - weekStart + 7) % 7;
    firstThursday.setUTCDate(firstThursday.getUTCDate() - offset);
    firstThursday.setUTCDate(firstThursday.getUTCDate() + (week - 1) * 7);
    return firstThursday.toISOString().slice(0, 10);
  }
  return key;
}

export function addMonths(isoDate, count) {
  const date = toUTCDate(isoDate);
  const day = date.getUTCDate();
  date.setUTCDate(1);
  date.setUTCMonth(date.getUTCMonth() + count);
  const lastDay = new Date(Date.UTC(date.getUTCFullYear(), date.getUTCMonth() + 1, 0)).getUTCDate();
  date.setUTCDate(Math.min(day, lastDay));
  return date.toISOString().slice(0, 10);
}

export function addDays(isoDate, count) {
  return new Date(toUTCDate(isoDate).getTime() + count * 86400000).toISOString().slice(0, 10);
}

export function daysBetween(a, b) {
  return Math.round((toUTCDate(b) - toUTCDate(a)) / 86400000);
}

export function todayISO() {
  return new Date().toISOString().slice(0, 10);
}

/** Human label for a period key: "Mar 2024", "Week of 4 Mar 2024", "2024". */
export function periodLabel(key, locale = undefined, weekStart = 1) {
  if (/^\d{4}$/.test(key)) return key;
  if (/^\d{4}-\d{2}$/.test(key)) {
    const date = toUTCDate(`${key}-01`);
    return date.toLocaleDateString(locale, { month: 'short', year: 'numeric', timeZone: 'UTC' });
  }
  if (/^\d{4}-W\d{2}$/.test(key)) {
    const start = periodStart(key, weekStart);
    const date = toUTCDate(start);
    return date.toLocaleDateString(locale, { day: 'numeric', month: 'short', timeZone: 'UTC' });
  }
  return key;
}
