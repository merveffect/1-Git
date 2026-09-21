/**
 * Fast non-cryptographic hash (FNV-1a, 64-bit) used only for transaction
 * identity/deduplication - never for secrets.
 */
export function fnv1a(text) {
  let h1 = 0x811c9dc5;
  let h2 = 0x01000193;
  for (let i = 0; i < text.length; i += 1) {
    const code = text.charCodeAt(i);
    h1 ^= code;
    h1 = Math.imul(h1, 0x01000193) >>> 0;
    h2 ^= code + i;
    h2 = Math.imul(h2, 0x85ebca6b) >>> 0;
  }
  return (h1 >>> 0).toString(16).padStart(8, '0') + (h2 >>> 0).toString(16).padStart(8, '0');
}

/** Identity of a transaction: same date, same amount, same merchant, same account. */
export function transactionKey({ date, amountCents, merchantKey, account }) {
  return fnv1a([date, amountCents, merchantKey, account || ''].join('|'));
}
