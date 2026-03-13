#!/bin/bash
# ============================================================
# DataMonitor — GCE VM Setup Script
# Run this once on a fresh Debian/Ubuntu GCE VM as root or
# with sudo: bash setup.sh
# ============================================================
set -e

APP_USER="datamonitor"
APP_DIR="/opt/datamonitor"
REPO_URL="https://github.com/merveffect/1-Git.git"  # update if repo moves

echo "==> Installing system packages..."
apt-get update -qq
apt-get install -y -qq git nginx python3 python3-pip python3-venv nodejs npm

echo "==> Creating app user..."
id -u $APP_USER &>/dev/null || useradd -m -s /bin/bash $APP_USER

echo "==> Cloning repo..."
rm -rf $APP_DIR
git clone $REPO_URL $APP_DIR
chown -R $APP_USER:$APP_USER $APP_DIR

echo "==> Building frontend..."
cd $APP_DIR/frontend
npm install --silent
npm run build
chown -R $APP_USER:$APP_USER $APP_DIR/frontend/dist

echo "==> Setting up Python virtualenv..."
cd $APP_DIR/backend
python3 -m venv .venv
.venv/bin/pip install -q --upgrade pip
.venv/bin/pip install -q -r requirements.txt

echo "==> Creating .env from example..."
if [ ! -f $APP_DIR/backend/.env ]; then
  cp $APP_DIR/backend/.env.example $APP_DIR/backend/.env
  echo "  !! Edit $APP_DIR/backend/.env and set DBT_PROJECT_PATH if needed"
fi
chown $APP_USER:$APP_USER $APP_DIR/backend/.env

echo "==> Installing systemd service..."
cp $APP_DIR/deploy/datamonitor.service /etc/systemd/system/datamonitor.service
systemctl daemon-reload
systemctl enable datamonitor
systemctl restart datamonitor

echo "==> Configuring Nginx..."
cp $APP_DIR/deploy/nginx.conf /etc/nginx/sites-available/datamonitor
ln -sf /etc/nginx/sites-available/datamonitor /etc/nginx/sites-enabled/datamonitor
rm -f /etc/nginx/sites-enabled/default
nginx -t && systemctl restart nginx

echo ""
echo "✓ Setup complete!"
echo "  App running at: http://$(curl -s ifconfig.me)"
echo "  Service status: systemctl status datamonitor"
echo "  Logs:           journalctl -u datamonitor -f"
