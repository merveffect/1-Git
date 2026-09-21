import test from 'node:test';
import assert from 'node:assert/strict';

import { parseAmount, toCents, fromCents } from '../src/lib/money.js';
import { parseDate, detectDateOrder, weekKey, periodStart, addMonths, addDays, daysBetween } from '../src/lib/dates.js';
import { parseCSV, detectDelimiter, findTableStart } from '../src/lib/csv.js';
import { parseOFX, looksLikeOFX } from '../src/lib/ofx.js';
import { redact, normalizeMerchant, merchantLabel } from '../src/lib/text.js';

test('parseAmount handles the formats banks actually export', () => {
  assert.equal(parseAmount('1.234,56'), 1234.56);   // European
  assert.equal(parseAmount('1,234.56'), 1234.56);   // Anglo
  assert.equal(parseAmount('1 234,56'), 1234.56);   // French spacing
  assert.equal(parseAmount('12,50'), 12.5);
  assert.equal(parseAmount('1,500'), 1500);         // grouping, not decimals
  assert.equal(parseAmount('1.500'), 1500);
  assert.equal(parseAmount('-12.50'), -12.5);
  assert.equal(parseAmount('12.50-'), -12.5);       // trailing sign
  assert.equal(parseAmount('(12.50)'), -12.5);      // accounting negative
  assert.equal(parseAmount('€ 12,50'), 12.5);
  assert.equal(parseAmount('12.50 TL'), 12.5);
  assert.equal(parseAmount('100.00 DR'), -100);     // debit marker
  assert.equal(parseAmount('100.00 CR'), 100);
  assert.equal(parseAmount(' 1.000,00 '), 1000);
});

test('parseAmount rejects non-numbers', () => {
  for (const value of ['', '   ', 'Opening balance', null, undefined, 'n/a']) {
    assert.equal(parseAmount(value), null);
  }
});

test('money conversion stays exact in minor units', () => {
  assert.equal(toCents(0.1) + toCents(0.2), toCents(0.3));
  assert.equal(fromCents(toCents(1234.56)), 1234.56);
});

test('parseDate covers common layouts', () => {
  assert.equal(parseDate('2024-02-01'), '2024-02-01');
  assert.equal(parseDate('01/02/2024'), '2024-02-01');           // day first by default
  assert.equal(parseDate('01/02/2024', 'MDY'), '2024-01-02');
  assert.equal(parseDate('13/02/2024', 'MDY'), '2024-02-13');    // impossible month, self-corrects
  assert.equal(parseDate('13.02.24'), '2024-02-13');
  assert.equal(parseDate('12 Mar 2024'), '2024-03-12');
  assert.equal(parseDate('Mar 12, 2024'), '2024-03-12');
  assert.equal(parseDate('20240301'), '2024-03-01');
  assert.equal(parseDate('2024-03-01 14:22:10'), '2024-03-01');
  assert.equal(parseDate('31/02/2024'), null);                   // no such day
  assert.equal(parseDate('not a date'), null);
});

test('detectDateOrder reads the whole column', () => {
  assert.equal(detectDateOrder(['01/02/2024', '13/02/2024']), 'DMY');
  assert.equal(detectDateOrder(['02/13/2024', '02/01/2024']), 'MDY');
  assert.equal(detectDateOrder(['01/02/2024', '03/04/2024']), null); // genuinely ambiguous
});

test('period keys and helpers', () => {
  assert.equal(weekKey('2026-09-21'), '2026-W39');
  assert.equal(periodStart('2026-W39'), '2026-09-21');
  assert.equal(weekKey('2024-01-01'), '2024-W01');
  assert.equal(addMonths('2024-01-31', 1), '2024-02-29');   // clamps to a real day
  assert.equal(addDays('2024-02-28', 2), '2024-03-01');
  assert.equal(daysBetween('2024-01-01', '2024-03-01'), 60);
});

test('CSV parsing handles quotes, delimiters and preambles', () => {
  const text = 'Account: ****1234\n\nDate;Description;Amount\n01/03/2024;"Shop, big ""one""";-12,50\n';
  assert.equal(detectDelimiter(text), ';');
  const rows = parseCSV(text);
  assert.equal(findTableStart(rows), 2);
  assert.deepEqual(rows[3], ['01/03/2024', 'Shop, big "one"', '-12,50']);
});

test('CSV keeps embedded newlines inside quoted fields', () => {
  const rows = parseCSV('a,b\n"line1\nline2",2\n');
  assert.equal(rows.length, 2);
  assert.equal(rows[1][0], 'line1\nline2');
});

test('OFX statements are read', () => {
  const ofx = '<OFX><CURDEF>USD<STMTTRN><TRNTYPE>DEBIT<DTPOSTED>20240301120000[0:GMT]<TRNAMT>-45.20<NAME>TESCO</STMTTRN></OFX>';
  assert.ok(looksLikeOFX(ofx));
  const parsed = parseOFX(ofx);
  assert.equal(parsed.currency, 'USD');
  assert.deepEqual(parsed.rows[0], {
    date: '2024-03-01', amount: -45.2, description: 'TESCO', currency: 'USD', type: 'DEBIT',
  });
});

test('redaction masks identifiers but keeps merchant names', () => {
  assert.match(redact('SALARY GB29NWBK60161331926819'), /GB29•••6819$/);
  assert.match(redact('PAYMENT 4111 1111 1111 1111'), /••••1111/);
  assert.match(redact('CUSTOMER 998877665544'), /••••5544/);
  assert.equal(redact('TESCO STORES 3288'), 'TESCO STORES 3288'); // short numbers are harmless
  assert.match(redact('mail me@example.com'), /•••@•••/);
});

test('merchant normalisation groups the same shop across statements', () => {
  const a = normalizeMerchant('CARD PAYMENT TO TESCO STORES 3288 ON 01/03 REF 9988776655');
  const b = normalizeMerchant('TESCO STORES 4412');
  assert.equal(a, b);
  assert.equal(merchantLabel('CARD PAYMENT TO TESCO STORES 3288'), 'Tesco Stores');
  assert.equal(merchantLabel('RENT LANDLORD GB29•••6819'), 'Rent Landlord');
});
