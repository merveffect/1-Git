/** Savings goals: how far along, and whether the current pace gets there. */

import { el, mount } from '../dom.js';
import { store, options, saveGoal, deleteGoal } from '../state.js';
import { goalProgress } from '../lib/analytics.js';
import { toCents } from '../lib/money.js';
import { todayISO, monthKey } from '../lib/dates.js';
import { progressMeter } from '../charts.js';
import { card, field, money, formatDate, toast } from './common.js';

export function renderGoals() {
  const container = el('div');
  const listSlot = el('div');
  const formSlot = el('div');

  const redraw = () => {
    mount(listSlot, store.data.goals.length === 0
      ? card(null, [el('p', { class: 'empty', text: 'No goal yet. Set one below and every import updates your progress.' })])
      : el('div', { class: 'grid grid-two' }, store.data.goals.map((goal) => goalCard(goal, redraw))));
    mount(formSlot, goalForm(redraw));
  };

  mount(container, [
    el('div', { class: 'page-head' }, [
      el('div', {}, [
        el('h1', { text: 'Goals' }),
        el('p', { class: 'page-subtitle', text: 'Progress is measured from what you actually keep — money in minus money out since the goal started.' }),
      ]),
    ]),
    listSlot,
    el('div', { style: 'height:16px' }),
    formSlot,
  ]);

  redraw();
  return container;
}

function goalCard(goal, redraw) {
  const progress = goalProgress(goal, store.data.transactions, options());
  const percent = (progress.progress * 100).toFixed(0);

  let verdict;
  if (progress.remainingCents === 0) {
    verdict = el('span', { class: 'pill pill-good', text: 'Reached 🎉' });
  } else if (progress.onTrack === true) {
    verdict = el('span', { class: 'pill pill-good', text: 'On track' });
  } else if (progress.onTrack === false) {
    verdict = el('span', { class: 'pill pill-bad', text: 'Behind pace' });
  } else {
    verdict = el('span', { class: 'pill', text: 'No deadline set' });
  }

  return card(goal.name, [
    el('div', { style: 'display:flex; align-items:baseline; gap:10px; flex-wrap:wrap' }, [
      el('span', { class: 'stat-value is-net', text: money(progress.savedCents) }),
      el('span', { class: 'stat-foot', text: `of ${money(progress.targetCents)} · ${percent}%` }),
    ]),
    el('div', { style: 'height:10px' }),
    progressMeter(progress.progress, { label: `${goal.name} progress` }),
    el('div', { style: 'height:14px' }),
    el('table', {}, [el('tbody', {}, [
      row('Still to go', money(progress.remainingCents)),
      row('You keep, per month', money(progress.monthlyNetCents)),
      goal.targetDate ? row('Needed per month', money(progress.requiredMonthlyCents || 0)) : null,
      goal.targetDate ? row('Deadline', formatDate(goal.targetDate)) : null,
      row('At this pace', progress.projectedDate && progress.remainingCents > 0
        ? `${formatDate(progress.projectedDate)} (${progress.monthsNeeded} months)`
        : progress.remainingCents === 0 ? 'Done' : 'Not saving anything yet'),
      row('Counting from', formatDate(goal.startDate)),
    ].filter(Boolean))]),
    el('div', { class: 'btn-row', style: 'margin-top:14px' }, [
      verdict,
      el('span', { style: 'flex:1' }),
      el('button', {
        class: 'btn-small btn-danger',
        text: 'Delete',
        onclick: () => {
          if (window.confirm(`Delete the goal "${goal.name}"?`)) {
            deleteGoal(goal.id);
            redraw();
          }
        },
      }),
    ]),
  ]);
}

function row(labelText, value) {
  return el('tr', {}, [
    el('td', { class: 'stat-foot', text: labelText }),
    el('td', { class: 'num', text: value }),
  ]);
}

function goalForm(redraw) {
  const name = el('input', { placeholder: 'e.g. Emergency fund, deposit, trip' });
  const target = el('input', { type: 'number', step: '0.01', min: '0', placeholder: '10000' });
  const startAmount = el('input', { type: 'number', step: '0.01', min: '0', placeholder: '0' });
  const startDate = el('input', { type: 'date', value: `${monthKey(todayISO())}-01` });
  const targetDate = el('input', { type: 'date' });

  return card('Add a goal', [
    el('form', {
      onsubmit: (event) => {
        event.preventDefault();
        const amount = Number.parseFloat(target.value);
        if (!name.value.trim() || !Number.isFinite(amount) || amount <= 0) {
          toast('Give the goal a name and a target amount.', 'bad');
          return;
        }
        saveGoal({
          name: name.value.trim(),
          targetCents: toCents(amount),
          startCents: toCents(Number.parseFloat(startAmount.value) || 0),
          startDate: startDate.value || todayISO(),
          targetDate: targetDate.value || null,
        });
        name.value = '';
        target.value = '';
        startAmount.value = '';
        targetDate.value = '';
        toast('Goal saved.');
        redraw();
      },
    }, [
      el('div', { class: 'field-row' }, [
        field('Goal', name),
        field(`Target amount (${store.data.settings.currency})`, target),
        field('Already saved', startAmount),
      ]),
      el('div', { class: 'field-row' }, [
        field('Count savings from', startDate),
        field('Target date (optional)', targetDate),
      ]),
      el('div', { style: 'height:14px' }),
      el('button', { class: 'btn-primary', type: 'submit', text: 'Save goal' }),
    ]),
  ]);
}
