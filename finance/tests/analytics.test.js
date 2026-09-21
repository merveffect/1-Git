import test from 'node:test';
import assert from 'node:assert/strict';

import {
  byPeriod, byCategory, byMerchant, totals, cumulativeNet, inRange,
  detectRecurring, categoryTrends, monthlyAverages, goalProgress, activeTransactions,
} from '../src/lib/analytics.js';

/** Twelve tidy months of a salary, rent, Netflix and groceries. */
function sampleYear({ spikeLastMonth = false } = {}) {
  const rows = [];
  for (let month = 1; month <= 12; month += 1) {
    const mm = String(month).padStart(2, '0');
    rows.push(tx(`2026-${mm}-01`, 300000, 'SALARY', 'Salary'));
    rows.push(tx(`2026-${mm}-03`, -1299, 'NETFLIX', 'Subscriptions'));
    rows.push(tx(`2026-${mm}-05`, -90000, 'RENT', 'Housing & rent'));
    const groceries = spikeLastMonth && month === 12 ? -60000 : -20000;
    rows.push(tx(`2026-${mm}-12`, groceries, 'TESCO', 'Groceries'));
    rows.push(tx(`2026-${mm}-15`, -50000, 'TO SAVINGS', 'Savings & investments'));
  }
  return rows;
}

function tx(date, amountCents, merchant, category, extra = {}) {
  return {
    id: `${date}-${merchant}`,
    date,
    amountCents,
    description: merchant,
    merchantKey: merchant.toLowerCase(),
    merchantLabel: merchant,
    category,
    excluded: false,
    ...extra,
  };
}

test('transfers are left out of income and spending by default', () => {
  const rows = sampleYear();
  assert.equal(activeTransactions(rows).length, 48);                       // savings moves dropped
  assert.equal(activeTransactions(rows, { includeTransfers: true }).length, 60);
  const summary = totals(rows);
  assert.equal(summary.incomeCents, 12 * 300000);
  assert.equal(summary.expenseCents, 12 * (1299 + 90000 + 20000));
  assert.equal(summary.netCents, summary.incomeCents - summary.expenseCents);
  assert.equal(summary.savingsRate, summary.netCents / summary.incomeCents);
  assert.ok(summary.savingsRate > 0.6 && summary.savingsRate < 0.7);
});

test('excluded transactions are ignored everywhere', () => {
  const rows = [...sampleYear(), tx('2026-06-06', -100000, 'ONE OFF', 'Shopping', { excluded: true })];
  assert.equal(totals(rows).expenseCents, totals(sampleYear()).expenseCents);
});

test('weekly, monthly and yearly buckets line up', () => {
  const rows = sampleYear();
  assert.equal(byPeriod(rows, { granularity: 'month' }).length, 12);
  assert.equal(byPeriod(rows, { granularity: 'year' }).length, 1);
  const weeks = byPeriod(rows, { granularity: 'week' });
  assert.ok(weeks.length >= 30, 'roughly one bucket per week with activity');
  const monthlyNet = byPeriod(rows, { granularity: 'month' }).reduce((a, p) => a + p.netCents, 0);
  const weeklyNet = weeks.reduce((a, p) => a + p.netCents, 0);
  assert.equal(monthlyNet, weeklyNet, 'the same money, bucketed differently');
});

test('periods are sorted oldest first and carry their start date', () => {
  const periods = byPeriod(sampleYear(), { granularity: 'month' });
  assert.equal(periods[0].key, '2026-01');
  assert.equal(periods[0].start, '2026-01-01');
  assert.equal(periods[11].key, '2026-12');
});

test('category breakdown ranks spending and shares add up', () => {
  const spend = byCategory(sampleYear(), 'out');
  assert.equal(spend[0].category, 'Housing & rent');
  assert.equal(spend[0].cents, 12 * 90000);
  assert.ok(Math.abs(spend.reduce((a, c) => a + c.share, 0) - 1) < 1e-9);
  const income = byCategory(sampleYear(), 'in');
  assert.deepEqual(income.map((c) => c.category), ['Salary']);
});

test('merchant breakdown groups by normalised name', () => {
  const merchants = byMerchant(sampleYear(), 'out');
  assert.equal(merchants[0].label, 'RENT');
  assert.equal(merchants[0].count, 12);
  assert.equal(merchants[0].lastDate, '2026-12-05');
});

test('cumulative net tracks the running total', () => {
  const periods = byPeriod(sampleYear(), { granularity: 'month' });
  const trail = cumulativeNet(periods);
  assert.equal(trail.length, 12);
  assert.equal(trail[11].cumulativeCents, periods.reduce((a, p) => a + p.netCents, 0));
  assert.ok(trail[0].cumulativeCents < trail[11].cumulativeCents);
});

test('date ranges filter inclusively', () => {
  const rows = sampleYear();
  const q2 = inRange(rows, '2026-04-01', '2026-06-30');
  assert.equal(byPeriod(q2, { granularity: 'month' }).length, 3);
});

test('recurring payments are found with their cadence and monthly cost', () => {
  const recurring = detectRecurring(sampleYear());
  const netflix = recurring.find((r) => r.label === 'NETFLIX');
  assert.ok(netflix, 'Netflix is recognised as recurring');
  assert.equal(netflix.cadence, 'monthly');
  assert.equal(netflix.typicalCents, 1299);
  assert.equal(netflix.monthlyCents, 1299);
  assert.equal(netflix.yearlyCents, 1299 * 12);
  assert.equal(netflix.intervalDays, 31);
  assert.equal(netflix.nextExpected, '2027-01-03'); // last seen 3 Dec + the typical gap
});

test('one-off and irregular spending is not called recurring', () => {
  const rows = [
    tx('2026-01-04', -5000, 'RANDOM', 'Shopping'),
    tx('2026-03-19', -8000, 'RANDOM', 'Shopping'),
    tx('2026-09-02', -2000, 'RANDOM', 'Shopping'),
  ];
  assert.equal(detectRecurring(rows).length, 0);
});

test('weekly recurring payments are detected too', () => {
  const rows = [];
  for (let week = 0; week < 8; week += 1) {
    const day = String(5 + week * 7).padStart(2, '0');
    const date = week < 4 ? `2026-01-${day}` : `2026-02-${String(week * 7 - 26).padStart(2, '0')}`;
    rows.push(tx(date, -1500, 'CLEANER', 'Housing & rent'));
  }
  const found = detectRecurring(rows);
  assert.equal(found.length, 1);
  assert.equal(found[0].cadence, 'weekly');
});

test('category trends compare the latest month with the recent average', () => {
  const trends = categoryTrends(sampleYear({ spikeLastMonth: true }), { granularity: 'month' });
  const groceries = trends.find((t) => t.category === 'Groceries');
  assert.equal(groceries.currentCents, 60000);
  assert.equal(groceries.averageCents, 20000);
  assert.equal(groceries.deltaCents, 40000);
  assert.equal(groceries.deltaRatio, 2);
  assert.equal(trends[0].category, 'Groceries', 'biggest mover comes first');
});

test('monthly averages divide by the months actually present', () => {
  const averages = monthlyAverages(sampleYear());
  assert.equal(averages.months, 12);
  assert.equal(averages.incomeCents, 300000);
  assert.equal(averages.expenseCents, 1299 + 90000 + 20000);
});

test('goal progress reports what is saved, what is left and the pace', () => {
  const progress = goalProgress(
    { startDate: '2026-01-01', targetCents: 3000000, startCents: 100000 },
    sampleYear(),
  );
  const kept = totals(sampleYear()).netCents;
  assert.equal(progress.savedCents, kept + 100000);
  assert.equal(progress.remainingCents, 3000000 - (kept + 100000));
  assert.ok(progress.progress > 0 && progress.progress < 1);
  assert.equal(progress.monthlyNetCents, Math.round(kept / 12));
  assert.ok(progress.monthsNeeded > 0);
});

test('a reached goal reports no remaining amount and full progress', () => {
  const progress = goalProgress(
    { startDate: '2026-01-01', targetCents: 100000, startCents: 0 },
    sampleYear(),
  );
  assert.equal(progress.remainingCents, 0);
  assert.equal(progress.progress, 1);
});

test('a goal with a deadline says whether the pace is enough', () => {
  const rows = sampleYear();
  const tight = goalProgress({ startDate: '2026-01-01', targetCents: 99000000, targetDate: '2027-01-01' }, rows);
  assert.equal(tight.onTrack, false);
  assert.ok(tight.requiredMonthlyCents > tight.monthlyNetCents);
});
