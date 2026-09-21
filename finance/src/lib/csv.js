/**
 * Minimal RFC 4180 CSV/TSV reader.
 *
 * Zero dependencies on purpose: this file runs in the browser over the user's
 * bank statement, so the less third-party code touching that data, the better.
 */

const DELIMITERS = [',', ';', '\t', '|'];

/** Count delimiter occurrences that sit outside of quoted sections. */
function countOutsideQuotes(line, delimiter) {
  let count = 0;
  let inQuotes = false;
  for (let i = 0; i < line.length; i += 1) {
    const ch = line[i];
    if (ch === '"') {
      if (inQuotes && line[i + 1] === '"') i += 1;
      else inQuotes = !inQuotes;
    } else if (ch === delimiter && !inQuotes) {
      count += 1;
    }
  }
  return count;
}

/**
 * Guess the delimiter by looking for the one that splits the sample lines into
 * the same number of fields most consistently.
 */
export function detectDelimiter(text) {
  const sample = text
    .split(/\r?\n/)
    .filter((line) => line.trim() !== '')
    .slice(0, 25);
  if (sample.length === 0) return ',';

  let best = ',';
  let bestScore = -Infinity;
  for (const delimiter of DELIMITERS) {
    const counts = sample.map((line) => countOutsideQuotes(line, delimiter));
    const mean = counts.reduce((a, b) => a + b, 0) / counts.length;
    if (mean < 0.5) continue;
    const variance = counts.reduce((a, b) => a + (b - mean) ** 2, 0) / counts.length;
    // Favour many fields, punish inconsistent field counts.
    const score = mean - variance * 2;
    if (score > bestScore) {
      bestScore = score;
      best = delimiter;
    }
  }
  return best;
}

/** Parse CSV text into an array of string arrays. Handles quotes and CRLF. */
export function parseCSV(text, delimiter) {
  const input = text.replace(/^﻿/, '');
  const sep = delimiter || detectDelimiter(input);
  const rows = [];
  let row = [];
  let field = '';
  let inQuotes = false;

  for (let i = 0; i < input.length; i += 1) {
    const ch = input[i];
    if (inQuotes) {
      if (ch === '"') {
        if (input[i + 1] === '"') {
          field += '"';
          i += 1;
        } else {
          inQuotes = false;
        }
      } else {
        field += ch;
      }
      continue;
    }
    if (ch === '"') {
      inQuotes = true;
    } else if (ch === sep) {
      row.push(field);
      field = '';
    } else if (ch === '\n') {
      row.push(field);
      rows.push(row);
      row = [];
      field = '';
    } else if (ch === '\r') {
      // handled by the \n branch
    } else {
      field += ch;
    }
  }
  row.push(field);
  rows.push(row);

  // Drop trailing blank lines produced by a final newline.
  while (rows.length > 0) {
    const last = rows[rows.length - 1];
    if (last.length === 1 && last[0].trim() === '') rows.pop();
    else break;
  }
  return rows.map((r) => r.map((cell) => cell.trim()));
}

/**
 * Bank exports often start with a preamble ("Account: ...", blank lines) before
 * the real table. Find the first row that matches the dominant column count.
 */
export function findTableStart(rows) {
  const counts = new Map();
  for (const row of rows) {
    const width = row.filter((c) => c !== '').length;
    if (width < 2) continue;
    counts.set(row.length, (counts.get(row.length) || 0) + 1);
  }
  if (counts.size === 0) return 0;
  let modal = 0;
  let modalHits = 0;
  for (const [width, hits] of counts) {
    if (hits > modalHits || (hits === modalHits && width > modal)) {
      modal = width;
      modalHits = hits;
    }
  }
  return rows.findIndex((row) => row.length === modal && row.filter((c) => c !== '').length >= 2);
}
