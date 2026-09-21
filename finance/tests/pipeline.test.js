import test from 'node:test';
import assert from 'node:assert/strict';

import { readStatement, prepareImport, deduplicate, buildTransactions } from '../src/lib/import.js';
import { detectColumns, mapRows, detectExpensesArePositive } from '../src/lib/detect.js';
import { parseCSV, findTableStart } from '../src/lib/csv.js';
import { categorizeOne, applyRules, ruleFromTransaction } from '../src/lib/categorize.js';

const DEBIT_CREDIT = `Account statement

Transaction Date,Description,Debit,Credit,Balance
01/03/2024,TESCO STORES 3288,45.20,,1200.00
02/03/2024,SALARY ACME LTD,,2500.00,3700.00
`;

const SINGLE_AMOUNT = `date,detail,amount
2024-03-01,Coffee shop,-3.50
2024-03-02,Rent,-900.00
2024-03-03,Salary,2500.00
`;

const ALL_POSITIVE = `date,detail,amount
2024-03-01,Coffee shop,3.50
2024-03-02,Rent,900.00
`;

test('separate debit and credit columns are detected and signed correctly', () => {
  const parsed = readStatement(DEBIT_CREDIT);
  assert.equal(parsed.mapping.debit, 2);
  assert.equal(parsed.mapping.credit, 3);
  assert.equal(parsed.mapping.balance, 4);
  assert.deepEqual(parsed.rows.map((r) => r.amount), [-45.2, 2500]);
});

test('a single signed amount column is used as-is', () => {
  const parsed = readStatement(SINGLE_AMOUNT);
  assert.equal(parsed.mapping.expensesArePositive, false);
  assert.deepEqual(parsed.rows.map((r) => r.amount), [-3.5, -900, 2500]);
});

test('an all-positive amount column is read as spending', () => {
  const parsed = readStatement(ALL_POSITIVE);
  assert.equal(parsed.mapping.expensesArePositive, true);
  assert.deepEqual(parsed.rows.map((r) => r.amount), [-3.5, -900]);
});

test('a type column overrides the sign', () => {
  const rows = parseCSV('date,detail,amount,type\n2024-03-01,Shop,10.00,DEBIT\n2024-03-02,Pay,20.00,CREDIT\n');
  const start = findTableStart(rows);
  const mapping = detectColumns(rows[start], rows.slice(start + 1));
  mapping.expensesArePositive = detectExpensesArePositive(rows.slice(start + 1), mapping);
  assert.deepEqual(mapRows(rows.slice(start + 1), mapping).rows.map((r) => r.amount), [-10, 20]);
});

test('unreadable lines are reported, not silently dropped', () => {
  const parsed = readStatement('date,detail,amount\n2024-03-01,Coffee,-3.50\nTOTAL,,999\n');
  assert.equal(parsed.rows.length, 1);
  assert.equal(parsed.skipped.length, 1);
  assert.match(parsed.skipped[0].reason, /date/);
});

test('re-uploading an overlapping statement only adds what is new', () => {
  const first = readStatement(SINGLE_AMOUNT);
  const imported = prepareImport(first.rows, [], [], { importId: 'a' }).added;
  assert.equal(imported.length, 3);

  const second = readStatement(`${SINGLE_AMOUNT}2024-03-04,New thing,-10.00\n`);
  const result = prepareImport(second.rows, imported, [], { importId: 'b' });
  assert.equal(result.added.length, 1);
  assert.equal(result.duplicates.length, 3);
  assert.equal(result.added[0].description, 'New thing');
});

test('genuine same-day repeats are kept, and only the surplus is added on re-upload', () => {
  const rows = [
    { date: '2024-03-01', amount: -3.5, description: 'COFFEE SHOP' },
    { date: '2024-03-01', amount: -3.5, description: 'COFFEE SHOP' },
  ];
  const built = buildTransactions(rows, { importId: 'a' });
  assert.equal(deduplicate(built, []).added.length, 2);

  const three = buildTransactions([...rows, rows[0]], { importId: 'b' });
  const again = deduplicate(three, built);
  assert.equal(again.added.length, 1, 'only the third occurrence is new');
  assert.equal(again.duplicates.length, 2);
});

test('identifiers are masked before anything is stored', () => {
  const built = buildTransactions(
    [{ date: '2024-03-01', amount: -10, description: 'SEPA GB29NWBK60161331926819 RENT' }],
    { importId: 'a', redactPII: true },
  );
  assert.doesNotMatch(built[0].description, /60161331926819/);
  assert.match(built[0].description, /GB29•••6819/);
});

test('redaction can be switched off', () => {
  const built = buildTransactions(
    [{ date: '2024-03-01', amount: -10, description: 'SEPA GB29NWBK60161331926819 RENT' }],
    { importId: 'a', redactPII: false },
  );
  assert.match(built[0].description, /GB29NWBK60161331926819/);
});

test('built-in rules categorise common merchants', () => {
  const cases = [
    ['TESCO STORES 3288', -4520, 'Groceries'],
    ['NETFLIX.COM', -1299, 'Subscriptions'],
    ['SALARY ACME LTD', 250000, 'Salary'],
    ['UBER *TRIP', -1200, 'Transport'],
    ['ATM CASH WITHDRAWAL', -10000, 'Cash'],
  ];
  for (const [description, amountCents, expected] of cases) {
    const result = categorizeOne({ description, amountCents, merchantKey: description.toLowerCase() });
    assert.equal(result.category, expected, description);
  }
});

test('unknown transactions fall back by direction', () => {
  assert.equal(categorizeOne({ description: 'zzz', amountCents: -100 }).category, 'Uncategorised');
  assert.equal(categorizeOne({ description: 'zzz', amountCents: 100 }).category, 'Other income');
});

test('user rules beat the built-in list', () => {
  const rule = { id: 'r1', field: 'description', type: 'contains', value: 'netflix', category: 'Entertainment' };
  const result = categorizeOne({ description: 'NETFLIX.COM', amountCents: -1299 }, [rule]);
  assert.equal(result.category, 'Entertainment');
  assert.equal(result.source, 'rule');
});

test('rules can be limited to one direction and an amount range', () => {
  const rule = {
    id: 'r1', field: 'description', type: 'contains', value: 'transfer',
    category: 'Savings & investments', direction: 'out', minCents: 10000,
  };
  const out = { description: 'TRANSFER TO SAVINGS', amountCents: -50000 };
  const inbound = { description: 'TRANSFER FROM MUM', amountCents: 50000 };
  const small = { description: 'TRANSFER TO SAVINGS', amountCents: -500 };
  assert.equal(categorizeOne(out, [rule]).category, 'Savings & investments');
  assert.notEqual(categorizeOne(inbound, [rule]).category, 'Savings & investments');
  assert.notEqual(categorizeOne(small, [rule]).category, 'Savings & investments');
});

test('manual categories survive a rules re-run', () => {
  const transactions = [
    { id: '1', description: 'TESCO', amountCents: -100, category: 'Gifts & donations', categorySource: 'manual' },
    { id: '2', description: 'TESCO', amountCents: -100, category: 'Uncategorised', categorySource: 'fallback' },
  ];
  const [manual, automatic] = applyRules(transactions, []);
  assert.equal(manual.category, 'Gifts & donations');
  assert.equal(automatic.category, 'Groceries');
});

test('"remember this" builds a rule that matches the same merchant again', () => {
  const tx = { description: 'RANDOM LOCAL SHOP 771', merchantKey: 'random local shop', amountCents: -500 };
  const rule = ruleFromTransaction(tx, 'Groceries');
  const other = { description: 'RANDOM LOCAL SHOP 902', merchantKey: 'random local shop', amountCents: -800 };
  assert.equal(categorizeOne(other, [rule]).category, 'Groceries');
});
