/**
 * Works out what the columns of an unknown bank CSV mean, then turns rows into
 * transactions. Everything is a guess the user can override in the import
 * preview - detection only has to be right often enough to save typing.
 */

import { parseAmount } from './money.js';
import { parseDate, detectDateOrder } from './dates.js';

const PATTERNS = {
  date: /\b(date|datum|fecha|data|tarih|posted|booking|value\s*date|transaction\s*date|islem\s*tarihi|işlem\s*tarihi)\b/i,
  description: /\b(description|details|detail|memo|payee|narrative|reference|merchant|name|beneficiary|counterparty|concepto|libell|verwendungszweck|buchungstext|aciklama|açıklama)\b/i,
  amount: /\b(amount|betrag|montant|importe|valore|valor|tutar|value|sum|net)\b/i,
  debit: /\b(debit|withdrawal|withdrawals|paid\s*out|money\s*out|outflow|expense|soll|borc|borç|gider|charge)\b/i,
  credit: /\b(credit|deposit|deposits|paid\s*in|money\s*in|inflow|income|haben|alacak|gelir)\b/i,
  balance: /\b(balance|saldo|solde|kontostand|bakiye|running\s*total)\b/i,
  currency: /\b(currency|ccy|waehrung|währung|devise|para\s*birimi)\b/i,
  type: /\b(type|transaction\s*type|dc|d\/c|debit\/credit|kind|direction|islem\s*turu|işlem\s*türü)\b/i,
  account: /\b(account|konto|compte|cuenta|hesap|iban|card)\b/i,
};

function scoreColumn(rows, index, test) {
  let hits = 0;
  let seen = 0;
  for (const row of rows) {
    const cell = row[index];
    if (cell === undefined || cell === '') continue;
    seen += 1;
    if (test(cell)) hits += 1;
  }
  return seen === 0 ? 0 : hits / seen;
}

function averageLength(rows, index) {
  let total = 0;
  let seen = 0;
  for (const row of rows) {
    const cell = row[index];
    if (!cell) continue;
    total += cell.length;
    seen += 1;
  }
  return seen === 0 ? 0 : total / seen;
}

/**
 * @param {string[]} headers
 * @param {string[][]} rows sample data rows (without the header)
 * @returns {{date:number|null, description:number[], amount:number|null,
 *   debit:number|null, credit:number|null, balance:number|null,
 *   currency:number|null, type:number|null, dateOrder:string}}
 */
export function detectColumns(headers, rows) {
  const used = new Set();
  const byHeader = (key) => {
    const index = headers.findIndex((h, i) => !used.has(i) && PATTERNS[key].test(h || ''));
    if (index >= 0) used.add(index);
    return index >= 0 ? index : null;
  };

  // Header names win; content analysis fills the gaps.
  let date = byHeader('date');
  const debit = byHeader('debit');
  const credit = byHeader('credit');
  const balance = byHeader('balance');
  let amount = byHeader('amount');
  const currency = byHeader('currency');
  const type = byHeader('type');
  let description = byHeader('description');

  const numericCols = headers
    .map((_, i) => i)
    .filter((i) => i !== balance && scoreColumn(rows, i, (c) => parseAmount(c) !== null) > 0.8);

  if (date === null) {
    let best = null;
    let bestScore = 0.6;
    headers.forEach((_, i) => {
      const score = scoreColumn(rows, i, (c) => parseDate(c) !== null);
      if (score > bestScore) {
        bestScore = score;
        best = i;
      }
    });
    date = best;
    if (date !== null) used.add(date);
  }

  if (amount === null && debit === null && credit === null) {
    const candidates = numericCols.filter((i) => i !== date && !used.has(i));
    // An amount column usually contains both positive and negative values, or
    // at least varies more than a running balance.
    let best = null;
    let bestScore = -1;
    for (const i of candidates) {
      const values = rows.map((r) => parseAmount(r[i])).filter((v) => v !== null);
      if (values.length === 0) continue;
      const hasNegative = values.some((v) => v < 0);
      const distinct = new Set(values).size / values.length;
      const score = (hasNegative ? 2 : 0) + distinct;
      if (score > bestScore) {
        bestScore = score;
        best = i;
      }
    }
    amount = best;
    if (amount !== null) used.add(amount);
  }

  if (description === null) {
    let best = null;
    let bestLength = 3;
    headers.forEach((_, i) => {
      if (used.has(i) || i === date || i === amount) return;
      if (scoreColumn(rows, i, (c) => parseAmount(c) !== null) > 0.5) return;
      const length = averageLength(rows, i);
      if (length > bestLength) {
        bestLength = length;
        best = i;
      }
    });
    description = best;
  }

  const descriptions = description === null ? [] : [description];
  // A second text column (payee + memo) often carries useful detail.
  headers.forEach((_, i) => {
    if (descriptions.includes(i) || used.has(i) || i === date || i === amount) return;
    if (!PATTERNS.description.test(headers[i] || '')) return;
    descriptions.push(i);
  });

  const dateOrder = date === null ? 'DMY' : detectDateOrder(rows.map((r) => r[date])) || 'DMY';

  return { date, description: descriptions, amount, debit, credit, balance, currency, type, dateOrder };
}

const CREDIT_WORDS = /\b(credit|cr|deposit|in|income|alacak|gelir|haben|incoming)\b/i;
const DEBIT_WORDS = /\b(debit|dr|db|withdrawal|out|payment|expense|borc|borç|gider|soll|outgoing)\b/i;

/**
 * Decide the sign convention of a single amount column.
 * Returns true when expenses are recorded as positive numbers.
 */
export function detectExpensesArePositive(rows, mapping) {
  if (mapping.amount === null || mapping.amount === undefined) return false;
  const values = rows.map((r) => parseAmount(r[mapping.amount])).filter((v) => v !== null && v !== 0);
  if (values.length === 0) return false;
  const negatives = values.filter((v) => v < 0).length;
  if (negatives > 0) return false; // mixed signs: the file already tells us
  // All positive: a type column decides, otherwise assume the file lists spending.
  if (mapping.type !== null && mapping.type !== undefined) {
    const debits = rows.filter((r) => DEBIT_WORDS.test(r[mapping.type] || '')).length;
    const credits = rows.filter((r) => CREDIT_WORDS.test(r[mapping.type] || '')).length;
    if (debits + credits > 0) return false; // signs come from the type column
  }
  return true;
}

/**
 * Turn raw rows into draft transactions using a mapping.
 * @returns {{rows:Array, skipped:Array<{row:string[], reason:string}>}}
 */
export function mapRows(rows, mapping) {
  const out = [];
  const skipped = [];
  const order = mapping.dateOrder || 'DMY';

  for (const row of rows) {
    const rawDate = mapping.date === null ? '' : row[mapping.date];
    const date = parseDate(rawDate, order);
    if (!date) {
      if (row.some((c) => c !== '')) skipped.push({ row, reason: 'no readable date' });
      continue;
    }

    let amount = null;
    if (mapping.debit !== null && mapping.debit !== undefined
      || mapping.credit !== null && mapping.credit !== undefined) {
      const debit = mapping.debit === null || mapping.debit === undefined
        ? null : parseAmount(row[mapping.debit]);
      const credit = mapping.credit === null || mapping.credit === undefined
        ? null : parseAmount(row[mapping.credit]);
      if (debit !== null && debit !== 0) amount = -Math.abs(debit);
      else if (credit !== null && credit !== 0) amount = Math.abs(credit);
    } else if (mapping.amount !== null && mapping.amount !== undefined) {
      amount = parseAmount(row[mapping.amount]);
      if (amount !== null) {
        if (mapping.expensesArePositive) amount = -amount;
        if (mapping.type !== null && mapping.type !== undefined) {
          const typeCell = row[mapping.type] || '';
          if (DEBIT_WORDS.test(typeCell) && !CREDIT_WORDS.test(typeCell)) amount = -Math.abs(amount);
          else if (CREDIT_WORDS.test(typeCell) && !DEBIT_WORDS.test(typeCell)) amount = Math.abs(amount);
        }
      }
    }

    if (amount === null) {
      skipped.push({ row, reason: 'no readable amount' });
      continue;
    }

    const description = (mapping.description || [])
      .map((i) => row[i])
      .filter((part) => part && part.trim() !== '')
      .join(' · ');

    out.push({
      date,
      amount,
      description: description || '(no description)',
      currency: mapping.currency === null || mapping.currency === undefined
        ? null : (row[mapping.currency] || '').trim().toUpperCase() || null,
      type: mapping.type === null || mapping.type === undefined ? null : row[mapping.type] || null,
    });
  }
  return { rows: out, skipped };
}
