/**
 * In-memory application state and the actions that change it.
 *
 * The decrypted data only ever lives in this module's memory. Every mutation
 * re-encrypts and writes the whole vault; locking drops the key and the data.
 */

import { DEFAULT_CATEGORIES, applyRules, ruleFromTransaction } from './lib/categorize.js';
import { prepareImport } from './lib/import.js';
import { deriveKey, newSalt } from './crypto.js';
import {
  loadVaultRecord, saveVaultRecord, sealVault, unsealVault, createVault, destroyVault,
  loadPrefs, savePrefs, VAULT_FORMAT,
} from './storage.js';

export const DATA_VERSION = 1;

export function emptyData() {
  return {
    version: DATA_VERSION,
    createdAt: new Date().toISOString(),
    settings: {
      currency: 'EUR',
      locale: '',
      weekStart: 1,
      includeTransfers: false,
      redactPII: true,
      autoLockMinutes: 10,
    },
    categories: DEFAULT_CATEGORIES,
    transactions: [],
    rules: [],
    goals: [],
    imports: [],
  };
}

const listeners = new Set();

export const store = {
  locked: true,
  data: null,
  key: null,
  salt: null,
  prefs: loadPrefs(),
  saving: false,
  lastError: null,
};

export function subscribe(listener) {
  listeners.add(listener);
  return () => listeners.delete(listener);
}

export function emit() {
  for (const listener of listeners) listener(store);
}

export function options() {
  const settings = store.data?.settings || emptyData().settings;
  return {
    weekStart: settings.weekStart,
    includeTransfers: settings.includeTransfers,
    categories: store.data?.categories || DEFAULT_CATEGORIES,
  };
}

let saveTimer = null;
let waiters = [];
let inFlight = null;

/**
 * Re-encrypt and persist, coalescing a burst of edits into one write.
 * Every caller gets a promise that settles when their data has actually landed.
 */
export function persist({ immediate = false } = {}) {
  if (store.locked || !store.key) return Promise.resolve();
  return new Promise((resolve, reject) => {
    waiters.push({ resolve, reject });
    if (saveTimer) clearTimeout(saveTimer);
    saveTimer = setTimeout(runSave, immediate ? 0 : 400);
  });
}

async function runSave() {
  saveTimer = null;
  const settled = waiters;
  waiters = [];
  if (store.locked || !store.key) {
    settled.forEach((waiter) => waiter.resolve());
    return;
  }
  // Serialise writes so an older snapshot can never land after a newer one.
  const previous = inFlight;
  inFlight = (async () => {
    if (previous) await previous.catch(() => {});
    store.saving = true;
    emit();
    try {
      const record = await sealVault(store.key, store.salt, store.data);
      await saveVaultRecord(record);
      store.lastError = null;
      settled.forEach((waiter) => waiter.resolve());
    } catch (error) {
      store.lastError = error.message || String(error);
      settled.forEach((waiter) => waiter.reject(error));
    } finally {
      store.saving = false;
      emit();
    }
  })();
  await inFlight;
}

/** Mutate the data and save. */
export function update(mutator) {
  if (!store.data) return;
  mutator(store.data);
  emit();
  persist().catch(() => { /* surfaced through store.lastError */ });
}

export async function vaultExists() {
  return (await loadVaultRecord()) !== null;
}

export async function createNewVault(passphrase) {
  const data = emptyData();
  const { key, salt } = await createVault(passphrase, data);
  store.key = key;
  store.salt = salt;
  store.data = data;
  store.locked = false;
  emit();
}

export async function unlock(passphrase) {
  const record = await loadVaultRecord();
  if (!record) throw new Error('No vault on this device yet.');
  const { key, salt, data } = await unsealVault(record, passphrase);
  store.key = key;
  store.salt = salt;
  store.data = migrate(data);
  store.locked = false;
  emit();
}

export function lock() {
  if (saveTimer) clearTimeout(saveTimer);
  saveTimer = null;
  waiters.forEach((waiter) => waiter.resolve());
  waiters = [];
  store.locked = true;
  store.data = null;
  store.key = null;
  store.salt = null;
  emit();
}

function migrate(data) {
  const base = emptyData();
  return {
    ...base,
    ...data,
    settings: { ...base.settings, ...(data.settings || {}) },
    categories: data.categories?.length ? data.categories : base.categories,
    version: DATA_VERSION,
  };
}

export function setPref(key, value) {
  store.prefs = { ...store.prefs, [key]: value };
  savePrefs(store.prefs);
  emit();
}

/* ---------------------------------------------------------------- actions */

/** @returns {{added:number, duplicates:number, skipped:number}} */
export function importStatement(rows, { filename, skipped = 0, account = '' }) {
  const importId = `imp_${Date.now().toString(36)}`;
  const settings = store.data.settings;
  const result = prepareImport(rows, store.data.transactions, store.data.rules, {
    currency: settings.currency,
    account,
    redactPII: settings.redactPII,
    importId,
  });

  update((data) => {
    data.transactions = data.transactions.concat(result.added);
    data.transactions.sort((a, b) => b.date.localeCompare(a.date) || a.id.localeCompare(b.id));
    data.imports.unshift({
      id: importId,
      filename,
      importedAt: new Date().toISOString(),
      added: result.added.length,
      duplicates: result.duplicates.length,
      skipped,
      account,
    });
  });

  return { added: result.added.length, duplicates: result.duplicates.length, skipped };
}

export function undoImport(importId) {
  update((data) => {
    data.transactions = data.transactions.filter((tx) => tx.importId !== importId);
    data.imports = data.imports.filter((entry) => entry.id !== importId);
  });
}

export function setCategory(txId, category, { alsoCreateRule = false } = {}) {
  update((data) => {
    const tx = data.transactions.find((t) => t.id === txId);
    if (!tx) return;
    tx.category = category;
    tx.categorySource = 'manual';
    if (alsoCreateRule) {
      const rule = ruleFromTransaction(tx, category);
      data.rules = [rule, ...data.rules.filter((r) => !(r.field === rule.field && r.value === rule.value))];
      data.transactions = applyRules(data.transactions, data.rules);
      const again = data.transactions.find((t) => t.id === txId);
      if (again) {
        again.category = category;
        again.categorySource = 'manual';
      }
    }
  });
}

export function setExcluded(txId, excluded) {
  update((data) => {
    const tx = data.transactions.find((t) => t.id === txId);
    if (tx) tx.excluded = excluded;
  });
}

export function setNote(txId, note) {
  update((data) => {
    const tx = data.transactions.find((t) => t.id === txId);
    if (tx) tx.note = note;
  });
}

export function addRule(rule) {
  update((data) => {
    data.rules = [{ enabled: true, createdAt: new Date().toISOString(), ...rule }, ...data.rules];
    data.transactions = applyRules(data.transactions, data.rules);
  });
}

export function updateRule(id, patch) {
  update((data) => {
    data.rules = data.rules.map((rule) => (rule.id === id ? { ...rule, ...patch } : rule));
    data.transactions = applyRules(data.transactions, data.rules);
  });
}

export function deleteRule(id) {
  update((data) => {
    data.rules = data.rules.filter((rule) => rule.id !== id);
    data.transactions = data.transactions.map((tx) => (
      tx.ruleId === id ? { ...tx, categorySource: 'fallback', ruleId: null } : tx
    ));
    data.transactions = applyRules(data.transactions, data.rules);
  });
}

/** Re-run every rule, optionally clearing manual overrides too. */
export function recategorizeAll({ includeManual = false } = {}) {
  update((data) => {
    const source = includeManual
      ? data.transactions.map((tx) => ({ ...tx, categorySource: 'fallback' }))
      : data.transactions;
    data.transactions = applyRules(source, data.rules);
  });
}

export function saveGoal(goal) {
  update((data) => {
    const id = goal.id || `goal_${Date.now().toString(36)}`;
    const existing = data.goals.findIndex((g) => g.id === id);
    const value = { ...goal, id };
    if (existing >= 0) data.goals[existing] = value;
    else data.goals.push(value);
  });
}

export function deleteGoal(id) {
  update((data) => {
    data.goals = data.goals.filter((goal) => goal.id !== id);
  });
}

export function updateSettings(patch) {
  update((data) => {
    data.settings = { ...data.settings, ...patch };
  });
}

export async function changePassphrase(currentPassphrase, nextPassphrase) {
  const record = await loadVaultRecord();
  if (!record) throw new Error('No vault to re-key.');
  await unsealVault(record, currentPassphrase); // verifies the current passphrase
  const salt = newSalt();
  const key = await deriveKey(nextPassphrase, salt);
  const next = await sealVault(key, salt, store.data);
  await saveVaultRecord(next);
  store.key = key;
  store.salt = salt;
  emit();
}

export async function wipeEverything() {
  await destroyVault();
  lock();
}

/* ------------------------------------------------------------ backup / export */

/** Encrypted backup: the same sealed blob, safe to store anywhere. */
export async function exportEncryptedBackup() {
  const record = await sealVault(store.key, store.salt, store.data);
  return JSON.stringify(record, null, 2);
}

export async function restoreEncryptedBackup(json, passphrase) {
  const record = JSON.parse(json);
  if (record.format !== VAULT_FORMAT) throw new Error('This is not a finance tracker backup file.');
  const { key, salt, data } = await unsealVault(record, passphrase);
  store.key = key;
  store.salt = salt;
  store.data = migrate(data);
  store.locked = false;
  await saveVaultRecord(record);
  emit();
}

/** Plain CSV export - unencrypted by definition, the UI warns about it. */
export function exportCSV(transactions = store.data.transactions) {
  const header = ['date', 'description', 'merchant', 'category', 'amount', 'currency', 'account', 'excluded', 'note'];
  const escape = (value) => {
    const text = String(value ?? '');
    return /[",\n]/.test(text) ? `"${text.replace(/"/g, '""')}"` : text;
  };
  const lines = [header.join(',')];
  for (const tx of transactions) {
    lines.push([
      tx.date, tx.description, tx.merchantLabel, tx.category,
      (tx.amountCents / 100).toFixed(2), tx.currency, tx.account,
      tx.excluded ? 'yes' : 'no', tx.note,
    ].map(escape).join(','));
  }
  return lines.join('\n');
}

/* ------------------------------------------------------------- auto-lock */

let idleTimer = null;

export function noteActivity() {
  if (store.locked) return;
  if (idleTimer) clearTimeout(idleTimer);
  const minutes = store.data?.settings?.autoLockMinutes ?? 10;
  if (!minutes) return;
  idleTimer = setTimeout(() => {
    persist({ immediate: true }).finally(lock);
  }, minutes * 60 * 1000);
}

export function stopIdleTimer() {
  if (idleTimer) clearTimeout(idleTimer);
  idleTimer = null;
}
