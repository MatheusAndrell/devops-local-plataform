#!/usr/bin/env bash
set -euo pipefail

ENV="${1:-dev}"
IMAGE_TAG="${2:-latest}"
NAMESPACE="devops-platform"

echo "==> Deploying to environment: $ENV (image tag: $IMAGE_TAG)"

if ! kind get clusters | grep -q "devops-local"; then
  echo "==> Creating Kind cluster..."
  kind create cluster --name devops-local
fi

echo "==> Loading Docker image into Kind..."
kind load docker-image "devops-local-platform-api:${IMAGE_TAG}" --name devops-local

echo "==> Deploying with Helm..."
helm upgrade --install devops-platform helm/devops-platform/ \
  -f "helm/devops-platform/values.yaml" \
  -f "helm/devops-platform/values-${ENV}.yaml" \
  --namespace "$NAMESPACE" \
  --create-namespace \
  --set "image.tag=${IMAGE_TAG}" \
  --wait --timeout=120s

echo "==> Waiting for rollout..."
kubectl rollout status deployment/devops-platform-devops-platform \
  -n "$NAMESPACE" --timeout=120s

echo "==> Smoke test..."
kubectl port-forward "svc/devops-platform-devops-platform" 9999:80 \
  -n "$NAMESPACE" &
PF_PID=$!
sleep 5

if curl -sf http://localhost:9999/health > /dev/null; then
  echo "  [OK] Health check passed"
else
  echo "  [FAIL] Health check failed"
  kill $PF_PID 2>/dev/null || true
  exit 1
fi

kill $PF_PID 2>/dev/null || true
echo "==> Deployment complete."
