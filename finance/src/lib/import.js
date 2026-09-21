/**
 * The import pipeline: raw file text -> preview -> deduplicated transactions.
 * Pure functions only, so the tricky parts are testable without a browser.
 */

import { parseCSV, findTableStart, detectDelimiter } from './csv.js';
import { detectColumns, mapRows, detectExpensesArePositive } from './detect.js';
import { looksLikeOFX, parseOFX } from './ofx.js';
import { redact, normalizeMerchant, merchantLabel, collapse } from './text.js';
import { transactionKey } from './hash.js';
import { toCents } from './money.js';
import { applyRules } from './categorize.js';

/**
 * Read a statement file into a preview the user can correct before importing.
 * @returns {{kind:'csv'|'ofx', headers:string[], sample:string[][], mapping:object,
 *   rows:Array, skipped:Array}}
 */
export function readStatement(text, { dateOrder } = {}) {
  if (looksLikeOFX(text)) {
    const parsed = parseOFX(text);
    return {
      kind: 'ofx',
      headers: ['Date', 'Description', 'Amount'],
      sample: parsed.rows.slice(0, 8).map((r) => [r.date, r.description, String(r.amount)]),
      mapping: { dateOrder: 'ISO', expensesArePositive: false, currency: parsed.currency },
      rows: parsed.rows,
      skipped: parsed.skipped,
    };
  }

  const delimiter = detectDelimiter(text);
  const table = parseCSV(text, delimiter);
  const start = findTableStart(table);
  const headers = table[start] || [];
  const body = table.slice(start + 1).filter((row) => row.some((cell) => cell !== ''));
  const mapping = detectColumns(headers, body.slice(0, 50));
  if (dateOrder) mapping.dateOrder = dateOrder;
  mapping.expensesArePositive = detectExpensesArePositive(body, mapping);
  mapping.delimiter = delimiter;
  mapping.headerRow = start;

  const mapped = mapRows(body, mapping);
  return {
    kind: 'csv',
    headers,
    sample: body.slice(0, 8),
    body,
    mapping,
    rows: mapped.rows,
    skipped: mapped.skipped,
  };
}

/** Re-run the mapping after the user tweaks it in the preview. */
export function remap(body, mapping) {
  return mapRows(body, mapping);
}

/**
 * Turn mapped rows into stored transactions.
 * @param {object} options currency, account, redactPII, importId
 */
export function buildTransactions(rows, options = {}) {
  const {
    currency = 'EUR', account = '', redactPII = true, importId = 'manual',
  } = options;
  return rows.map((row, index) => {
    const cleaned = collapse(redactPII ? redact(row.description) : row.description);
    const merchantKey = normalizeMerchant(cleaned);
    const amountCents = toCents(row.amount);
    return {
      id: `tx_${importId}_${index}`,
      date: row.date,
      amountCents,
      description: cleaned,
      merchantKey,
      merchantLabel: merchantLabel(cleaned),
      currency: row.currency || currency,
      account,
      category: 'Uncategorised',
      categorySource: 'fallback',
      ruleId: null,
      excluded: false,
      note: '',
      importId,
      key: transactionKey({ date: row.date, amountCents, merchantKey, account }),
    };
  });
}

/**
 * Drop rows already present from an earlier upload.
 *
 * Identical repeat purchases on one day are legitimate, so identity is counted
 * rather than set-based: if the vault already holds two matching rows and the
 * new file has three, exactly one is added.
 *
 * @returns {{added:Array, duplicates:Array}}
 */
export function deduplicate(incoming, existing) {
  const counts = new Map();
  for (const tx of existing) counts.set(tx.key, (counts.get(tx.key) || 0) + 1);

  const seen = new Map();
  const added = [];
  const duplicates = [];
  for (const tx of incoming) {
    const index = (seen.get(tx.key) || 0) + 1;
    seen.set(tx.key, index);
    if (index <= (counts.get(tx.key) || 0)) duplicates.push(tx);
    else added.push(tx);
  }
  return { added, duplicates };
}

/**
 * Full pipeline for a parsed file.
 * @returns {{added:Array, duplicates:Array, skipped:Array}}
 */
export function prepareImport(rows, existing, rules, options = {}) {
  const built = buildTransactions(rows, options);
  const { added, duplicates } = deduplicate(built, existing);
  return { added: applyRules(added, rules, options), duplicates };
}
