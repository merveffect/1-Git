/**
 * Local persistence. The encrypted vault lives in IndexedDB on this device;
 * only non-sensitive UI preferences are stored in the clear.
 */

import { encryptJSON, decryptJSON, deriveKey, newSalt, toBase64, fromBase64, KDF_PARAMS } from './crypto.js';

const DB_NAME = 'finance-tracker';
const DB_VERSION = 1;
const STORE = 'vault';
const VAULT_KEY = 'main';
const PREFS_KEY = 'finance-tracker.prefs';

export const VAULT_FORMAT = 'finance-tracker-vault';
export const VAULT_VERSION = 1;

const VAULT_FALLBACK_KEY = 'finance-tracker.vault';

/**
 * Some browsers refuse IndexedDB on file:// pages. The vault is a single
 * encrypted blob, so localStorage is an acceptable fallback - same ciphertext,
 * same device, just a different drawer.
 */
const fallback = {
  get() {
    try {
      const raw = localStorage.getItem(VAULT_FALLBACK_KEY);
      return raw ? JSON.parse(raw) : null;
    } catch {
      return null;
    }
  },
  put(record) {
    localStorage.setItem(VAULT_FALLBACK_KEY, JSON.stringify(record));
  },
  remove() {
    try {
      localStorage.removeItem(VAULT_FALLBACK_KEY);
    } catch {
      /* nothing to remove */
    }
  },
};

let useFallback = false;

function openDB() {
  if (useFallback || typeof indexedDB === 'undefined') return Promise.reject(new Error('no indexeddb'));
  return new Promise((resolve, reject) => {
    const request = indexedDB.open(DB_NAME, DB_VERSION);
    request.onupgradeneeded = () => {
      const db = request.result;
      if (!db.objectStoreNames.contains(STORE)) db.createObjectStore(STORE);
    };
    request.onsuccess = () => resolve(request.result);
    request.onerror = () => reject(request.error);
  });
}

function tx(db, mode, run) {
  return new Promise((resolve, reject) => {
    const transaction = db.transaction(STORE, mode);
    const store = transaction.objectStore(STORE);
    const request = run(store);
    transaction.oncomplete = () => resolve(request?.result);
    transaction.onerror = () => reject(transaction.error);
    transaction.onabort = () => reject(transaction.error);
  });
}

/** @returns {Promise<object|null>} the stored (still encrypted) vault record */
export async function loadVaultRecord() {
  let db;
  try {
    db = await openDB();
  } catch {
    useFallback = true;
    return fallback.get();
  }
  try {
    return (await tx(db, 'readonly', (store) => store.get(VAULT_KEY))) || null;
  } catch {
    useFallback = true;
    return fallback.get();
  } finally {
    db.close();
  }
}

export async function saveVaultRecord(record) {
  let db;
  try {
    db = await openDB();
  } catch {
    useFallback = true;
    fallback.put(record);
    return;
  }
  try {
    await tx(db, 'readwrite', (store) => store.put(record, VAULT_KEY));
  } catch (error) {
    useFallback = true;
    fallback.put(record);
  } finally {
    db.close();
  }
}

export async function destroyVault() {
  fallback.remove();
  let db;
  try {
    db = await openDB();
  } catch {
    return;
  }
  try {
    await tx(db, 'readwrite', (store) => store.delete(VAULT_KEY));
  } finally {
    db.close();
  }
}

export async function hasVault() {
  return (await loadVaultRecord()) !== null;
}

/** Build an encrypted vault record from plain data. */
export async function sealVault(key, salt, data) {
  const payload = await encryptJSON(key, data);
  return {
    format: VAULT_FORMAT,
    version: VAULT_VERSION,
    kdf: { ...KDF_PARAMS, salt: toBase64(salt) },
    cipher: 'AES-GCM',
    iv: payload.iv,
    data: payload.data,
    updatedAt: new Date().toISOString(),
  };
}

/**
 * Derive the key from a passphrase for an existing record and decrypt it.
 * @returns {Promise<{key:CryptoKey, salt:Uint8Array, data:object}>}
 */
export async function unsealVault(record, passphrase) {
  const salt = fromBase64(record.kdf.salt);
  const key = await deriveKey(passphrase, salt, record.kdf.iterations);
  const data = await decryptJSON(key, { iv: record.iv, data: record.data });
  return { key, salt, data };
}

/** Create a brand new vault for a passphrase. */
export async function createVault(passphrase, data) {
  const salt = newSalt();
  const key = await deriveKey(passphrase, salt);
  const record = await sealVault(key, salt, data);
  await saveVaultRecord(record);
  return { key, salt, record };
}

/** Non-sensitive preferences (theme, auto-lock delay) kept outside the vault. */
export function loadPrefs() {
  try {
    return JSON.parse(localStorage.getItem(PREFS_KEY) || '{}');
  } catch {
    return {};
  }
}

export function savePrefs(prefs) {
  try {
    localStorage.setItem(PREFS_KEY, JSON.stringify(prefs));
  } catch {
    /* storage may be disabled; preferences are optional */
  }
}
