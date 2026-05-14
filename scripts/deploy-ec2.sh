#!/bin/bash
# Deploy script for AWS EC2 (Ubuntu) — no Docker
# Run this on your EC2 instance after SSH-ing in

set -e

echo "=== Installing Node.js 20, nginx, and pm2 ==="
sudo apt update
sudo apt install -y nginx curl
curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -
sudo apt install -y nodejs
sudo npm install -g pm2

echo "=== Cloning / pulling repo ==="
REPO_DIR="/home/ubuntu/cc"
# git clone <repo-url> "$REPO_DIR" || (cd "$REPO_DIR" && git pull origin main)

cd "$REPO_DIR"

echo "=== Set your Atlas URI ==="
read -p "Enter MONGO_URI: " mongo_uri
export MONGO_URI="$mongo_uri"

echo "=== Installing backend dependencies ==="
cd "$REPO_DIR/backend"
npm install

echo "=== Installing frontend dependencies & building ==="
cd "$REPO_DIR/frontend"
npm install
npm run build

echo "=== Configuring nginx ==="
sudo tee /etc/nginx/sites-available/cc > /dev/null <<'NGINX'
server {
    listen 80 default_server;
    server_name _;

    root /home/ubuntu/cc/frontend/dist;
    index index.html;

    location / {
        try_files $uri /index.html;
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
MONGO_URI="$mongo_uri" pm2 start server.js --name cc-backend
pm2 save
sudo env PATH="$PATH:/usr/bin" pm2 startup systemd -u ubuntu --hp /home/ubuntu

echo "=== Done! ==="
pm2 list
sudo systemctl status nginx --no-pager
