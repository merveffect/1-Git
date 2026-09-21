/** The full ledger: search, filter, fix categories, exclude one-offs. */

import { el, mount } from '../dom.js';
import { store, options, setCategory, setExcluded, setNote, exportCSV } from '../state.js';
import { periodKey } from '../lib/dates.js';
import { categoryKind } from '../lib/categorize.js';
import { card, money, formatDate, categorySelect, toast, downloadFile, field } from './common.js';

const PAGE_SIZE = 150;

let filters = { search: '', category: '', direction: 'all', from: '', to: '', account: '', period: null, granularity: 'month' };
let visible = PAGE_SIZE;

export function setTransactionFilters(params = {}) {
  filters = {
    search: params.search || '',
    category: params.category || '',
    direction: params.direction || 'all',
    from: params.from || '',
    to: params.to || '',
    account: params.account || '',
    period: params.period || null,
    granularity: params.granularity || 'month',
  };
  visible = PAGE_SIZE;
}

function matches(tx) {
  const { weekStart } = store.data.settings;
  if (filters.period && periodKey(tx.date, filters.granularity, weekStart) !== filters.period) return false;
  if (filters.category && tx.category !== filters.category) return false;
  if (filters.account && tx.account !== filters.account) return false;
  if (filters.from && tx.date < filters.from) return false;
  if (filters.to && tx.date > filters.to) return false;
  if (filters.direction === 'in' && tx.amountCents < 0) return false;
  if (filters.direction === 'out' && tx.amountCents >= 0) return false;
  if (filters.search) {
    const needle = filters.search.toLowerCase();
    const haystack = `${tx.description} ${tx.merchantLabel} ${tx.category} ${tx.note}`.toLowerCase();
    if (!haystack.includes(needle)) return false;
  }
  return true;
}

export function renderTransactions(navigate) {
  const container = el('div');
  const listSlot = el('div');

  const redraw = () => mount(listSlot, listCard(redraw));

  const searchInput = el('input', {
    type: 'search', placeholder: 'Search description, merchant or note…', value: filters.search,
    oninput: (event) => {
      filters.search = event.target.value;
      visible = PAGE_SIZE;
      redraw();
    },
  });

  const categoryFilter = el('select', {
    onchange: (event) => { filters.category = event.target.value; redraw(); },
  }, [
    el('option', { value: '', text: 'All categories', selected: filters.category === '' }),
    ...(store.data.categories).map((category) => el('option', {
      value: category.name, text: category.name, selected: filters.category === category.name,
    })),
  ]);

  const directionFilter = el('select', {
    onchange: (event) => { filters.direction = event.target.value; redraw(); },
  }, [
    el('option', { value: 'all', text: 'In and out', selected: filters.direction === 'all' }),
    el('option', { value: 'out', text: 'Money out only', selected: filters.direction === 'out' }),
    el('option', { value: 'in', text: 'Money in only', selected: filters.direction === 'in' }),
  ]);

  const fromInput = el('input', {
    type: 'date', value: filters.from,
    onchange: (event) => { filters.from = event.target.value; redraw(); },
  });
  const toInput = el('input', {
    type: 'date', value: filters.to,
    onchange: (event) => { filters.to = event.target.value; redraw(); },
  });

  mount(container, [
    el('div', { class: 'page-head' }, [
      el('div', {}, [
        el('h1', { text: 'Transactions' }),
        el('p', { class: 'page-subtitle', text: 'Fix a category once and the app can remember it for next time.' }),
      ]),
      el('div', { class: 'btn-row' }, [
        el('button', {
          class: 'btn-small',
          text: 'Clear filters',
          onclick: () => { setTransactionFilters({}); navigate('transactions'); },
        }),
        el('button', {
          class: 'btn-small',
          text: 'Export shown as CSV',
          onclick: () => {
            const rows = store.data.transactions.filter(matches);
            downloadFile(`transactions-${new Date().toISOString().slice(0, 10)}.csv`, exportCSV(rows), 'text/csv');
            toast('Exported as plain CSV — that file is not encrypted, keep it somewhere safe.', 'bad');
          },
        }),
      ]),
    ]),
    card(null, [
      el('div', { class: 'field-row' }, [
        field('Search', searchInput),
        field('Category', categoryFilter),
        field('Direction', directionFilter),
        field('From', fromInput),
        field('To', toInput),
      ]),
      filters.period ? el('p', { class: 'stat-foot', text: `Showing period ${filters.period}.` }) : null,
    ]),
    listSlot,
  ]);

  redraw();
  return container;
}

function listCard(redraw) {
  const rows = store.data.transactions.filter(matches);
  const shown = rows.slice(0, visible);
  const opts = options();
  const sums = rows.reduce((acc, tx) => {
    if (tx.excluded) return acc;
    if (!opts.includeTransfers && categoryKind(tx.category, opts.categories) === 'transfer') return acc;
    if (tx.amountCents >= 0) acc.in += tx.amountCents;
    else acc.out += -tx.amountCents;
    return acc;
  }, { in: 0, out: 0 });

  return card(null, [
    el('div', { class: 'card-head' }, [
      el('h2', { text: `${rows.length} transactions` }),
      el('span', { class: 'stat-foot', text: `In ${money(sums.in)} · Out ${money(sums.out)} · Net ${money(sums.in - sums.out)}` }),
    ]),
    rows.length === 0
      ? el('p', { class: 'empty', text: 'Nothing matches these filters.' })
      : el('div', { class: 'table-wrap' }, [
        el('table', {}, [
          el('thead', {}, [el('tr', {}, [
            el('th', { text: 'Date' }),
            el('th', { text: 'Description' }),
            el('th', { text: 'Category' }),
            el('th', { class: 'num', text: 'Amount' }),
            el('th', {}),
          ])]),
          el('tbody', {}, shown.map((tx) => transactionRow(tx, redraw))),
        ]),
      ]),
    rows.length > visible
      ? el('div', { class: 'btn-row', style: 'margin-top:14px; justify-content:center' }, [
        el('button', {
          text: `Show ${Math.min(PAGE_SIZE, rows.length - visible)} more`,
          onclick: () => { visible += PAGE_SIZE; redraw(); },
        }),
      ])
      : null,
  ]);
}

function transactionRow(tx, redraw) {
  return el('tr', { class: tx.excluded ? 'row-excluded' : '' }, [
    el('td', { text: formatDate(tx.date) }),
    el('td', { class: 'cell-desc' }, [
      el('span', { text: tx.description }),
      el('small', { text: `${tx.merchantLabel}${tx.account ? ` · ${tx.account}` : ''}${tx.note ? ` · ${tx.note}` : ''}` }),
    ]),
    el('td', {}, [
      categorySelect(tx.category, (value) => {
        setCategory(tx.id, value, { alsoCreateRule: false });
        redraw();
      }),
      tx.categorySource === 'manual'
        ? el('span', { class: 'pill', style: 'margin-left:6px', text: 'manual' })
        : null,
    ]),
    el('td', { class: `num ${tx.amountCents >= 0 ? 'amount-in' : 'amount-out'}`, text: money(tx.amountCents) }),
    el('td', { class: 'num' }, [
      el('div', { class: 'btn-row', style: 'justify-content:flex-end; flex-wrap:nowrap' }, [
        el('button', {
          class: 'btn-small btn-ghost',
          title: `Always put "${tx.merchantLabel}" in ${tx.category}`,
          text: 'Remember',
          onclick: () => {
            setCategory(tx.id, tx.category, { alsoCreateRule: true });
            toast(`From now on, "${tx.merchantLabel}" goes to ${tx.category}.`);
            redraw();
          },
        }),
        el('button', {
          class: 'btn-small btn-ghost',
          title: 'Leave this out of the totals (e.g. a one-off you moved between your own accounts)',
          text: tx.excluded ? 'Include' : 'Ignore',
          onclick: () => { setExcluded(tx.id, !tx.excluded); redraw(); },
        }),
        el('button', {
          class: 'btn-small btn-ghost',
          text: 'Note',
          onclick: () => {
            const note = window.prompt('Note for this transaction:', tx.note || '');
            if (note !== null) {
              setNote(tx.id, note);
              redraw();
            }
          },
        }),
      ]),
    ]),
  ]);
}
