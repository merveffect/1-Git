/**
 * Vault encryption.
 *
 * Everything the app stores about your money is encrypted with a key derived
 * from your passphrase alone. There is no server, no key escrow and no
 * recovery: lose the passphrase and the data is gone, which is the point.
 *
 *   passphrase --PBKDF2-SHA256(600k, 16-byte salt)--> 256-bit key
 *   plaintext JSON --AES-256-GCM(12-byte random IV)--> ciphertext
 *
 * A fresh IV is generated for every single write.
 */

const KDF_ITERATIONS = 600000;
const SALT_BYTES = 16;
const IV_BYTES = 12;

const encoder = new TextEncoder();
const decoder = new TextDecoder();

export function randomBytes(length) {
  return crypto.getRandomValues(new Uint8Array(length));
}

export function toBase64(bytes) {
  let binary = '';
  const view = new Uint8Array(bytes);
  for (let i = 0; i < view.length; i += 1) binary += String.fromCharCode(view[i]);
  return btoa(binary);
}

export function fromBase64(text) {
  const binary = atob(text);
  const bytes = new Uint8Array(binary.length);
  for (let i = 0; i < binary.length; i += 1) bytes[i] = binary.charCodeAt(i);
  return bytes;
}

/** @returns {Promise<CryptoKey>} non-extractable AES-GCM key */
export async function deriveKey(passphrase, salt, iterations = KDF_ITERATIONS) {
  const material = await crypto.subtle.importKey(
    'raw',
    encoder.encode(passphrase.normalize('NFKC')),
    'PBKDF2',
    false,
    ['deriveKey'],
  );
  return crypto.subtle.deriveKey(
    { name: 'PBKDF2', salt, iterations, hash: 'SHA-256' },
    material,
    { name: 'AES-GCM', length: 256 },
    false,
    ['encrypt', 'decrypt'],
  );
}

export function newSalt() {
  return randomBytes(SALT_BYTES);
}

export const KDF_PARAMS = { name: 'PBKDF2', hash: 'SHA-256', iterations: KDF_ITERATIONS };

/**
 * Encrypt a JSON-serialisable value.
 * @returns {Promise<{iv:string, data:string}>} base64 parts
 */
export async function encryptJSON(key, value) {
  const iv = randomBytes(IV_BYTES);
  const plaintext = encoder.encode(JSON.stringify(value));
  const ciphertext = await crypto.subtle.encrypt({ name: 'AES-GCM', iv }, key, plaintext);
  plaintext.fill(0);
  return { iv: toBase64(iv), data: toBase64(new Uint8Array(ciphertext)) };
}

/** Throws if the passphrase is wrong or the payload was tampered with. */
export async function decryptJSON(key, payload) {
  const iv = fromBase64(payload.iv);
  const data = fromBase64(payload.data);
  const plaintext = await crypto.subtle.decrypt({ name: 'AES-GCM', iv }, key, data);
  return JSON.parse(decoder.decode(plaintext));
}

/** Rough strength meter for the passphrase field (0-4). */
export function passphraseStrength(passphrase) {
  const value = passphrase || '';
  let score = 0;
  if (value.length >= 10) score += 1;
  if (value.length >= 16) score += 1;
  if (value.length >= 24) score += 1;
  if (/[a-z]/.test(value) && /[A-Z0-9]/.test(value)) score += 1;
  if (/\s/.test(value) && value.trim().split(/\s+/).length >= 4) score = Math.max(score, 3);
  if (value.length < 8) score = 0;
  return Math.min(4, score);
}
