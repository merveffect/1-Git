/** Shared UI pieces: formatting bound to the user's settings, tiles, toasts. */

import { el } from '../dom.js';
import { formatMoney } from '../lib/money.js';
import { periodLabel } from '../lib/dates.js';
import { store } from '../state.js';

export function settings() {
  return store.data?.settings || { currency: 'EUR', locale: '', weekStart: 1 };
}

export function money(cents) {
  const { currency, locale } = settings();
  return formatMoney(cents, currency || 'EUR', locale || undefined);
}

export function label(periodKeyValue) {
  const { locale, weekStart } = settings();
  return periodLabel(periodKeyValue, locale || undefined, weekStart);
}

export function formatDate(isoDate) {
  const { locale } = settings();
  return new Date(`${isoDate}T00:00:00Z`).toLocaleDateString(locale || undefined, {
    day: '2-digit', month: 'short', year: 'numeric', timeZone: 'UTC',
  });
}

export function card(title, children, actions = null) {
  return el('section', { class: 'card' }, [
    title || actions
      ? el('div', { class: 'card-head' }, [
        title ? el('h2', { text: title }) : el('span'),
        actions,
      ])
      : null,
    ...(Array.isArray(children) ? children : [children]),
  ]);
}

export function stat(labelText, value, { tone = '', foot = '' } = {}) {
  return el('div', { class: 'card stat' }, [
    el('span', { class: 'stat-label', text: labelText }),
    el('span', { class: `stat-value ${tone}`, text: value }),
    foot ? el('span', { class: 'stat-foot', text: foot }) : null,
  ]);
}

export function field(labelText, control) {
  return el('div', { class: 'field' }, [el('label', { text: labelText }), control]);
}

export function segmented(optionList, current, onChange) {
  return el('div', { class: 'segmented', role: 'tablist' }, optionList.map((option) => el('button', {
    class: option.value === current ? 'is-active' : '',
    role: 'tab',
    'aria-selected': String(option.value === current),
    text: option.label,
    onclick: () => onChange(option.value),
  })));
}

let toastTimer = null;

export function toast(message, tone = 'good') {
  document.querySelectorAll('.toast').forEach((node) => node.remove());
  const node = el('div', { class: `toast toast-${tone}`, text: message, role: 'status' });
  document.body.appendChild(node);
  if (toastTimer) clearTimeout(toastTimer);
  toastTimer = setTimeout(() => node.remove(), 4200);
}

/** Download data as a file, entirely client-side (no upload anywhere). */
export function downloadFile(filename, content, type = 'application/json') {
  const blob = new Blob([content], { type });
  const url = URL.createObjectURL(blob);
  const link = el('a', { href: url, download: filename });
  document.body.appendChild(link);
  link.click();
  link.remove();
  setTimeout(() => URL.revokeObjectURL(url), 1000);
}

export function categorySelect(value, onChange, { className = '' } = {}) {
  const categories = store.data?.categories || [];
  return el('select', {
    class: className,
    onchange: (event) => onChange(event.target.value),
  }, categories.map((category) => el('option', {
    value: category.name,
    text: category.name,
    selected: category.name === value,
  })));
}

export function tone(cents) {
  return cents >= 0 ? 'is-net' : 'is-negative';
}
