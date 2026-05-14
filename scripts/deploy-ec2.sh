#!/bin/bash
# Deploy script for AWS EC2 (Ubuntu) — no Docker
# Usage: MONGO_URI="mongodb+srv://..." bash scripts/deploy-ec2.sh
#   or:  bash scripts/deploy-ec2.sh "mongodb+srv://..."

set -euo pipefail

MONGO_URI="${MONGO_URI:-${1:-}}"
if [ -z "$MONGO_URI" ]; then
  echo "ERROR: MONGO_URI is required."
  echo "Usage: MONGO_URI=\"mongodb+srv://...\" bash scripts/deploy-ec2.sh"
  exit 1
fi

REPO_URL="${REPO_URL:-git@github.com:your-org/cc.git}"
REPO_DIR="/home/ubuntu/cc"

echo "=== Installing Node.js 20, nginx, and pm2 ==="
sudo apt update
sudo apt install -y nginx curl
curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -
sudo apt install -y nodejs
sudo npm install -g pm2 serve

echo "=== Cloning / pulling repo ==="
if [ ! -d "$REPO_DIR" ]; then
  git clone "$REPO_URL" "$REPO_DIR"
else
  cd "$REPO_DIR" && git pull origin main
fi

echo "=== Building frontend ==="
cd "$REPO_DIR/frontend"
npm install
npm run build

echo "=== Installing backend dependencies ==="
cd "$REPO_DIR/backend"
npm install

echo "=== Configuring nginx ==="
sudo tee /etc/nginx/sites-available/cc > /dev/null <<'NGINX'
server {
    listen 80 default_server;
    server_name _;

    gzip on;
    gzip_types text/css application/javascript image/svg+xml;
    gzip_min_length 256;

    location / {
        proxy_pass http://127.0.0.1:3000;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    }

    location /api/ {
        proxy_pass http://127.0.0.1:5000;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    }
}
NGINX
sudo rm -f /etc/nginx/sites-enabled/default
sudo ln -sf /etc/nginx/sites-available/cc /etc/nginx/sites-enabled/
sudo nginx -t
sudo systemctl enable nginx
sudo systemctl restart nginx

echo "=== Starting backend with pm2 ==="
cd "$REPO_DIR/backend"
pm2 delete cc-backend 2>/dev/null || true
MONGO_URI="$MONGO_URI" PORT=5000 pm2 start server.js --name cc-backend

echo "=== Starting frontend with pm2 ==="
pm2 delete cc-frontend 2>/dev/null || true
pm2 start "$(which serve)" --name cc-frontend -- -s "$REPO_DIR/frontend/dist" -l 3000 --no-clipboard

pm2 save
sudo env PATH="$PATH:/usr/bin" pm2 startup systemd -u ubuntu --hp /home/ubuntu

echo "=== Done! ==="
pm2 list
sudo systemctl status nginx --no-pager
