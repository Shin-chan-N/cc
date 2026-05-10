#!/bin/bash
# Deploy script for AWS EC2 (Ubuntu)
# Run this on your EC2 instance after SSH-ing in

set -e

echo "=== Installing dependencies ==="
sudo apt update
sudo apt install -y docker.io docker-compose-v2

echo "=== Starting Docker ==="
sudo systemctl enable docker
sudo systemctl start docker

echo "=== Cloning / pulling repo ==="
# Replace with your repo URL
# git pull origin main

echo "=== Set your Atlas URI ==="
read -p "Enter MONGO_URI: " mongo_uri
export MONGO_URI="$mongo_uri"

echo "=== Building and running ==="
sudo docker compose up --build -d

echo "=== Done! ==="
sudo docker compose ps
