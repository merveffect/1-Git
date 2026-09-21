/** The overview: money in, money out, where it went, and what it is doing over time. */

import { el } from '../dom.js';
import { store, options, setPref } from '../state.js';
import {
  byPeriod, byCategory, byMerchant, totals, cumulativeNet, inRange,
  insights, detectRecurring, categoryTrends, monthlyAverages, activeTransactions,
} from '../lib/analytics.js';
import { addMonths, todayISO, monthKey } from '../lib/dates.js';
import { incomeExpenseChart, cumulativeChart, categoryBars, legend } from '../charts.js';
import { card, stat, money, label, segmented, tone, formatDate } from './common.js';

const RANGES = [
  { value: 'this-month', label: 'This month' },
  { value: '3m', label: '3 months' },
  { value: '12m', label: '12 months' },
  { value: 'ytd', label: 'This year' },
  { value: 'all', label: 'All time' },
];

export function rangeBounds(range) {
  const today = todayISO();
  switch (range) {
    case 'this-month': return { from: `${monthKey(today)}-01`, to: null };
    case '3m': return { from: addMonths(today, -3), to: null };
    case '12m': return { from: addMonths(today, -12), to: null };
    case 'ytd': return { from: `${today.slice(0, 4)}-01-01`, to: null };
    default: return { from: null, to: null };
  }
}

export function renderDashboard(navigate) {
  const granularity = store.prefs.granularity || 'month';
  const range = store.prefs.range || '12m';
  const opts = { ...options(), granularity };
  const all = store.data.transactions;
  const { from, to } = rangeBounds(range);
  const scoped = inRange(all, from, to);

  if (all.length === 0) return emptyState(navigate);

  const periods = byPeriod(scoped, opts);
  const periodsWithLabels = periods.map((period) => ({ ...period, label: label(period.key) }));
  const summary = totals(scoped, opts);
  const spending = byCategory(scoped, 'out', opts);
  const earning = byCategory(scoped, 'in', opts);
  const merchants = byMerchant(scoped, 'out', opts);
  const trail = cumulativeNet(periods).map((point) => ({ ...point, label: label(point.key) }));
  const averages = monthlyAverages(scoped, opts);
  const recurring = detectRecurring(all, opts);
  const trends = categoryTrends(scoped, { ...opts, granularity: 'month' });
  const highlights = insights(scoped, { ...opts, formatMoney: money });
  const counted = activeTransactions(scoped, opts).length;

  const periodWord = granularity === 'week' ? 'week' : granularity === 'year' ? 'year' : 'month';
  const latest = periodsWithLabels[periodsWithLabels.length - 1];

  return el('div', {}, [
    el('div', { class: 'page-head' }, [
      el('div', {}, [
        el('h1', { text: 'Overview' }),
        el('p', {
          class: 'page-subtitle',
          text: `${counted} transactions${from ? ` since ${formatDate(from)}` : ''}`
            + `${store.data.settings.includeTransfers ? '' : ' · transfers excluded'}`,
        }),
      ]),
      el('div', { class: 'btn-row' }, [
        segmented(RANGES, range, (value) => setPref('range', value)),
        segmented([
          { value: 'week', label: 'Weekly' },
          { value: 'month', label: 'Monthly' },
          { value: 'year', label: 'Yearly' },
        ], granularity, (value) => setPref('granularity', value)),
      ]),
    ]),

    el('div', { class: 'grid grid-stats' }, [
      stat('Money in', money(summary.incomeCents), {
        tone: 'is-income',
        foot: `${money(averages.incomeCents)} per month on average`,
      }),
      stat('Money out', money(summary.expenseCents), {
        tone: 'is-expense',
        foot: `${money(averages.expenseCents)} per month on average`,
      }),
      stat('Kept', money(summary.netCents), {
        tone: tone(summary.netCents),
        foot: summary.savingsRate === null
          ? 'No income recorded in this range'
          : `${(summary.savingsRate * 100).toFixed(0)}% of everything that came in`,
      }),
      stat(`Latest ${periodWord}`, latest ? money(latest.netCents) : '—', {
        tone: latest ? tone(latest.netCents) : '',
        foot: latest ? `${latest.label}: in ${money(latest.incomeCents)}, out ${money(latest.expenseCents)}` : '',
      }),
    ]),

    el('div', { style: 'height:16px' }),

    card('Income vs spending', [
      incomeExpenseChart(periodsWithLabels, {
        width: 760,
        currency: store.data.settings.currency,
        locale: store.data.settings.locale || undefined,
        onSelect: (period) => navigate('transactions', { period: period.key, granularity }),
      }),
      legend([
        { key: 'income', label: 'Money in' },
        { key: 'expense', label: 'Money out' },
      ]),
      el('p', { class: 'stat-foot', style: 'margin-top:8px', text: `Click a ${periodWord} to see its transactions.` }),
    ]),

    el('div', { class: 'grid grid-two', style: 'margin-top:16px' }, [
      card('Where your money goes', [
        categoryBars(spending, {
          currency: store.data.settings.currency,
          locale: store.data.settings.locale || undefined,
          limit: 10,
          onSelect: (item) => navigate('transactions', { category: item.category, from, to }),
        }),
      ], spending.length > 10 ? el('span', { class: 'pill', text: `top 10 of ${spending.length}` }) : null),

      card('What you kept over time', [
        cumulativeChart(trail, {
          width: 480,
          currency: store.data.settings.currency,
          locale: store.data.settings.locale || undefined,
        }),
        el('p', { class: 'stat-foot', style: 'margin-top:6px', text: 'Running total of money in minus money out across the range.' }),
      ]),
    ]),

    el('div', { class: 'grid grid-two', style: 'margin-top:16px' }, [
      card('Biggest places your money went', [
        categoryBars(merchants.slice(0, 8).map((m) => ({ ...m, category: m.label })), {
          currency: store.data.settings.currency,
          locale: store.data.settings.locale || undefined,
          limit: 8,
          onSelect: (item) => navigate('transactions', { search: item.label, from, to }),
        }),
      ]),
      card('Worth knowing', [
        highlights.length === 0
          ? el('p', { class: 'empty', text: 'Import another month to unlock trends.' })
          : el('ul', { style: 'margin:0; padding-left:18px; display:flex; flex-direction:column; gap:8px' },
            highlights.map((item) => el('li', { class: 'stat-foot', style: 'font-size:13.5px; color:var(--text-secondary)', text: item.text }))),
        trends.length > 0 ? el('div', { style: 'margin-top:14px' }, [
          el('h3', { text: 'Moved most vs your recent average' }),
          el('div', { class: 'table-wrap', style: 'margin-top:8px' }, [
            el('table', {}, [
              el('tbody', {}, trends.slice(0, 5).map((row) => el('tr', {}, [
                el('td', { text: row.category }),
                el('td', { class: 'num', text: money(row.currentCents) }),
                el('td', { class: 'num' }, [
                  el('span', {
                    class: `pill ${row.deltaCents > 0 ? 'pill-bad' : 'pill-good'}`,
                    text: `${row.deltaCents > 0 ? '+' : ''}${money(row.deltaCents)}`,
                  }),
                ]),
              ]))),
            ]),
          ]),
        ]) : null,
      ]),
    ]),

    recurring.length > 0 ? el('div', { style: 'margin-top:16px' }, [
      card('Regular payments', [
        el('p', { class: 'stat-foot', style: 'margin-bottom:10px', text: `${recurring.length} payments repeat on a schedule — about ${money(recurring.reduce((acc, r) => acc + r.monthlyCents, 0))} a month, ${money(recurring.reduce((acc, r) => acc + r.yearlyCents, 0))} a year.` }),
        el('div', { class: 'table-wrap' }, [
          el('table', {}, [
            el('thead', {}, [el('tr', {}, [
              el('th', { text: 'Payment' }), el('th', { text: 'Category' }), el('th', { text: 'Every' }),
              el('th', { class: 'num', text: 'Typical' }), el('th', { class: 'num', text: 'Per month' }),
              el('th', { text: 'Next expected' }),
            ])]),
            el('tbody', {}, recurring.slice(0, 8).map((item) => el('tr', {}, [
              el('td', { text: item.label }),
              el('td', {}, [el('span', { class: 'pill', text: item.category })]),
              el('td', { text: item.cadence }),
              el('td', { class: 'num', text: money(item.typicalCents) }),
              el('td', { class: 'num', text: money(item.monthlyCents) }),
              el('td', { text: formatDate(item.nextExpected) }),
            ]))),
          ]),
        ]),
      ], el('button', { class: 'btn-small', text: 'See all transactions', onclick: () => navigate('transactions') })),
    ]) : null,

    earning.length > 1 ? el('div', { style: 'margin-top:16px' }, [
      card('Where your money comes from', [
        el('div', { class: 'bar-list-wrap' }, [
          (() => {
            const node = categoryBars(earning, {
              currency: store.data.settings.currency,
              locale: store.data.settings.locale || undefined,
              limit: 6,
              onSelect: (item) => navigate('transactions', { category: item.category, from, to }),
            });
            node.classList.add('is-income');
            return node;
          })(),
        ]),
      ]),
    ]) : null,
  ]);
}

function emptyState(navigate) {
  return el('div', {}, [
    el('div', { class: 'page-head' }, [
      el('div', {}, [
        el('h1', { text: 'Overview' }),
        el('p', { class: 'page-subtitle', text: 'Nothing imported yet.' }),
      ]),
    ]),
    card(null, [
      el('div', { class: 'dropzone', onclick: () => navigate('import') }, [
        el('strong', { text: 'Start with one bank statement' }),
        el('p', { text: 'Export a CSV (or OFX/QFX) from your bank and drop it in. It is read here in your browser — it never leaves this device.' }),
        el('div', { style: 'height:14px' }),
        el('button', { class: 'btn-primary', text: 'Import a statement' }),
      ]),
    ]),
  ]);
}
