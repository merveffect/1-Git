/** Categorisation rules: the user's own on top of the built-in keyword list. */

import { el, mount } from '../dom.js';
import { store, options, addRule, updateRule, deleteRule, recategorizeAll } from '../state.js';
import { byCategory } from '../lib/analytics.js';
import { card, field, money, toast, categorySelect } from './common.js';

export function renderRules(navigate) {
  const container = el('div');
  const slot = el('div');
  const redraw = () => mount(slot, [rulesCard(redraw), el('div', { style: 'height:16px' }), uncategorisedCard(navigate)]);

  mount(container, [
    el('div', { class: 'page-head' }, [
      el('div', {}, [
        el('h1', { text: 'Categories & rules' }),
        el('p', { class: 'page-subtitle', text: 'Your rules run first, then a built-in list of a few hundred common merchants.' }),
      ]),
      el('div', { class: 'btn-row' }, [
        el('button', {
          class: 'btn-small',
          text: 'Re-apply rules',
          onclick: () => { recategorizeAll(); toast('Rules re-applied.'); redraw(); },
        }),
        el('button', {
          class: 'btn-small btn-danger',
          text: 'Re-apply, overwriting manual edits',
          onclick: () => {
            if (window.confirm('This clears the categories you set by hand and re-runs every rule. Continue?')) {
              recategorizeAll({ includeManual: true });
              toast('Everything re-categorised.');
              redraw();
            }
          },
        }),
      ]),
    ]),
    newRuleCard(redraw),
    el('div', { style: 'height:16px' }),
    slot,
  ]);

  redraw();
  return container;
}

function newRuleCard(redraw) {
  let category = store.data.categories[0]?.name || 'Uncategorised';
  const value = el('input', { placeholder: 'e.g. migros, uber, landlord' });
  const type = el('select', {}, [
    el('option', { value: 'contains', text: 'contains' }),
    el('option', { value: 'startsWith', text: 'starts with' }),
    el('option', { value: 'equals', text: 'is exactly' }),
    el('option', { value: 'regex', text: 'matches regex' }),
  ]);
  const direction = el('select', {}, [
    el('option', { value: 'any', text: 'in or out' }),
    el('option', { value: 'out', text: 'money out only' }),
    el('option', { value: 'in', text: 'money in only' }),
  ]);
  const picker = categorySelect(category, (next) => { category = next; });

  return card('Add a rule', [
    el('form', {
      onsubmit: (event) => {
        event.preventDefault();
        if (!value.value.trim()) {
          toast('Type the text to look for.', 'bad');
          return;
        }
        addRule({
          id: `rule_${Date.now().toString(36)}`,
          field: 'description',
          type: type.value,
          value: value.value.trim(),
          direction: direction.value === 'any' ? undefined : direction.value,
          category,
        });
        value.value = '';
        toast('Rule added and applied to everything already imported.');
        redraw();
      },
    }, [
      el('div', { class: 'field-row' }, [
        field('When the description', type),
        field('this text', value),
        field('and it is', direction),
        field('put it in', picker),
      ]),
      el('div', { style: 'height:14px' }),
      el('button', { class: 'btn-primary', type: 'submit', text: 'Add rule' }),
    ]),
  ]);
}

function rulesCard(redraw) {
  const rules = store.data.rules;
  return card(`Your rules (${rules.length})`, [
    rules.length === 0
      ? el('p', { class: 'empty', text: 'No rules of your own yet. Use “Remember” on a transaction, or add one above.' })
      : el('div', { class: 'table-wrap' }, [
        el('table', {}, [
          el('thead', {}, [el('tr', {}, [
            el('th', { text: 'Match' }), el('th', { text: 'Text' }), el('th', { text: 'Category' }),
            el('th', { text: 'Active' }), el('th', {}),
          ])]),
          el('tbody', {}, rules.map((rule) => el('tr', {}, [
            el('td', { text: `${rule.field === 'merchant' ? 'merchant' : 'description'} ${rule.type}` }),
            el('td', { text: rule.value }),
            el('td', {}, [categorySelect(rule.category, (value) => {
              updateRule(rule.id, { category: value });
              redraw();
            })]),
            el('td', {}, [el('input', {
              type: 'checkbox',
              checked: rule.enabled !== false,
              style: 'width:auto',
              onchange: (event) => { updateRule(rule.id, { enabled: event.target.checked }); redraw(); },
            })]),
            el('td', { class: 'num' }, [el('button', {
              class: 'btn-small btn-danger',
              text: 'Delete',
              onclick: () => { deleteRule(rule.id); redraw(); },
            })]),
          ]))),
        ]),
      ]),
  ]);
}

/** What still has no home - the fastest way to improve the numbers. */
function uncategorisedCard(navigate) {
  const opts = options();
  const uncategorised = store.data.transactions.filter((tx) => tx.category === 'Uncategorised' && !tx.excluded);
  const groups = new Map();
  for (const tx of uncategorised) {
    const key = tx.merchantKey || tx.description;
    const group = groups.get(key) || { label: tx.merchantLabel || tx.description, cents: 0, count: 0 };
    group.cents += Math.abs(tx.amountCents);
    group.count += 1;
    groups.set(key, group);
  }
  const ranked = [...groups.values()].sort((a, b) => b.cents - a.cents).slice(0, 12);
  const totalUncategorised = byCategory(store.data.transactions, 'out', opts)
    .find((c) => c.category === 'Uncategorised');

  return card('Still uncategorised', [
    uncategorised.length === 0
      ? el('p', { class: 'empty', text: 'Everything has a category. Nice.' })
      : el('div', {}, [
        el('p', {
          class: 'stat-foot',
          style: 'margin-bottom:12px',
          text: `${uncategorised.length} transactions worth ${money(totalUncategorised?.cents || 0)} have no category yet. Sorting the biggest ones makes the charts much more useful.`,
        }),
        el('div', { class: 'table-wrap' }, [
          el('table', {}, [
            el('thead', {}, [el('tr', {}, [
              el('th', { text: 'Merchant' }), el('th', { class: 'num', text: 'Times' }),
              el('th', { class: 'num', text: 'Total' }), el('th', {}),
            ])]),
            el('tbody', {}, ranked.map((group) => el('tr', {}, [
              el('td', { text: group.label }),
              el('td', { class: 'num', text: String(group.count) }),
              el('td', { class: 'num', text: money(group.cents) }),
              el('td', { class: 'num' }, [el('button', {
                class: 'btn-small',
                text: 'Sort these',
                onclick: () => navigate('transactions', { search: group.label, category: 'Uncategorised' }),
              })]),
            ]))),
          ]),
        ]),
      ]),
  ]);
}
