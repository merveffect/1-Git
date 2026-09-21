/** First-run setup and the unlock screen. */

import { el, mount } from '../dom.js';
import { passphraseStrength } from '../crypto.js';
import { createNewVault, unlock, restoreEncryptedBackup, vaultExists } from '../state.js';
import { field } from './common.js';

const STRENGTH_WORDS = ['too short', 'weak', 'fair', 'good', 'strong'];

export async function renderLock(root, { onUnlocked }) {
  const exists = await vaultExists();
  mount(root, exists ? unlockView(onUnlocked) : setupView(onUnlocked));
}

function head(title, subtitle) {
  return el('div', { class: 'lock-head' }, [
    el('div', { class: 'brand-mark' }),
    el('h1', { text: title }),
    el('p', { class: 'page-subtitle', text: subtitle }),
  ]);
}

function setupView(onUnlocked) {
  const passphrase = el('input', { type: 'password', autocomplete: 'new-password', placeholder: 'A long phrase you will remember' });
  const confirm = el('input', { type: 'password', autocomplete: 'new-password', placeholder: 'Type it again' });
  const meter = el('div', { class: 'strength' }, [0, 1, 2, 3].map(() => el('span')));
  const hint = el('p', { class: 'stat-foot', text: 'Four random words make a strong, memorable passphrase.' });
  const error = el('p', { class: 'error' });
  const submit = el('button', { class: 'btn-primary', type: 'submit', text: 'Create my vault' });

  passphrase.addEventListener('input', () => {
    const score = passphraseStrength(passphrase.value);
    meter.querySelectorAll('span').forEach((bar, index) => {
      bar.className = index < score ? `on-${score}` : '';
    });
    hint.textContent = passphrase.value
      ? `Passphrase strength: ${STRENGTH_WORDS[score]}`
      : 'Four random words make a strong, memorable passphrase.';
  });

  const form = el('form', {
    onsubmit: async (event) => {
      event.preventDefault();
      error.textContent = '';
      if (passphrase.value.length < 8) {
        error.textContent = 'Use at least 8 characters - longer is much better.';
        return;
      }
      if (passphrase.value !== confirm.value) {
        error.textContent = 'The two passphrases do not match.';
        return;
      }
      submit.disabled = true;
      submit.textContent = 'Encrypting…';
      try {
        await createNewVault(passphrase.value);
        onUnlocked();
      } catch (err) {
        error.textContent = err.message || 'Could not create the vault.';
        submit.disabled = false;
        submit.textContent = 'Create my vault';
      }
    },
  }, [
    field('Choose a passphrase', passphrase),
    meter,
    hint,
    el('div', { style: 'height:12px' }),
    field('Confirm passphrase', confirm),
    submit,
    error,
    el('p', { class: 'lock-note' }, [
      'Your statements are read and stored ',
      el('strong', { text: 'only on this device' }),
      ', encrypted with this passphrase (AES-256-GCM). Nothing is uploaded, and there is no account and no password reset — if you forget the passphrase the data cannot be recovered by anyone, including you.',
    ]),
  ]);

  return el('div', { class: 'lock-screen' }, [
    el('div', { class: 'card lock-card' }, [
      head('Set up your money vault', 'One passphrase, stored nowhere, protects everything.'),
      form,
      restoreBlock(onUnlocked),
    ]),
  ]);
}

function unlockView(onUnlocked) {
  const passphrase = el('input', { type: 'password', autocomplete: 'current-password', placeholder: 'Your passphrase', autofocus: true });
  const error = el('p', { class: 'error' });
  const submit = el('button', { class: 'btn-primary', type: 'submit', text: 'Unlock' });

  const form = el('form', {
    onsubmit: async (event) => {
      event.preventDefault();
      error.textContent = '';
      submit.disabled = true;
      submit.textContent = 'Decrypting…';
      try {
        await unlock(passphrase.value);
        onUnlocked();
      } catch {
        error.textContent = 'That passphrase does not open this vault.';
        submit.disabled = false;
        submit.textContent = 'Unlock';
        passphrase.select();
      }
    },
  }, [field('Passphrase', passphrase), submit, error]);

  return el('div', { class: 'lock-screen' }, [
    el('div', { class: 'card lock-card' }, [
      head('Welcome back', 'Your data stays encrypted until you unlock it.'),
      form,
      restoreBlock(onUnlocked),
    ]),
  ]);
}

/** Restore from an encrypted backup file (e.g. on a new device). */
function restoreBlock(onUnlocked) {
  const fileInput = el('input', { type: 'file', accept: '.json,application/json', style: 'display:none' });
  const error = el('p', { class: 'error' });

  fileInput.addEventListener('change', async () => {
    const file = fileInput.files?.[0];
    if (!file) return;
    const text = await file.text();
    const passphrase = window.prompt('Passphrase for this backup file:');
    if (!passphrase) return;
    try {
      await restoreEncryptedBackup(text, passphrase);
      onUnlocked();
    } catch (err) {
      error.textContent = err.message?.includes('not a finance tracker')
        ? err.message
        : 'Could not open that backup with that passphrase.';
    }
    fileInput.value = '';
  });

  return el('details', { style: 'margin-top:16px' }, [
    el('summary', { class: 'stat-foot', style: 'cursor:pointer', text: 'Restore from an encrypted backup' }),
    el('p', { class: 'lock-note', text: 'Pick a backup file you exported earlier. It is decrypted here on this device.' }),
    el('button', { class: 'btn-small', type: 'button', text: 'Choose backup file', onclick: () => fileInput.click() }),
    fileInput,
    error,
  ]);
}
