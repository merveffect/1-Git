/**
 * Hand-rolled SVG charts.
 *
 * Colours come from CSS custom properties (see styles.css) so light and dark
 * are two selected palettes rather than an automatic flip. The three series
 * hues are the validated categorical slots 1-3.
 */

import { svg, el } from './dom.js';
import { formatMoney, formatCompact } from './lib/money.js';

const PAD = { top: 16, right: 16, bottom: 28, left: 56 };
const BAR_GAP = 2; // surface gap between adjacent bars

let tooltip = null;

function ensureTooltip() {
  if (!tooltip) {
    tooltip = el('div', { class: 'chart-tooltip', role: 'status', 'aria-live': 'polite' });
    document.body.appendChild(tooltip);
  }
  return tooltip;
}

function showTooltip(event, html) {
  const node = ensureTooltip();
  node.innerHTML = html;
  node.classList.add('is-visible');
  const rect = node.getBoundingClientRect();
  const x = Math.min(window.innerWidth - rect.width - 8, Math.max(8, event.clientX + 12));
  const y = Math.max(8, event.clientY - rect.height - 12);
  node.style.transform = `translate(${x}px, ${y}px)`;
}

export function hideTooltip() {
  if (tooltip) tooltip.classList.remove('is-visible');
}

function niceTicks(max, count = 4) {
  if (max <= 0) return [0];
  const rough = max / count;
  const magnitude = 10 ** Math.floor(Math.log10(rough));
  const step = [1, 2, 2.5, 5, 10].map((m) => m * magnitude).find((s) => s >= rough) || magnitude * 10;
  const ticks = [];
  for (let value = 0; value <= max + step / 2; value += step) ticks.push(value);
  return ticks;
}

/** Bar with rounded top corners, anchored to the baseline. */
function barPath(x, y, width, height, radius = 4) {
  const r = Math.max(0, Math.min(radius, width / 2, height));
  if (height <= 0) return '';
  return `M${x},${y + height} L${x},${y + r} Q${x},${y} ${x + r},${y} L${x + width - r},${y} Q${x + width},${y} ${x + width},${y + r} L${x + width},${y + height} Z`;
}

function axisLayer(width, height, ticks, scale, currency, locale) {
  const parts = [];
  for (const tick of ticks) {
    const y = scale(tick);
    parts.push(svg('line', {
      class: 'grid-line', x1: PAD.left, x2: width - PAD.right, y1: y, y2: y,
    }));
    parts.push(svg('text', {
      class: 'axis-label', x: PAD.left - 8, y: y + 4, 'text-anchor': 'end',
    }, formatCompact(tick, currency, locale)));
  }
  parts.push(svg('line', {
    class: 'axis-line', x1: PAD.left, x2: width - PAD.right, y1: height - PAD.bottom, y2: height - PAD.bottom,
  }));
  return parts;
}

/**
 * Income vs spending per period, side by side.
 * @param {Array<{key,label,incomeCents,expenseCents,netCents}>} periods
 */
export function incomeExpenseChart(periods, { width = 720, height = 260, currency = 'EUR', locale, onSelect } = {}) {
  if (periods.length === 0) return emptyChart(width, height, 'No transactions yet');

  const max = Math.max(...periods.map((p) => Math.max(p.incomeCents, p.expenseCents)), 1);
  const ticks = niceTicks(max);
  const top = ticks[ticks.length - 1];
  const plotHeight = height - PAD.top - PAD.bottom;
  const scale = (value) => height - PAD.bottom - (value / top) * plotHeight;
  const plotWidth = width - PAD.left - PAD.right;
  const slot = plotWidth / periods.length;
  const barWidth = Math.max(3, Math.min(26, (slot - 10) / 2 - BAR_GAP / 2));

  const marks = [];
  const labels = [];
  const labelEvery = Math.ceil(periods.length / Math.max(2, Math.floor(plotWidth / 64)));

  periods.forEach((period, index) => {
    const centre = PAD.left + slot * index + slot / 2;
    const incomeX = centre - barWidth - BAR_GAP / 2;
    const expenseX = centre + BAR_GAP / 2;
    const incomeY = scale(period.incomeCents);
    const expenseY = scale(period.expenseCents);

    marks.push(svg('path', {
      class: 'mark mark-income',
      d: barPath(incomeX, incomeY, barWidth, height - PAD.bottom - incomeY),
    }));
    marks.push(svg('path', {
      class: 'mark mark-expense',
      d: barPath(expenseX, expenseY, barWidth, height - PAD.bottom - expenseY),
    }));

    // One generous hit target per period.
    marks.push(svg('rect', {
      class: 'hit-area',
      x: PAD.left + slot * index,
      y: PAD.top,
      width: slot,
      height: plotHeight,
      onmousemove: (event) => showTooltip(event, `
        <strong>${period.label}</strong>
        <span class="tt-row"><i class="swatch swatch-income"></i>In ${formatMoney(period.incomeCents, currency, locale)}</span>
        <span class="tt-row"><i class="swatch swatch-expense"></i>Out ${formatMoney(period.expenseCents, currency, locale)}</span>
        <span class="tt-row tt-net">Net ${formatMoney(period.netCents, currency, locale)}</span>`),
      onmouseleave: hideTooltip,
      onclick: () => onSelect?.(period),
    }));

    if (index % labelEvery === 0 || index === periods.length - 1) {
      labels.push(svg('text', {
        class: 'axis-label', x: centre, y: height - PAD.bottom + 16, 'text-anchor': 'middle',
      }, period.label));
    }
  });

  return svg('svg', {
    class: 'chart', viewBox: `0 0 ${width} ${height}`, width: '100%', height,
    role: 'img', 'aria-label': `Income and spending per period, ${periods.length} periods`,
  }, [...axisLayer(width, height, ticks, scale, currency, locale), ...marks, ...labels]);
}

/** Cumulative net cash flow. */
export function cumulativeChart(points, { width = 720, height = 200, currency = 'EUR', locale } = {}) {
  if (points.length < 2) return emptyChart(width, height, 'Not enough history yet');

  const values = points.map((p) => p.cumulativeCents);
  const min = Math.min(0, ...values);
  const max = Math.max(0, ...values);
  const span = max - min || 1;
  const plotHeight = height - PAD.top - PAD.bottom;
  const plotWidth = width - PAD.left - PAD.right;
  const scaleY = (value) => PAD.top + plotHeight - ((value - min) / span) * plotHeight;
  const scaleX = (index) => PAD.left + (plotWidth * index) / (points.length - 1);

  const line = points.map((p, i) => `${i === 0 ? 'M' : 'L'}${scaleX(i).toFixed(1)},${scaleY(p.cumulativeCents).toFixed(1)}`).join(' ');
  const area = `${line} L${scaleX(points.length - 1).toFixed(1)},${scaleY(Math.max(0, min))} L${scaleX(0).toFixed(1)},${scaleY(Math.max(0, min))} Z`;

  const ticks = niceTicks(max, 3);
  const marks = [
    svg('path', { class: 'area-net', d: area }),
    svg('path', { class: 'line-net', d: line }),
  ];

  if (min < 0) {
    marks.unshift(svg('line', {
      class: 'zero-line', x1: PAD.left, x2: width - PAD.right, y1: scaleY(0), y2: scaleY(0),
    }));
  }

  points.forEach((point, index) => {
    marks.push(svg('rect', {
      class: 'hit-area',
      x: scaleX(index) - plotWidth / points.length / 2,
      y: PAD.top,
      width: plotWidth / points.length,
      height: plotHeight,
      onmousemove: (event) => showTooltip(event, `
        <strong>${point.label || point.key}</strong>
        <span class="tt-row tt-net">Saved so far ${formatMoney(point.cumulativeCents, currency, locale)}</span>`),
      onmouseleave: hideTooltip,
    }));
  });

  const lastPoint = points[points.length - 1];
  marks.push(svg('circle', {
    class: 'point-net', cx: scaleX(points.length - 1), cy: scaleY(lastPoint.cumulativeCents), r: 4.5,
  }));

  return svg('svg', {
    class: 'chart', viewBox: `0 0 ${width} ${height}`, width: '100%', height,
    role: 'img', 'aria-label': 'Cumulative money kept over time',
  }, [
    ...axisLayer(width, height, ticks.filter((t) => t <= max), scaleY, currency, locale),
    ...marks,
    svg('text', { class: 'axis-label', x: PAD.left, y: height - 8 }, points[0].label || points[0].key),
    svg('text', { class: 'axis-label', x: width - PAD.right, y: height - 8, 'text-anchor': 'end' }, lastPoint.label || lastPoint.key),
  ]);
}

/**
 * Where the money goes: ranked horizontal bars in a single hue, each with its
 * own label and value, so nothing depends on colour alone.
 */
export function categoryBars(items, { currency = 'EUR', locale, limit = 10, onSelect } = {}) {
  if (items.length === 0) return el('p', { class: 'empty', text: 'Nothing to show for this period.' });
  const shown = items.slice(0, limit);
  const max = Math.max(...shown.map((item) => item.cents), 1);

  return el('ul', { class: 'bar-list' }, shown.map((item) => el('li', {
    class: 'bar-row',
    tabindex: '0',
    role: onSelect ? 'button' : null,
    onclick: () => onSelect?.(item),
    onkeydown: (event) => {
      if (event.key === 'Enter' || event.key === ' ') {
        event.preventDefault();
        onSelect?.(item);
      }
    },
  }, [
    el('span', { class: 'bar-label', text: item.category || item.label }),
    el('span', { class: 'bar-track' }, [
      el('span', {
        class: 'bar-fill',
        style: `width: ${Math.max(2, (item.cents / max) * 100)}%`,
      }),
    ]),
    el('span', { class: 'bar-value', text: formatMoney(item.cents, currency, locale) }),
    el('span', { class: 'bar-share', text: item.share !== undefined ? `${(item.share * 100).toFixed(0)}%` : `${item.count}×` }),
  ])));
}

/** Small inline trend line, no axes. */
export function sparkline(values, { width = 120, height = 32 } = {}) {
  if (values.length < 2) return svg('svg', { class: 'sparkline', width, height });
  const min = Math.min(...values);
  const max = Math.max(...values);
  const span = max - min || 1;
  const points = values.map((value, index) => {
    const x = (width * index) / (values.length - 1);
    const y = height - 3 - ((value - min) / span) * (height - 6);
    return `${index === 0 ? 'M' : 'L'}${x.toFixed(1)},${y.toFixed(1)}`;
  }).join(' ');
  return svg('svg', {
    class: 'sparkline', viewBox: `0 0 ${width} ${height}`, width, height, 'aria-hidden': 'true',
  }, [svg('path', { class: 'spark-line', d: points })]);
}

/** Goal progress meter. */
export function progressMeter(progress, { label = '' } = {}) {
  const percent = Math.max(0, Math.min(1, progress)) * 100;
  return el('div', {
    class: 'meter',
    role: 'progressbar',
    'aria-valuenow': percent.toFixed(0),
    'aria-valuemin': '0',
    'aria-valuemax': '100',
    'aria-label': label,
  }, [el('div', { class: 'meter-fill', style: `width: ${percent}%` })]);
}

function emptyChart(width, height, message) {
  return svg('svg', { class: 'chart', viewBox: `0 0 ${width} ${height}`, width: '100%', height }, [
    svg('text', {
      class: 'axis-label', x: width / 2, y: height / 2, 'text-anchor': 'middle',
    }, message),
  ]);
}

/** Legend - always present when two or more series share a chart. */
export function legend(entries) {
  return el('ul', { class: 'legend' }, entries.map((entry) => el('li', { class: 'legend-item' }, [
    el('i', { class: `swatch swatch-${entry.key}` }),
    el('span', { text: entry.label }),
  ])));
}
