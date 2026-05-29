#!/usr/bin/env bash
set -euo pipefail

echo "==> Checking prerequisites..."

for cmd in docker kubectl helm kind k6 terraform node; do
  if command -v "$cmd" &>/dev/null; then
    echo "  [OK] $cmd $(${cmd} --version 2>&1 | head -1)"
  else
    echo "  [MISSING] $cmd"
  fi
done

echo ""
echo "==> Installing Node.js dependencies..."
for service in apps/api apps/auth-service apps/user-service; do
  echo "  -> $service"
  (cd "$service" && npm ci --silent)
done

echo ""
echo "==> Building Docker images..."
docker build -t devops-local-platform-api:latest apps/api/ -q
docker build -t devops-auth-service:latest apps/auth-service/ -q
docker build -t devops-user-service:latest apps/user-service/ -q

echo ""
echo "==> Setup complete. Run 'make up' to start the stack."
