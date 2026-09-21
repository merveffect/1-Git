/**
 * Rule-based categorisation.
 *
 * Matching order: the user's own rules (top to bottom), then the built-in
 * keyword rules, then a fallback based on the direction of the money.
 * A manual choice on a single transaction always wins and is never overwritten
 * by a re-run.
 */

import { normalizeMerchant } from './text.js';

/** kind drives the analytics: transfers are movements, not income or spending. */
export const DEFAULT_CATEGORIES = [
  { name: 'Salary', kind: 'income' },
  { name: 'Other income', kind: 'income' },
  { name: 'Refunds', kind: 'income' },
  { name: 'Housing & rent', kind: 'expense' },
  { name: 'Utilities', kind: 'expense' },
  { name: 'Internet & phone', kind: 'expense' },
  { name: 'Groceries', kind: 'expense' },
  { name: 'Eating out', kind: 'expense' },
  { name: 'Transport', kind: 'expense' },
  { name: 'Fuel & car', kind: 'expense' },
  { name: 'Travel', kind: 'expense' },
  { name: 'Shopping', kind: 'expense' },
  { name: 'Subscriptions', kind: 'expense' },
  { name: 'Entertainment', kind: 'expense' },
  { name: 'Health', kind: 'expense' },
  { name: 'Sport & fitness', kind: 'expense' },
  { name: 'Education', kind: 'expense' },
  { name: 'Kids', kind: 'expense' },
  { name: 'Pets', kind: 'expense' },
  { name: 'Insurance', kind: 'expense' },
  { name: 'Taxes', kind: 'expense' },
  { name: 'Fees & interest', kind: 'expense' },
  { name: 'Cash', kind: 'expense' },
  { name: 'Gifts & donations', kind: 'expense' },
  { name: 'Transfers', kind: 'transfer' },
  { name: 'Savings & investments', kind: 'transfer' },
  { name: 'Uncategorised', kind: 'expense' },
];

export const CATEGORY_NAMES = DEFAULT_CATEGORIES.map((c) => c.name);

/** Built-in keyword rules. Keywords are matched case-insensitively. */
const BUILTIN = [
  ['Salary', ['salary', 'payroll', 'wages', 'maas', 'maaş', 'gehalt', 'salaire', 'employer', 'bordro']],
  ['Refunds', ['refund', 'reimbursement', 'iade', 'chargeback', 'rückerstattung']],
  ['Housing & rent', ['rent', 'landlord', 'mortgage', 'kira', 'miete', 'loyer', 'hoa', 'aidat', 'property management']],
  ['Utilities', ['electric', 'energy', 'gas bill', 'water', 'utility', 'elektrik', 'dogalgaz', 'doğalgaz', 'su fatura', 'stadtwerke', 'edf', 'engie', 'enerji']],
  ['Internet & phone', ['vodafone', 'turkcell', 'turk telekom', 'türk telekom', 'o2', 'three', 'ee ', 'orange', 'telekom', 'internet', 'broadband', 'mobile', 'sfr', 'bouygues', 'giffgaff', 'lyca']],
  ['Groceries', ['supermarket', 'grocery', 'migros', 'bim', 'a101', 'sok market', 'şok', 'carrefour', 'tesco', 'sainsbury', 'aldi', 'lidl', 'asda', 'waitrose', 'rewe', 'edeka', 'kaufland', 'auchan', 'leclerc', 'monoprix', 'whole foods', 'trader joe', 'kroger', 'walmart', 'market']],
  ['Eating out', ['restaurant', 'cafe', 'café', 'coffee', 'starbucks', 'costa', 'pret', 'mcdonald', 'burger', 'kfc', 'pizza', 'domino', 'subway', 'kebab', 'sushi', 'bistro', 'bakery', 'firin', 'fırın', 'kahve', 'lokanta', 'deliveroo', 'ubereats', 'uber eats', 'just eat', 'yemeksepeti', 'getir yemek', 'glovo', 'wolt', 'doordash', 'grubhub']],
  ['Transport', ['uber', 'bolt', 'lyft', 'taxi', 'metro', 'transport', 'tfl', 'oyster', 'railway', 'trainline', 'sncf', 'db bahn', 'deutsche bahn', 'istanbulkart', 'bitaksi', 'bus ', 'tram', 'ferry', 'blablacar', 'citymapper']],
  ['Fuel & car', ['shell', 'bp ', 'esso', 'total energies', 'totalenergies', 'petrol', 'opet', 'aytemiz', 'gasoline', 'fuel', 'parking', 'otopark', 'car wash', 'garage', 'mot ', 'tyre', 'lastik', 'autoroute', 'toll', 'hgs', 'ogs']],
  ['Travel', ['airline', 'airways', 'ryanair', 'easyjet', 'lufthansa', 'turkish airlines', 'thy', 'pegasus', 'wizz', 'booking.com', 'airbnb', 'hotel', 'hostel', 'expedia', 'trivago', 'skyscanner', 'flight', 'otel']],
  ['Shopping', ['amazon', 'ebay', 'etsy', 'zara', 'h&m', 'hm ', 'uniqlo', 'nike', 'adidas', 'decathlon', 'ikea', 'mediamarkt', 'currys', 'argos', 'trendyol', 'hepsiburada', 'n11', 'aliexpress', 'temu', 'shein', 'asos', 'zalando', 'apple store', 'lc waikiki', 'defacto', 'bershka', 'mango']],
  ['Subscriptions', ['netflix', 'spotify', 'disney', 'hbo', 'hulu', 'youtube premium', 'apple.com/bill', 'icloud', 'google storage', 'google one', 'dropbox', 'adobe', 'microsoft 365', 'office 365', 'patreon', 'substack', 'medium', 'chatgpt', 'openai', 'anthropic', 'claude.ai', 'notion', 'canva', 'prime video', 'blinkist', 'audible', 'duolingo', 'subscription', 'abonelik', 'abonnement']],
  ['Entertainment', ['cinema', 'sinema', 'theatre', 'theater', 'concert', 'ticketmaster', 'biletix', 'steam', 'playstation', 'xbox', 'nintendo', 'twitch', 'bar ', 'pub ', 'club ', 'bowling', 'museum', 'muze', 'müze']],
  ['Health', ['pharmacy', 'eczane', 'apotheke', 'boots', 'chemist', 'doctor', 'dentist', 'dis hekim', 'diş hekim', 'hospital', 'hastane', 'clinic', 'klinik', 'optician', 'laboratuvar', 'medical', 'saglik', 'sağlık', 'doctolib']],
  ['Sport & fitness', ['gym', 'fitness', 'macfit', 'basic fit', 'basic-fit', 'puregym', 'yoga', 'pilates', 'swim', 'spor', 'strava', 'classpass', 'sportsdirect']],
  ['Education', ['university', 'universite', 'üniversite', 'school', 'okul', 'tuition', 'course', 'udemy', 'coursera', 'kurs', 'kitap', 'books', 'waterstones', 'library']],
  ['Kids', ['nursery', 'kindergarten', 'kres', 'kreş', 'daycare', 'toys', 'oyuncak', 'babyshop', 'child']],
  ['Pets', ['vet', 'veteriner', 'petshop', 'pet shop', 'zooplus', 'mama ', 'kedi', 'kopek', 'köpek']],
  ['Insurance', ['insurance', 'sigorta', 'assurance', 'versicherung', 'allianz', 'axa', 'aviva', 'zurich', 'anadolu sigorta']],
  ['Taxes', ['tax', 'vergi', 'hmrc', 'finanzamt', 'impots', 'impôts', 'irs ', 'council tax', 'stamp duty', 'sgk']],
  ['Fees & interest', ['fee', 'charge', 'commission', 'komisyon', 'masraf', 'interest', 'faiz', 'overdraft', 'bsmv', 'kkdf', 'service charge', 'atm fee', 'exchange fee']],
  ['Cash', ['atm', 'cash withdrawal', 'nakit', 'bankomat', 'cash point', 'withdrawal']],
  ['Gifts & donations', ['donation', 'bagis', 'bağış', 'charity', 'gofundme', 'unicef', 'ahbap', 'kizilay', 'kızılay', 'gift']],
  ['Savings & investments', ['savings', 'birikim', 'vadeli', 'investment', 'yatirim', 'yatırım', 'trading212', 'trade republic', 'degiro', 'etoro', 'coinbase', 'binance', 'revolut vault', 'pension', 'bes ', 'isa ']],
  ['Transfers', ['transfer', 'havale', 'eft ', 'fast ', 'sepa', 'own account', 'kendi hesab', 'internal', 'virement', 'überweisung', 'zelle', 'venmo', 'paypal transfer', 'wise', 'revolut']],
];

export const BUILTIN_RULES = BUILTIN.flatMap(([category, keywords]) =>
  keywords.map((keyword) => ({
    id: `builtin:${category}:${keyword}`,
    builtin: true,
    field: 'description',
    type: 'contains',
    value: keyword,
    category,
  })));

export function categoryKind(name, categories = DEFAULT_CATEGORIES) {
  return categories.find((c) => c.name === name)?.kind || 'expense';
}

function fieldValue(tx, field) {
  if (field === 'merchant') return tx.merchantKey || normalizeMerchant(tx.description || '');
  return tx.description || '';
}

/** Does a single rule match a transaction? */
export function ruleMatches(rule, tx) {
  if (rule.direction === 'in' && tx.amountCents <= 0) return false;
  if (rule.direction === 'out' && tx.amountCents >= 0) return false;
  if (rule.minCents !== undefined && rule.minCents !== null
    && Math.abs(tx.amountCents) < rule.minCents) return false;
  if (rule.maxCents !== undefined && rule.maxCents !== null
    && Math.abs(tx.amountCents) > rule.maxCents) return false;

  const haystack = fieldValue(tx, rule.field || 'description').toLowerCase();
  const needle = String(rule.value ?? '').toLowerCase().trim();
  if (needle === '') return false;

  switch (rule.type) {
    case 'equals':
      return haystack === needle;
    case 'startsWith':
      return haystack.startsWith(needle);
    case 'regex':
      try {
        return new RegExp(rule.value, 'i').test(fieldValue(tx, rule.field || 'description'));
      } catch {
        return false;
      }
    case 'contains':
    default:
      return haystack.includes(needle);
  }
}

/**
 * @returns {{category:string, source:'rule'|'builtin'|'fallback', ruleId:string|null}}
 */
export function categorizeOne(tx, userRules = [], { useBuiltins = true } = {}) {
  for (const rule of userRules) {
    if (rule.enabled === false) continue;
    if (ruleMatches(rule, tx)) return { category: rule.category, source: 'rule', ruleId: rule.id };
  }
  if (useBuiltins) {
    // Longer keywords are more specific, so try them first.
    for (const rule of BUILTIN_RULES_SORTED) {
      if (ruleMatches(rule, tx)) return { category: rule.category, source: 'builtin', ruleId: rule.id };
    }
  }
  return {
    category: tx.amountCents > 0 ? 'Other income' : 'Uncategorised',
    source: 'fallback',
    ruleId: null,
  };
}

const BUILTIN_RULES_SORTED = [...BUILTIN_RULES].sort((a, b) => b.value.length - a.value.length);

/**
 * Apply rules to a list of transactions, leaving manual choices untouched.
 * Mutates nothing: returns new objects.
 */
export function applyRules(transactions, userRules = [], options = {}) {
  return transactions.map((tx) => {
    if (tx.categorySource === 'manual') return tx;
    const result = categorizeOne(tx, userRules, options);
    if (tx.category === result.category && tx.categorySource === result.source) return tx;
    return { ...tx, category: result.category, categorySource: result.source, ruleId: result.ruleId };
  });
}

/** Build a user rule from a manual correction ("always call this X"). */
export function ruleFromTransaction(tx, category) {
  return {
    id: `rule_${Date.now().toString(36)}_${Math.random().toString(36).slice(2, 8)}`,
    field: 'merchant',
    type: 'equals',
    value: tx.merchantKey || normalizeMerchant(tx.description || ''),
    category,
    enabled: true,
    createdAt: new Date().toISOString(),
  };
}
