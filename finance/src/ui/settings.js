/** Preferences, security controls and backups. */

import { el, mount } from '../dom.js';
import {
  store, updateSettings, setPref, changePassphrase, exportEncryptedBackup,
  exportCSV, wipeEverything, lock, recategorizeAll,
} from '../state.js';
import { card, field, toast, downloadFile } from './common.js';

const CURRENCIES = ['EUR', 'USD', 'GBP', 'TRY', 'CHF', 'SEK', 'NOK', 'DKK', 'PLN', 'CAD', 'AUD', 'JPY'];

export function renderSettings(navigate, onLocked) {
  const container = el('div');
  const settings = store.data.settings;

  mount(container, [
    el('div', { class: 'page-head' }, [
      el('div', {}, [
        el('h1', { text: 'Settings' }),
        el('p', { class: 'page-subtitle', text: 'Everything here applies to this device only.' }),
      ]),
    ]),

    card('How your money is shown', [
      el('div', { class: 'field-row' }, [
        field('Currency', el('select', {
          onchange: (event) => { updateSettings({ currency: event.target.value }); toast('Currency updated.'); },
        }, CURRENCIES.map((code) => el('option', {
          value: code, text: code, selected: settings.currency === code,
        })))),
        field('Number & date format', el('select', {
          onchange: (event) => { updateSettings({ locale: event.target.value }); toast('Format updated.'); },
        }, [
          el('option', { value: '', text: 'Match my browser', selected: !settings.locale }),
          ...['en-GB', 'en-US', 'de-DE', 'fr-FR', 'tr-TR', 'es-ES', 'nl-NL'].map((code) => el('option', {
            value: code, text: code, selected: settings.locale === code,
          })),
        ])),
        field('Weeks start on', el('select', {
          onchange: (event) => updateSettings({ weekStart: Number(event.target.value) }),
        }, [
          el('option', { value: '1', text: 'Monday', selected: settings.weekStart === 1 }),
          el('option', { value: '0', text: 'Sunday', selected: settings.weekStart === 0 }),
        ])),
        field('Appearance', el('select', {
          onchange: (event) => {
            setPref('theme', event.target.value);
            applyTheme(event.target.value);
          },
        }, [
          el('option', { value: '', text: 'Match my system', selected: !store.prefs.theme }),
          el('option', { value: 'light', text: 'Light', selected: store.prefs.theme === 'light' }),
          el('option', { value: 'dark', text: 'Dark', selected: store.prefs.theme === 'dark' }),
        ])),
      ]),
      el('label', { class: 'checkbox' }, [
        el('input', {
          type: 'checkbox',
          checked: settings.includeTransfers,
          onchange: (event) => updateSettings({ includeTransfers: event.target.checked }),
        }),
        el('span', { text: 'Count transfers and savings moves as income/spending (off by default, so moving money between your own accounts does not inflate the totals)' }),
      ]),
    ]),

    card('Security', [
      el('div', { class: 'notice' }, [
        'Your vault is encrypted with AES-256-GCM. The key is derived from your passphrase with PBKDF2-SHA256 (600,000 rounds) and never leaves this device — there is no server and no account.',
      ]),
      el('div', { class: 'field-row' }, [
        field('Lock automatically after', el('select', {
          onchange: (event) => updateSettings({ autoLockMinutes: Number(event.target.value) }),
        }, [
          { value: 1, text: '1 minute' }, { value: 5, text: '5 minutes' },
          { value: 10, text: '10 minutes' }, { value: 30, text: '30 minutes' },
          { value: 0, text: 'Never (not recommended)' },
        ].map((option) => el('option', {
          value: String(option.value), text: option.text, selected: settings.autoLockMinutes === option.value,
        })))),
      ]),
      el('label', { class: 'checkbox' }, [
        el('input', {
          type: 'checkbox',
          checked: settings.redactPII,
          onchange: (event) => {
            updateSettings({ redactPII: event.target.checked });
            toast('Applies to statements you import from now on.');
          },
        }),
        el('span', { text: 'Mask IBANs, card and account numbers in descriptions when importing' }),
      ]),
      el('div', { class: 'btn-row' }, [
        el('button', { text: 'Lock now', onclick: () => { lock(); onLocked(); } }),
        el('button', { text: 'Change passphrase', onclick: () => changePassphraseFlow() }),
      ]),
    ]),

    card('Backups', [
      el('p', { class: 'stat-foot', style: 'margin-bottom:12px' }, [
        'Browser storage can be cleared by the browser itself. Export an encrypted backup now and then — it is the same sealed blob, useless to anyone without your passphrase, so it is safe in cloud storage or on a USB stick.',
      ]),
      el('div', { class: 'btn-row' }, [
        el('button', {
          class: 'btn-primary',
          text: 'Download encrypted backup',
          onclick: async () => {
            const json = await exportEncryptedBackup();
            downloadFile(`finance-vault-${new Date().toISOString().slice(0, 10)}.json`, json);
            toast('Encrypted backup downloaded.');
          },
        }),
        el('button', {
          text: 'Download plain CSV',
          onclick: () => {
            if (!window.confirm('A CSV export is NOT encrypted — anyone who opens the file sees your transactions. Continue?')) return;
            downloadFile(`transactions-${new Date().toISOString().slice(0, 10)}.csv`, exportCSV(), 'text/csv');
            toast('Plain CSV downloaded — store it carefully.', 'bad');
          },
        }),
      ]),
    ]),

    card('Data', [
      el('p', { class: 'stat-foot', style: 'margin-bottom:12px', text: `${store.data.transactions.length} transactions, ${store.data.rules.length} rules, ${store.data.imports.length} imports, ${store.data.goals.length} goals.` }),
      el('div', { class: 'btn-row' }, [
        el('button', {
          text: 'Re-categorise everything',
          onclick: () => { recategorizeAll(); toast('Done.'); },
        }),
        el('button', {
          class: 'btn-danger',
          text: 'Delete the vault on this device',
          onclick: async () => {
            if (!window.confirm('This permanently deletes every transaction, rule and goal stored in this browser. Without a backup file it cannot be undone. Continue?')) return;
            if (!window.confirm('Really delete everything?')) return;
            await wipeEverything();
            onLocked();
          },
        }),
      ]),
    ]),
  ]);

  return container;
}

export function applyTheme(theme) {
  if (theme) document.documentElement.dataset.theme = theme;
  else delete document.documentElement.dataset.theme;
}

async function changePassphraseFlow() {
  const current = window.prompt('Current passphrase:');
  if (!current) return;
  const next = window.prompt('New passphrase (at least 8 characters):');
  if (!next) return;
  if (next.length < 8) {
    toast('That new passphrase is too short.', 'bad');
    return;
  }
  const confirmed = window.prompt('Type the new passphrase again:');
  if (confirmed !== next) {
    toast('The new passphrases did not match.', 'bad');
    return;
  }
  try {
    await changePassphrase(current, next);
    toast('Passphrase changed. Older backup files still need the old one.');
  } catch {
    toast('That current passphrase is not right.', 'bad');
  }
}
