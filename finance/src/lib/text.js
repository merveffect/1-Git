/**
 * Description clean-up: redaction of identifiers, and merchant normalisation
 * used for grouping, deduplication and recurring-payment detection.
 */

const NOISE_PREFIXES = [
  'card payment to', 'card payment', 'pos payment', 'pos purchase', 'purchase at',
  'direct debit', 'standing order', 'bank transfer', 'sepa direct debit',
  'sepa credit transfer', 'sepa', 'faster payment', 'bacs', 'ach debit', 'ach credit',
  'payment to', 'payment from', 'transfer to', 'transfer from', 'debit card',
  'credit card', 'contactless', 'visa', 'mastercard', 'maestro', 'iban',
  'kartli islem', 'kartli işlem', 'para transferi', 'havale', 'eft', 'odeme', 'ödeme',
];

const NOISE_TOKENS = /\b(x{2,}\d*|ref|reference|trn|trans|transaction|auth|authorisation|authorization|no|nr|id|tid|mid|inv|invoice|order|ord|receipt|value|date|on|pos|atm|eur|usd|gbp|try|tl)\b/gi;

/**
 * Mask things that identify a person or an account. Runs on every imported
 * description so the stored data set stays free of account identifiers even
 * though it never leaves the device.
 */
export function redact(text) {
  if (!text) return '';
  let out = String(text);
  // IBAN, written either compactly or in groups of four. The digit guard stops
  // an ordinary word after a token like "GB29" from being eaten.
  const maskIban = (match, prefix, rest) => {
    const compact = (prefix + rest).replace(/\s/g, '');
    if (compact.length < 14 || compact.replace(/\D/g, '').length < 8) return match;
    return `${prefix}•••${compact.slice(-4)}`;
  };
  out = out.replace(/\b([A-Z]{2}\d{2})([A-Z0-9]{10,30})\b/g, maskIban);
  out = out.replace(/\b([A-Z]{2}\d{2})((?: [A-Z0-9]{4}){2,7}(?: [A-Z0-9]{1,3})?)\b/g, maskIban);
  // Card numbers, 13-19 digits with optional separators: keep the last 4.
  out = out.replace(/\b(?:\d[ -]?){12,18}\d\b/g, (match) => `••••${match.replace(/\D/g, '').slice(-4)}`);
  // Any other long identifier (account/customer/national id numbers).
  out = out.replace(/\b\d{9,}\b/g, (match) => `••••${match.slice(-4)}`);
  out = out.replace(/\b[\w.+-]+@[\w-]+\.[\w.]{2,}\b/g, '•••@•••');
  return out.replace(/\s{2,}/g, ' ').trim();
}

/** Loose key used to group the same merchant across statements. */
export function normalizeMerchant(description) {
  if (!description) return '';
  let out = String(description).toLowerCase();
  out = out.replace(/[•]/g, ' ');
  for (const prefix of NOISE_PREFIXES) {
    if (out.startsWith(prefix)) {
      out = out.slice(prefix.length);
      break;
    }
  }
  out = out
    .replace(/\b[a-z]{2}\d{2}\b/g, ' ') // IBAN country+check remnant, e.g. "gb29"
    .replace(/\b[a-z]*\d{4,}[a-z]*\b/g, ' ') // long reference numbers
    .replace(/\d{1,2}[-/.]\d{1,2}([-/.]\d{2,4})?/g, ' ') // embedded dates
    .replace(/\*/g, ' ')
    .replace(/[^\p{L}\p{N}&' ]+/gu, ' ')
    .replace(NOISE_TOKENS, ' ')
    .replace(/\b\d+\b/g, ' ')
    .replace(/\s{2,}/g, ' ')
    .trim();
  // Keep the first few meaningful words - the tail is usually reference noise.
  const words = out.split(' ').filter(Boolean).slice(0, 4);
  return words.join(' ');
}

/** Title-cased merchant label for display. */
export function merchantLabel(description) {
  const key = normalizeMerchant(description);
  if (!key) return 'Unknown';
  return key.replace(/\b[\p{L}]/gu, (c) => c.toUpperCase());
}

export function collapse(text) {
  return String(text ?? '').replace(/\s+/g, ' ').trim();
}
