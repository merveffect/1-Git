/** Reader for OFX / QFX statement files (SGML 1.x and XML 2.x variants). */

import { parseAmount } from './money.js';
import { parseDate } from './dates.js';

function tagValue(block, tag) {
  const match = block.match(new RegExp(`<${tag}>([^<\\r\\n]*)`, 'i'));
  return match ? match[1].trim() : '';
}

function parseOFXDate(value) {
  const digits = String(value).replace(/[^\d]/g, '');
  if (digits.length >= 8) return parseDate(digits.slice(0, 8));
  return null;
}

export function looksLikeOFX(text) {
  return /<(OFX|STMTTRN)\b/i.test(text) || /^OFXHEADER/im.test(text);
}

/** @returns {{rows:Array, skipped:Array, currency:string|null}} */
export function parseOFX(text) {
  const rows = [];
  const skipped = [];
  const currency = tagValue(text, 'CURDEF') || null;
  const blocks = text.match(/<STMTTRN>[\s\S]*?<\/STMTTRN>/gi) || [];

  for (const block of blocks) {
    const date = parseOFXDate(tagValue(block, 'DTPOSTED') || tagValue(block, 'DTUSER'));
    const amount = parseAmount(tagValue(block, 'TRNAMT'));
    if (!date || amount === null) {
      skipped.push({ row: [block.slice(0, 120)], reason: 'incomplete OFX record' });
      continue;
    }
    const name = tagValue(block, 'NAME');
    const memo = tagValue(block, 'MEMO');
    const unique = [...new Set([name, memo].filter(Boolean))];
    rows.push({
      date,
      amount,
      description: unique.join(' · ') || '(no description)',
      currency,
      type: tagValue(block, 'TRNTYPE') || null,
    });
  }
  return { rows, skipped, currency };
}
