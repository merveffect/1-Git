#!/bin/bash
# ============================================================
# Pull latest code and restart the service on the GCE VM
# Run this on the VM whenever you push new changes to git
# ============================================================
set -e

APP_DIR="/opt/datamonitor"

echo "==> Pulling latest code..."
cd $APP_DIR
git pull origin main

echo "==> Rebuilding frontend..."
cd $APP_DIR/frontend
npm install --silent
npm run build

echo "==> Installing any new Python deps..."
cd $APP_DIR/backend
.venv/bin/pip install -q -r requirements.txt

echo "==> Restarting service..."
systemctl restart datamonitor

echo "✓ Update complete — $(systemctl is-active datamonitor)"
