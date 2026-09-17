'use strict';

const WEEKDAYS = ['Pzt', 'Sal', 'Çar', 'Per', 'Cum', 'Cmt', 'Paz'];
const MONTHS = ['Oca', 'Şub', 'Mar', 'Nis', 'May', 'Haz', 'Tem', 'Ağu', 'Eyl', 'Eki', 'Kas', 'Ara'];

const COMPLAINTS = [
  'Diş ağrısı', 'Boğaz ağrısı', 'Cilt sorunu', 'Göz muayenesi',
  'Genel muayene', 'Kadın doğum', 'Çocuk doktoru', 'Psikolog',
  'Fizyoterapi', 'Ortopedi', 'Alerji', 'Kalp kontrolü',
];
const TIMES = [
  { label: 'Sabah', text: 'sabah' },
  { label: 'Öğleden sonra', text: 'öğleden sonra' },
  { label: 'Akşam', text: 'akşam' },
];

const $ = (id) => document.getElementById(id);
const state = { days: new Set(), times: new Set(), jobId: null, timer: null, config: null };

/* ---------- token ---------- */

function getToken() {
  try { return localStorage.getItem('doctolib_token') || ''; } catch { return ''; }
}
function setToken(v) {
  try { localStorage.setItem('doctolib_token', v); } catch { /* özel sekme */ }
}

async function api(path, options = {}) {
  const headers = Object.assign({ 'Content-Type': 'application/json' }, options.headers || {});
  const token = getToken();
  if (token) headers['X-Token'] = token;
  const res = await fetch(path, Object.assign({}, options, { headers }));
  if (res.status === 401 || res.status === 403) {
    $('authCard').classList.remove('hidden');
    throw new Error('auth');
  }
  return res;
}

/* ---------- chip'ler ---------- */

function makeChip(label, onToggle) {
  const b = document.createElement('button');
  b.type = 'button';
  b.className = 'chip';
  b.textContent = label;
  b.setAttribute('aria-pressed', 'false');
  b.addEventListener('click', () => {
    const on = b.getAttribute('aria-pressed') === 'true';
    b.setAttribute('aria-pressed', String(!on));
    onToggle(!on);
    updatePreview();
  });
  return b;
}

function buildChips() {
  const cc = $('complaintChips');
  COMPLAINTS.forEach((c) => {
    const b = document.createElement('button');
    b.type = 'button';
    b.className = 'chip';
    b.textContent = c;
    b.addEventListener('click', () => {
      const box = $('complaint');
      box.value = box.value.trim() ? `${box.value.trim()}, ${c.toLowerCase()}` : c;
      box.focus();
      updatePreview();
    });
    cc.appendChild(b);
  });

  WEEKDAYS.forEach((d, i) => {
    $('dayChips').appendChild(makeChip(d, (on) => {
      if (on) state.days.add(i); else state.days.delete(i);
    }));
  });

  TIMES.forEach((t) => {
    $('timeChips').appendChild(makeChip(t.label, (on) => {
      if (on) state.times.add(t.text); else state.times.delete(t.text);
    }));
  });
}

const DAY_NAMES = ['pazartesi', 'salı', 'çarşamba', 'perşembe', 'cuma', 'cumartesi', 'pazar'];

/** Chip seçimlerini, Claude'un çözümleyeceği tek bir cümleye ekler. */
function composeText() {
  const parts = [$('complaint').value.trim()];
  const days = [...state.days].sort().map((i) => DAY_NAMES[i]);
  const times = [...state.times];
  if (days.length || times.length) {
    const when = [days.join(', '), times.join(' veya ')].filter(Boolean).join(' ');
    parts.push(`${when} müsaitim`);
  }
  return parts.filter(Boolean).join('. ');
}

function updatePreview() {
  const text = composeText();
  $('previewLine').textContent = text ? `Aranacak: "${text}"` : '';
}

/* ---------- arama ---------- */

async function startSearch() {
  const text = composeText();
  if (text.length < 3) {
    $('complaint').focus();
    return;
  }
  $('searchBtn').disabled = true;
  $('resultsCard').classList.add('hidden');
  $('statusCard').classList.remove('hidden');
  $('spinner').classList.remove('done');
  $('statusText').textContent = 'İstek çözümleniyor…';
  $('logBox').textContent = '';
  $('intentBox').classList.add('hidden');
  $('alertBox').classList.add('hidden');

  try {
    const res = await api('/api/search', { method: 'POST', body: JSON.stringify({ text }) });
    if (!res.ok) throw new Error(`Sunucu hatası (${res.status})`);
    const data = await res.json();
    state.jobId = data.job_id;
    poll();
  } catch (err) {
    $('searchBtn').disabled = false;
    if (err.message !== 'auth') showError(err.message);
  }
}

function poll() {
  clearTimeout(state.timer);
  state.timer = setTimeout(async () => {
    try {
      const res = await api(`/api/jobs/${state.jobId}`);
      if (!res.ok) throw new Error(`İş okunamadı (${res.status})`);
      const job = await res.json();
      render(job);
      if (job.status === 'queued' || job.status === 'running') poll();
      else finish();
    } catch (err) {
      finish();
      if (err.message !== 'auth') showError(err.message);
    }
  }, 1500);
}

function finish() {
  $('searchBtn').disabled = false;
  $('spinner').classList.add('done');
  loadHistory();
}

function showError(message) {
  $('statusCard').classList.remove('hidden');
  $('statusText').textContent = 'Hata';
  $('alertBox').textContent = message;
  $('alertBox').classList.remove('hidden');
}

/* ---------- görüntüleme ---------- */

function render(job) {
  const labels = { queued: 'Sırada…', running: 'Aranıyor…', done: 'Tamamlandı', error: 'Hata' };
  $('statusText').textContent = labels[job.status] || job.status;
  $('logBox').textContent = (job.log || []).join('\n');

  if (job.intent) {
    const i = job.intent;
    $('intentBox').innerHTML = '';
    const rows = [
      ['Şikayet', i.reason_summary],
      ['Uzmanlık', i.specialty_label],
      ['Konum', i.location_label],
      ['Müsaitlik', i.windows],
    ];
    rows.forEach(([k, v]) => {
      if (!v) return;
      const div = document.createElement('div');
      const b = document.createElement('b');
      b.textContent = `${k}: `;
      div.appendChild(b);
      div.appendChild(document.createTextNode(v));
      $('intentBox').appendChild(div);
    });
    $('intentBox').classList.remove('hidden');

    if (i.red_flags && i.red_flags.length) {
      $('alertBox').textContent =
        '⚠ Mesajında acil değerlendirme gerektirebilecek işaretler var: ' +
        i.red_flags.join('; ') + '. Randevu beklemek yerine 112\'yi ara.';
      $('alertBox').classList.remove('hidden');
    }
  }

  if (job.status === 'error') showError(job.error || 'Bilinmeyen hata');
  if (job.status === 'done') renderSlots(job);
}

function renderSlots(job) {
  const wrap = $('results');
  wrap.innerHTML = '';
  $('resultsCard').classList.remove('hidden');

  if (!job.slots.length) {
    $('resultsTitle').textContent = 'Uygun randevu bulunamadı';
    const p = document.createElement('p');
    p.className = 'muted tiny';
    p.textContent = 'Müsaitlik filtreni genişletmeyi veya başka bir uzmanlık denemeyi düşünebilirsin.';
    wrap.appendChild(p);
    return;
  }

  $('resultsTitle').textContent = `${job.slots.length} uygun randevu`;
  job.slots.slice(0, 30).forEach((s) => wrap.appendChild(slotCard(job.id, s)));
}

function slotCard(jobId, s) {
  const d = new Date(s.start);
  const el = document.createElement('article');
  el.className = 'slot';

  const when = document.createElement('div');
  when.className = 'when';
  when.innerHTML =
    `<div class="d">${d.getDate()}</div>` +
    `<div class="m">${MONTHS[d.getMonth()]}</div>` +
    `<div class="w">${WEEKDAYS[s.weekday]}</div>` +
    `<div class="t">${s.time}</div>`;

  const body = document.createElement('div');
  const who = document.createElement('div');
  who.className = 'who';
  who.textContent = s.practitioner;
  body.appendChild(who);

  [s.speciality, s.address, s.motive].filter(Boolean).forEach((line) => {
    const m = document.createElement('div');
    m.className = 'meta';
    m.textContent = line;
    body.appendChild(m);
  });

  const actions = document.createElement('div');
  actions.className = 'actions';

  const link = document.createElement('a');
  link.href = s.link;
  link.target = '_blank';
  link.rel = 'noopener';
  link.textContent = 'Doctolib\'de aç';
  actions.appendChild(link);

  if (state.config && state.config.server_booking) {
    const btn = document.createElement('button');
    btn.type = 'button';
    btn.textContent = 'Sunucuda al';
    btn.addEventListener('click', () => bookSlot(jobId, s.key, btn));
    actions.appendChild(btn);
  }

  body.appendChild(actions);
  el.appendChild(when);
  el.appendChild(body);
  return el;
}

async function bookSlot(jobId, slotKey, btn) {
  btn.disabled = true;
  btn.textContent = 'Alınıyor…';
  try {
    const res = await api(`/api/jobs/${jobId}/book`, {
      method: 'POST',
      body: JSON.stringify({ slot_key: slotKey }),
    });
    const data = await res.json();
    btn.textContent = data.ok ? '✓ Alındı' : 'Olmadı';
    btn.disabled = data.ok;
    if (!data.ok) showError(data.message);
  } catch (err) {
    btn.disabled = false;
    btn.textContent = 'Sunucuda al';
    if (err.message !== 'auth') showError(err.message);
  }
}

/* ---------- geçmiş ---------- */

async function loadHistory() {
  try {
    const res = await api('/api/jobs');
    if (!res.ok) return;
    const data = await res.json();
    const list = (data.jobs || []).filter((j) => j.id !== state.jobId);
    if (!list.length) return;
    const wrap = $('history');
    wrap.innerHTML = '';
    list.slice(0, 8).forEach((j) => {
      const row = document.createElement('div');
      row.className = 'history-item';
      row.innerHTML = `<span class="t"></span><span class="n">${j.slot_count} sonuç</span>`;
      row.querySelector('.t').textContent = j.text;
      row.addEventListener('click', async () => {
        state.jobId = j.id;
        const r = await api(`/api/jobs/${j.id}`);
        if (r.ok) {
          $('statusCard').classList.remove('hidden');
          render(await r.json());
          window.scrollTo({ top: 0, behavior: 'smooth' });
        }
      });
      wrap.appendChild(row);
    });
    $('historyCard').classList.remove('hidden');
  } catch { /* geçmiş kritik değil */ }
}

/* ---------- başlangıç ---------- */

async function init() {
  buildChips();
  $('searchBtn').addEventListener('click', startSearch);
  $('complaint').addEventListener('input', updatePreview);
  $('tokenSave').addEventListener('click', () => {
    setToken($('tokenInput').value.trim());
    $('authCard').classList.add('hidden');
    init();
  });

  try {
    const res = await api('/api/config');
    if (res.ok) {
      state.config = await res.json();
      $('locationPill').textContent = state.config.location_label;
      $('authCard').classList.add('hidden');
      loadHistory();
    }
  } catch { /* auth kartı zaten gösterildi */ }
}

init();

if ('serviceWorker' in navigator) {
  navigator.serviceWorker.register('/static/sw.js').catch(() => {});
}
