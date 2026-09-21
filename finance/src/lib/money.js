/** Amount parsing and formatting for messy bank-export numbers. */

const CURRENCY_CHARS = /[^\d.,\-+()\s]/g;

/**
 * Parse an amount cell into a number.
 *
 * Handles: "1.234,56", "1,234.56", "-12.50", "12.50-", "(12.50)", "€ 12,50",
 * "12,50 TL", "1 234,56", "12.50 CR" / "12.50 DR".
 * Returns null when the cell holds no usable number.
 */
export function parseAmount(raw) {
  if (raw === null || raw === undefined) return null;
  if (typeof raw === 'number') return Number.isFinite(raw) ? raw : null;

  let text = String(raw).replace(/ /g, ' ').trim();
  if (text === '') return null;

  let sign = 1;
  const upper = text.toUpperCase();
  // Credit/debit markers used by some banks instead of a minus sign.
  if (/\b(DR|DB|DEBIT)\b/.test(upper)) sign = -1;
  if (/\b(CR|CREDIT)\b/.test(upper)) sign = 1;
  if (/^\(.*\)$/.test(text)) {
    sign = -1;
    text = text.slice(1, -1);
  }
  if (/-\s*$/.test(text)) {
    sign = -1;
    text = text.replace(/-\s*$/, '');
  }

  text = text.replace(CURRENCY_CHARS, '').replace(/\s/g, '').replace(/[()]/g, '');
  if (text.startsWith('-')) {
    sign = -1;
    text = text.slice(1);
  } else if (text.startsWith('+')) {
    text = text.slice(1);
  }
  if (text === '' || !/\d/.test(text)) return null;

  const lastComma = text.lastIndexOf(',');
  const lastDot = text.lastIndexOf('.');
  let normalized;
  if (lastComma >= 0 && lastDot >= 0) {
    // Whichever separator comes last is the decimal one.
    const decimalSep = lastComma > lastDot ? ',' : '.';
    const thousandSep = decimalSep === ',' ? '.' : ',';
    normalized = text.split(thousandSep).join('').replace(decimalSep, '.');
  } else if (lastComma >= 0 || lastDot >= 0) {
    const sep = lastComma >= 0 ? ',' : '.';
    const idx = lastComma >= 0 ? lastComma : lastDot;
    const decimals = text.length - idx - 1;
    const occurrences = text.split(sep).length - 1;
    if (occurrences > 1 || decimals === 3) {
      // "1.234.567" or "1,234" -> grouping separator, not a decimal point.
      normalized = text.split(sep).join('');
    } else {
      normalized = text.replace(sep, '.');
    }
  } else {
    normalized = text;
  }

  const value = Number.parseFloat(normalized);
  if (!Number.isFinite(value)) return null;
  return sign * value;
}

/** Money is stored as integer minor units to keep sums exact. */
export function toCents(value) {
  return Math.round(value * 100);
}

export function fromCents(cents) {
  return cents / 100;
}

export function formatMoney(cents, currency = 'EUR', locale = undefined) {
  const value = fromCents(cents);
  try {
    return new Intl.NumberFormat(locale, {
      style: 'currency',
      currency,
      maximumFractionDigits: 2,
    }).format(value);
  } catch {
    return `${value.toFixed(2)} ${currency}`;
  }
}

/** Compact form for chart axes: 12.4k, 1.2M. */
export function formatCompact(cents, currency = 'EUR', locale = undefined) {
  const value = fromCents(cents);
  try {
    return new Intl.NumberFormat(locale, {
      style: 'currency',
      currency,
      notation: 'compact',
      maximumFractionDigits: 1,
    }).format(value);
  } catch {
    return `${Math.round(value)}`;
  }
}
