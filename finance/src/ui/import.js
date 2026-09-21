/**
 * Statement import: drop a file, check what the app understood, confirm.
 * The file is read with FileReader in this tab - it is never sent anywhere.
 */

import { el, mount } from '../dom.js';
import { store, importStatement, undoImport } from '../state.js';
import { readStatement, remap, buildTransactions } from '../lib/import.js';
import { applyRules } from '../lib/categorize.js';
import { card, field, money, toast, formatDate } from './common.js';

const ACCEPTED = '.csv,.tsv,.txt,.ofx,.qfx';

let current = null; // { filename, parsed, mapping }

export function renderImport(navigate) {
  const container = el('div');
  const previewSlot = el('div');

  function refreshPreview() {
    mount(previewSlot, current ? previewCard(refreshPreview, navigate) : null);
  }

  async function handleFile(file) {
    if (!file) return;
    if (file.size > 20 * 1024 * 1024) {
      toast('That file is larger than 20 MB — is it really a statement?', 'bad');
      return;
    }
    const text = await file.text();
    try {
      const parsed = readStatement(text);
      if (parsed.rows.length === 0) {
        toast('No transactions could be read from that file. Check the column mapping below.', 'bad');
      }
      current = { filename: file.name, parsed, mapping: { ...parsed.mapping } };
      refreshPreview();
      previewSlot.scrollIntoView({ behavior: 'smooth', block: 'nearest' });
    } catch (error) {
      toast(`Could not read that file: ${error.message}`, 'bad');
    }
  }

  const fileInput = el('input', {
    type: 'file', accept: ACCEPTED, style: 'display:none',
    onchange: (event) => handleFile(event.target.files?.[0]),
  });

  const dropzone = el('div', {
    class: 'dropzone',
    tabindex: '0',
    role: 'button',
    onclick: () => fileInput.click(),
    onkeydown: (event) => { if (event.key === 'Enter') fileInput.click(); },
    ondragover: (event) => { event.preventDefault(); dropzone.classList.add('is-over'); },
    ondragleave: () => dropzone.classList.remove('is-over'),
    ondrop: (event) => {
      event.preventDefault();
      dropzone.classList.remove('is-over');
      handleFile(event.dataTransfer?.files?.[0]);
    },
  }, [
    el('strong', { text: 'Drop this month’s statement here' }),
    el('p', { text: 'CSV, TSV, OFX or QFX — whatever your bank exports. Excel files: save as CSV first.' }),
    el('div', { style: 'height:12px' }),
    el('button', { class: 'btn-primary', type: 'button', text: 'Choose a file' }),
    fileInput,
  ]);

  mount(container, [
    el('div', { class: 'page-head' }, [
      el('div', {}, [
        el('h1', { text: 'Import a statement' }),
        el('p', { class: 'page-subtitle', text: 'Every month: export from your bank, drop it here. Repeats from an overlapping statement are detected and skipped.' }),
      ]),
    ]),
    el('div', { class: 'notice' }, [
      'The file is parsed inside this browser tab. Nothing is uploaded, and account numbers, IBANs and card numbers are masked out of the descriptions before anything is stored.',
    ]),
    dropzone,
    previewSlot,
    historyCard(),
  ]);

  refreshPreview();
  return container;
}

function columnSelect(headers, value, onChange, { allowNone = true } = {}) {
  return el('select', {
    onchange: (event) => onChange(event.target.value === '' ? null : Number(event.target.value)),
  }, [
    allowNone ? el('option', { value: '', text: '— none —', selected: value === null || value === undefined }) : null,
    ...headers.map((header, index) => el('option', {
      value: String(index),
      text: `${index + 1}. ${header || '(unnamed)'}`,
      selected: value === index,
    })),
  ]);
}

function previewCard(refresh, navigate) {
  const { parsed, mapping, filename } = current;
  const isCSV = parsed.kind === 'csv';
  const mapped = isCSV ? remap(parsed.body, mapping) : { rows: parsed.rows, skipped: parsed.skipped };
  const preview = applyRules(
    buildTransactions(mapped.rows.slice(0, 8), {
      currency: store.data.settings.currency,
      redactPII: store.data.settings.redactPII,
      importId: 'preview',
    }),
    store.data.rules,
  );

  const set = (patch) => {
    current.mapping = { ...current.mapping, ...patch };
    refresh();
  };

  const controls = isCSV ? el('div', {}, [
    el('div', { class: 'field-row' }, [
      field('Date column', columnSelect(parsed.headers, mapping.date, (value) => set({ date: value }), { allowNone: false })),
      field('Date order', el('select', {
        onchange: (event) => set({ dateOrder: event.target.value }),
      }, [
        el('option', { value: 'DMY', text: 'Day first (31/01/2026)', selected: mapping.dateOrder === 'DMY' }),
        el('option', { value: 'MDY', text: 'Month first (01/31/2026)', selected: mapping.dateOrder === 'MDY' }),
      ])),
      field('Description column', columnSelect(parsed.headers, mapping.description?.[0] ?? null, (value) => set({ description: value === null ? [] : [value] }))),
    ]),
    el('div', { class: 'field-row' }, [
      field('Amount column', columnSelect(parsed.headers, mapping.amount, (value) => set({ amount: value }))),
      field('Money out column', columnSelect(parsed.headers, mapping.debit, (value) => set({ debit: value }))),
      field('Money in column', columnSelect(parsed.headers, mapping.credit, (value) => set({ credit: value }))),
    ]),
    mapping.amount !== null && mapping.amount !== undefined
      ? el('label', { class: 'checkbox' }, [
        el('input', {
          type: 'checkbox',
          checked: !!mapping.expensesArePositive,
          onchange: (event) => set({ expensesArePositive: event.target.checked }),
        }),
        el('span', { text: 'Spending is written as a positive number in this file' }),
      ])
      : null,
  ]) : el('p', { class: 'stat-foot', text: 'OFX files carry their own structure, so there is nothing to map.' });

  const accountInput = el('input', {
    placeholder: 'e.g. Main current account',
    value: current.account || '',
    oninput: (event) => { current.account = event.target.value; },
  });

  const readable = mapped.rows.length;
  const skipped = mapped.skipped.length;

  return card(`Check before importing — ${filename}`, [
    el('p', {
      class: readable === 0 ? 'notice notice-bad' : 'notice',
      text: readable === 0
        ? 'No rows could be read. Pick the right columns below and the preview will update.'
        : `${readable} transactions read${skipped ? `, ${skipped} lines ignored (headers, totals or blanks)` : ''}. Check that the first rows look right.`,
    }),
    controls,
    field('Which account is this? (optional)', accountInput),
    el('div', { class: 'table-wrap' }, [
      el('table', { class: 'preview-table' }, [
        el('thead', {}, [el('tr', {}, [
          el('th', { text: 'Date' }), el('th', { text: 'Description (masked)' }),
          el('th', { text: 'Category' }), el('th', { class: 'num', text: 'Amount' }),
        ])]),
        el('tbody', {}, preview.length === 0
          ? [el('tr', {}, [el('td', { colspan: '4', class: 'empty', text: 'Nothing to preview yet.' })])]
          : preview.map((tx) => el('tr', {}, [
            el('td', { text: formatDate(tx.date) }),
            el('td', { text: tx.description }),
            el('td', {}, [el('span', { class: 'pill', text: tx.category })]),
            el('td', { class: `num ${tx.amountCents >= 0 ? 'amount-in' : 'amount-out'}`, text: money(tx.amountCents) }),
          ]))),
      ]),
    ]),
    el('div', { class: 'btn-row', style: 'margin-top:16px' }, [
      el('button', {
        class: 'btn-primary',
        disabled: readable === 0,
        text: `Import ${readable} transactions`,
        onclick: () => {
          const result = importStatement(mapped.rows, {
            filename,
            skipped,
            account: current.account || '',
          });
          current = null;
          toast(result.duplicates > 0
            ? `Imported ${result.added} new transactions. ${result.duplicates} were already in your vault and were skipped.`
            : `Imported ${result.added} transactions.`);
          navigate('dashboard');
        },
      }),
      el('button', { class: 'btn-ghost', text: 'Cancel', onclick: () => { current = null; refresh(); } }),
    ]),
  ]);
}

function historyCard() {
  const imports = store.data.imports;
  if (imports.length === 0) return null;
  return el('div', { style: 'margin-top:16px' }, [
    card('Import history', [
      el('div', { class: 'table-wrap' }, [
        el('table', {}, [
          el('thead', {}, [el('tr', {}, [
            el('th', { text: 'File' }), el('th', { text: 'When' }), el('th', { text: 'Account' }),
            el('th', { class: 'num', text: 'Added' }), el('th', { class: 'num', text: 'Skipped as duplicate' }), el('th', {}),
          ])]),
          el('tbody', {}, imports.map((entry) => el('tr', {}, [
            el('td', { text: entry.filename }),
            el('td', { text: new Date(entry.importedAt).toLocaleString() }),
            el('td', { text: entry.account || '—' }),
            el('td', { class: 'num', text: String(entry.added) }),
            el('td', { class: 'num', text: String(entry.duplicates) }),
            el('td', { class: 'num' }, [
              el('button', {
                class: 'btn-small btn-danger',
                text: 'Undo',
                onclick: () => {
                  if (window.confirm(`Remove the ${entry.added} transactions imported from ${entry.filename}?`)) {
                    undoImport(entry.id);
                    toast('Import undone.');
                  }
                },
              }),
            ]),
          ]))),
        ]),
      ]),
    ]),
  ]);
}
