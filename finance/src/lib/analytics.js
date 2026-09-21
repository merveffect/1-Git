/**
 * All the number crunching: period rollups, category and merchant breakdowns,
 * recurring-payment detection, trends and savings-goal projection.
 *
 * Amounts are integer minor units (cents) throughout; negative = money out.
 */

import { periodKey, periodStart, daysBetween, addDays, addMonths, todayISO } from './dates.js';
import { categoryKind, DEFAULT_CATEGORIES } from './categorize.js';

const DEFAULTS = {
  granularity: 'month',
  weekStart: 1,
  includeTransfers: false,
  categories: DEFAULT_CATEGORIES,
};

/** Transactions that count towards income/expense statistics. */
export function activeTransactions(transactions, options = {}) {
  const { includeTransfers, categories } = { ...DEFAULTS, ...options };
  return transactions.filter((tx) => {
    if (tx.excluded) return false;
    if (!includeTransfers && categoryKind(tx.category, categories) === 'transfer') return false;
    return true;
  });
}

export function inRange(transactions, from, to) {
  return transactions.filter((tx) => (!from || tx.date >= from) && (!to || tx.date <= to));
}

/**
 * Group into periods.
 * @returns {Array<{key, start, incomeCents, expenseCents, netCents, count}>}
 */
export function byPeriod(transactions, options = {}) {
  const { granularity, weekStart } = { ...DEFAULTS, ...options };
  const buckets = new Map();
  for (const tx of activeTransactions(transactions, options)) {
    const key = periodKey(tx.date, granularity, weekStart);
    let bucket = buckets.get(key);
    if (!bucket) {
      bucket = { key, start: periodStart(key, weekStart), incomeCents: 0, expenseCents: 0, netCents: 0, count: 0 };
      buckets.set(key, bucket);
    }
    if (tx.amountCents >= 0) bucket.incomeCents += tx.amountCents;
    else bucket.expenseCents += -tx.amountCents;
    bucket.netCents += tx.amountCents;
    bucket.count += 1;
  }
  return [...buckets.values()].sort((a, b) => a.start.localeCompare(b.start));
}

export function totals(transactions, options = {}) {
  let incomeCents = 0;
  let expenseCents = 0;
  let count = 0;
  for (const tx of activeTransactions(transactions, options)) {
    if (tx.amountCents >= 0) incomeCents += tx.amountCents;
    else expenseCents += -tx.amountCents;
    count += 1;
  }
  const netCents = incomeCents - expenseCents;
  return {
    incomeCents,
    expenseCents,
    netCents,
    count,
    savingsRate: incomeCents > 0 ? netCents / incomeCents : null,
  };
}

/**
 * Spending (or income) split by category, biggest first.
 * @param {'out'|'in'} direction
 */
export function byCategory(transactions, direction = 'out', options = {}) {
  const buckets = new Map();
  let total = 0;
  for (const tx of activeTransactions(transactions, options)) {
    const isOut = tx.amountCents < 0;
    if ((direction === 'out') !== isOut) continue;
    const cents = Math.abs(tx.amountCents);
    const name = tx.category || 'Uncategorised';
    const bucket = buckets.get(name) || { category: name, cents: 0, count: 0 };
    bucket.cents += cents;
    bucket.count += 1;
    buckets.set(name, bucket);
    total += cents;
  }
  return [...buckets.values()]
    .map((b) => ({ ...b, share: total > 0 ? b.cents / total : 0 }))
    .sort((a, b) => b.cents - a.cents);
}

/** Where the money actually went, by merchant. */
export function byMerchant(transactions, direction = 'out', options = {}) {
  const buckets = new Map();
  for (const tx of activeTransactions(transactions, options)) {
    const isOut = tx.amountCents < 0;
    if ((direction === 'out') !== isOut) continue;
    const key = tx.merchantKey || tx.description || 'unknown';
    const bucket = buckets.get(key) || {
      key,
      label: tx.merchantLabel || tx.description || 'Unknown',
      category: tx.category,
      cents: 0,
      count: 0,
      lastDate: tx.date,
    };
    bucket.cents += Math.abs(tx.amountCents);
    bucket.count += 1;
    if (tx.date > bucket.lastDate) bucket.lastDate = tx.date;
    buckets.set(key, bucket);
  }
  return [...buckets.values()].sort((a, b) => b.cents - a.cents);
}

/** Running balance of net cash flow over time, for the trend chart. */
export function cumulativeNet(periods) {
  let running = 0;
  return periods.map((p) => {
    running += p.netCents;
    return { key: p.key, start: p.start, cumulativeCents: running };
  });
}

function cadenceFor(days) {
  if (days >= 5 && days <= 9) return { cadence: 'weekly', perMonth: 52 / 12 };
  if (days >= 12 && days <= 16) return { cadence: 'fortnightly', perMonth: 26 / 12 };
  if (days >= 25 && days <= 35) return { cadence: 'monthly', perMonth: 1 };
  if (days >= 58 && days <= 70) return { cadence: 'every 2 months', perMonth: 0.5 };
  if (days >= 85 && days <= 100) return { cadence: 'quarterly', perMonth: 1 / 3 };
  if (days >= 350 && days <= 380) return { cadence: 'yearly', perMonth: 1 / 12 };
  return null;
}

function median(values) {
  const sorted = [...values].sort((a, b) => a - b);
  const mid = Math.floor(sorted.length / 2);
  return sorted.length % 2 ? sorted[mid] : (sorted[mid - 1] + sorted[mid]) / 2;
}

/**
 * Subscriptions and other repeating charges: same merchant, similar amount,
 * regular interval, at least three times.
 */
export function detectRecurring(transactions, options = {}) {
  const groups = new Map();
  for (const tx of activeTransactions(transactions, options)) {
    if (tx.amountCents >= 0) continue;
    const key = tx.merchantKey || tx.description;
    if (!key) continue;
    const group = groups.get(key) || { key, label: tx.merchantLabel || tx.description, items: [] };
    group.items.push(tx);
    groups.set(key, group);
  }

  const found = [];
  for (const group of groups.values()) {
    const items = group.items.slice().sort((a, b) => a.date.localeCompare(b.date));
    if (items.length < 3) continue;

    const gaps = [];
    for (let i = 1; i < items.length; i += 1) gaps.push(daysBetween(items[i - 1].date, items[i].date));
    const typicalGap = median(gaps);
    const cadence = cadenceFor(typicalGap);
    if (!cadence) continue;
    // Intervals must be reasonably regular.
    const regular = gaps.filter((g) => Math.abs(g - typicalGap) <= Math.max(4, typicalGap * 0.35)).length;
    if (regular / gaps.length < 0.6) continue;

    const amounts = items.map((tx) => Math.abs(tx.amountCents));
    const typicalAmount = median(amounts);
    const stable = amounts.filter((a) => Math.abs(a - typicalAmount) <= Math.max(100, typicalAmount * 0.25)).length;
    if (stable / amounts.length < 0.6) continue;

    const last = items[items.length - 1];
    found.push({
      key: group.key,
      label: group.label,
      category: last.category,
      cadence: cadence.cadence,
      intervalDays: Math.round(typicalGap),
      count: items.length,
      typicalCents: Math.round(typicalAmount),
      monthlyCents: Math.round(typicalAmount * cadence.perMonth),
      yearlyCents: Math.round(typicalAmount * cadence.perMonth * 12),
      firstDate: items[0].date,
      lastDate: last.date,
      nextExpected: addDays(last.date, Math.round(typicalGap)),
    });
  }
  return found.sort((a, b) => b.monthlyCents - a.monthlyCents);
}

/**
 * Compare the latest period against the average of the ones before it and
 * return the categories that moved the most.
 */
export function categoryTrends(transactions, options = {}) {
  const { granularity, weekStart } = { ...DEFAULTS, ...options };
  const active = activeTransactions(transactions, options).filter((tx) => tx.amountCents < 0);
  const keys = [...new Set(active.map((tx) => periodKey(tx.date, granularity, weekStart)))]
    .sort((a, b) => periodStart(a, weekStart).localeCompare(periodStart(b, weekStart)));
  if (keys.length < 2) return [];

  const current = keys[keys.length - 1];
  const previous = keys.slice(Math.max(0, keys.length - 4), keys.length - 1);
  const sum = new Map();
  const baseline = new Map();

  for (const tx of active) {
    const key = periodKey(tx.date, granularity, weekStart);
    const cents = Math.abs(tx.amountCents);
    const name = tx.category || 'Uncategorised';
    if (key === current) sum.set(name, (sum.get(name) || 0) + cents);
    else if (previous.includes(key)) baseline.set(name, (baseline.get(name) || 0) + cents);
  }

  const names = new Set([...sum.keys(), ...baseline.keys()]);
  const result = [];
  for (const name of names) {
    const now = sum.get(name) || 0;
    const before = (baseline.get(name) || 0) / Math.max(1, previous.length);
    result.push({
      category: name,
      currentCents: now,
      averageCents: Math.round(before),
      deltaCents: Math.round(now - before),
      deltaRatio: before > 0 ? (now - before) / before : null,
    });
  }
  return result.sort((a, b) => Math.abs(b.deltaCents) - Math.abs(a.deltaCents));
}

/** Average monthly spend/income over the whole data set (for projections). */
export function monthlyAverages(transactions, options = {}) {
  const periods = byPeriod(transactions, { ...options, granularity: 'month' });
  if (periods.length === 0) return { incomeCents: 0, expenseCents: 0, netCents: 0, months: 0 };
  // Ignore the newest month when it is obviously partial data.
  const months = periods.length;
  const sum = periods.reduce((acc, p) => ({
    incomeCents: acc.incomeCents + p.incomeCents,
    expenseCents: acc.expenseCents + p.expenseCents,
    netCents: acc.netCents + p.netCents,
  }), { incomeCents: 0, expenseCents: 0, netCents: 0 });
  return {
    incomeCents: Math.round(sum.incomeCents / months),
    expenseCents: Math.round(sum.expenseCents / months),
    netCents: Math.round(sum.netCents / months),
    months,
  };
}

/**
 * Savings-goal progress.
 * Saved so far = net cash flow since the goal's start date, plus any opening amount.
 */
export function goalProgress(goal, transactions, options = {}) {
  const since = inRange(activeTransactions(transactions, options), goal.startDate, null);
  const net = since.reduce((acc, tx) => acc + tx.amountCents, 0);
  const savedCents = (goal.startCents || 0) + Math.max(0, net);
  const targetCents = goal.targetCents || 0;
  const remainingCents = Math.max(0, targetCents - savedCents);
  const monthly = monthlyAverages(since, options).netCents;
  const monthsNeeded = monthly > 0 ? Math.ceil(remainingCents / monthly) : null;

  let requiredMonthly = null;
  let onTrack = null;
  if (goal.targetDate) {
    const monthsLeft = Math.max(
      0,
      Math.round(daysBetween(todayISO(), goal.targetDate) / 30.44),
    );
    requiredMonthly = monthsLeft > 0 ? Math.ceil(remainingCents / monthsLeft) : remainingCents;
    onTrack = monthly >= requiredMonthly;
  }

  return {
    savedCents,
    targetCents,
    remainingCents,
    progress: targetCents > 0 ? Math.min(1, savedCents / targetCents) : 0,
    monthlyNetCents: monthly,
    monthsNeeded,
    projectedDate: monthsNeeded === null ? null : addMonths(todayISO(), monthsNeeded),
    requiredMonthlyCents: requiredMonthly,
    onTrack,
  };
}

/**
 * One-line highlights for the dashboard.
 * `options.formatMoney` lets the UI pass its currency formatter in.
 */
export function insights(transactions, options = {}) {
  const format = options.formatMoney || ((cents) => (cents / 100).toFixed(0));
  const out = [];
  const months = byPeriod(transactions, { ...options, granularity: 'month' });
  if (months.length === 0) return out;

  const latest = months[months.length - 1];
  const spend = byCategory(inRange(transactions, latest.start, null), 'out', options);
  if (spend.length > 0) {
    out.push({
      kind: 'top-category',
      text: `${spend[0].category} is your biggest spend this month at ${(spend[0].share * 100).toFixed(0)}% of everything you spent.`,
      category: spend[0].category,
      cents: spend[0].cents,
    });
  }

  const trends = categoryTrends(transactions, { ...options, granularity: 'month' });
  const riser = trends.find((t) => t.deltaRatio !== null && t.deltaRatio > 0.25 && t.deltaCents > 2000);
  if (riser) {
    out.push({
      kind: 'rising',
      text: `${riser.category} is up ${(riser.deltaRatio * 100).toFixed(0)}% versus your recent average.`,
      category: riser.category,
      cents: riser.deltaCents,
    });
  }

  const recurring = detectRecurring(transactions, options);
  if (recurring.length > 0) {
    const monthly = recurring.reduce((acc, r) => acc + r.monthlyCents, 0);
    out.push({
      kind: 'recurring',
      text: `${recurring.length} payments repeat every month and cost about ${format(monthly)} of that.`,
      cents: monthly,
    });
  }

  if (latest.incomeCents > 0) {
    const rate = latest.netCents / latest.incomeCents;
    out.push({
      kind: 'savings-rate',
      text: rate >= 0
        ? `You kept ${(rate * 100).toFixed(0)}% of what came in this month.`
        : `You spent ${Math.abs(rate * 100).toFixed(0)}% more than you earned this month.`,
      cents: latest.netCents,
    });
  }
  return out;
}
