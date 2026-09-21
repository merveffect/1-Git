/**
 * Entry point. Shows the lock screen until the vault is open, then the app.
 *
 * Nothing in this app makes a network request - the page's Content-Security-Policy
 * blocks outbound connections entirely, which is why there are no third-party
 * scripts, fonts or analytics anywhere in the bundle.
 */

import { store } from './state.js';
import { renderLock } from './ui/lock.js';
import { renderShell } from './ui/shell.js';
import { applyTheme } from './ui/settings.js';

const root = document.getElementById('app');
let shell = null;

function showLock() {
  if (shell) {
    shell.destroy();
    shell = null;
  }
  renderLock(root, { onUnlocked: showApp });
}

function showApp() {
  applyTheme(store.prefs.theme);
  shell = renderShell(root, { onLocked: showLock });
}

applyTheme(store.prefs.theme);
showLock();

// Warn before a refresh loses an in-flight save.
window.addEventListener('beforeunload', (event) => {
  if (store.saving) {
    event.preventDefault();
    event.returnValue = '';
  }
});
