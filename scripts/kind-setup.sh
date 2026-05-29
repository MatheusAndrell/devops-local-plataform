#!/usr/bin/env bash
set -euo pipefail

CLUSTER="${1:-devops-local}"

echo "==> Setting up Kind cluster: $CLUSTER"

if kind get clusters | grep -q "$CLUSTER"; then
  echo "  Cluster '$CLUSTER' already exists. Skipping creation."
else
  kind create cluster --name "$CLUSTER"
fi

echo "==> Installing NGINX Ingress Controller..."
kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/main/deploy/static/provider/kind/deploy.yaml
kubectl wait --namespace ingress-nginx \
  --for=condition=ready pod \
  --selector=app.kubernetes.io/component=controller \
  --timeout=90s

echo "==> Installing Metrics Server..."
kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml
kubectl patch deployment metrics-server -n kube-system \
  --type=json \
  -p='[{"op":"add","path":"/spec/template/spec/containers/0/args/-","value":"--kubelet-insecure-tls"}]'

echo "==> Kind cluster '$CLUSTER' is ready."
echo "  kubectl get nodes"
kubectl get nodes
