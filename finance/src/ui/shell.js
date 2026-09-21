/** Navigation shell: sidebar, routing and the auto-lock activity watch. */

import { el, mount } from '../dom.js';
import { store, subscribe, noteActivity, stopIdleTimer, lock, persist } from '../state.js';
import { hideTooltip } from '../charts.js';
import { renderDashboard } from './dashboard.js';
import { renderImport } from './import.js';
import { renderTransactions, setTransactionFilters } from './transactions.js';
import { renderGoals } from './goals.js';
import { renderRules } from './rules.js';
import { renderSettings } from './settings.js';

const ROUTES = [
  { id: 'dashboard', label: 'Overview', icon: '◎', autoRefresh: true },
  { id: 'import', label: 'Import', icon: '↑' },
  { id: 'transactions', label: 'Transactions', icon: '≡' },
  { id: 'goals', label: 'Goals', icon: '◆' },
  { id: 'rules', label: 'Categories', icon: '⌥' },
  { id: 'settings', label: 'Settings', icon: '⚙' },
];

export function renderShell(root, { onLocked }) {
  let route = 'dashboard';
  const viewSlot = el('main', { class: 'main' });
  const savingNote = el('span', { class: 'saving-dot' });

  const navigate = (next, params) => {
    route = next;
    if (next === 'transactions') setTransactionFilters(params || {});
    hideTooltip();
    draw();
    window.scrollTo({ top: 0 });
  };

  function drawView() {
    switch (route) {
      case 'import': return renderImport(navigate);
      case 'transactions': return renderTransactions(navigate);
      case 'goals': return renderGoals(navigate);
      case 'rules': return renderRules(navigate);
      case 'settings': return renderSettings(navigate, onLocked);
      default: return renderDashboard(navigate);
    }
  }

  function draw() {
    mount(viewSlot, drawView());
    root.querySelectorAll('.nav-link').forEach((link) => {
      link.classList.toggle('is-active', link.dataset.route === route);
    });
  }

  const sidebar = el('nav', { class: 'sidebar', 'aria-label': 'Sections' }, [
    el('div', { class: 'brand' }, [
      el('div', { class: 'brand-mark' }),
      el('span', { class: 'brand-name', text: 'My Money' }),
    ]),
    ...ROUTES.map((entry) => el('button', {
      class: 'nav-link',
      dataset: { route: entry.id },
      onclick: () => navigate(entry.id),
    }, [
      el('span', { class: 'nav-icon', text: entry.icon }),
      el('span', { text: entry.label }),
    ])),
    el('div', { class: 'nav-spacer' }),
    savingNote,
    el('button', {
      class: 'nav-link',
      onclick: async () => {
        await persist({ immediate: true }).catch(() => {});
        lock();
        onLocked();
      },
    }, [
      el('span', { class: 'nav-icon', text: '⏻' }),
      el('span', { text: 'Lock' }),
    ]),
  ]);

  mount(root, [el('div', { class: 'app' }, [sidebar, viewSlot])]);
  draw();

  const unsubscribe = subscribe(() => {
    savingNote.textContent = store.saving ? 'Saving…' : (store.lastError ? `Save failed: ${store.lastError}` : '');
    if (store.locked) {
      unsubscribe();
      detachActivity();
      onLocked();
      return;
    }
    const entry = ROUTES.find((r) => r.id === route);
    if (entry?.autoRefresh) draw();
  });

  const activity = () => noteActivity();
  const events = ['pointerdown', 'keydown', 'wheel', 'touchstart'];
  events.forEach((name) => window.addEventListener(name, activity, { passive: true }));
  const onHidden = () => {
    if (document.visibilityState === 'hidden') persist({ immediate: true }).catch(() => {});
  };
  document.addEventListener('visibilitychange', onHidden);
  noteActivity();

  function detachActivity() {
    events.forEach((name) => window.removeEventListener(name, activity));
    document.removeEventListener('visibilitychange', onHidden);
    stopIdleTimer();
  }

  return { navigate, destroy: () => { unsubscribe(); detachActivity(); } };
}
