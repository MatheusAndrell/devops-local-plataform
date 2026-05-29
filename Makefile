.PHONY: help up down build deploy monitor logs test load-test lint clean setup k8s-apply k8s-delete helm-install argocd-install

COMPOSE = docker compose -f docker/docker-compose.yml
KUBECTL = kubectl
HELM = helm
KIND_CLUSTER = devops-local
NAMESPACE = devops-platform

help:
	@echo ""
	@echo "  DevOps Local Platform — Commands"
	@echo ""
	@echo "  Local Stack (Docker Compose)"
	@echo "  make setup        — Install dependencies for all services"
	@echo "  make build        — Build all Docker images"
	@echo "  make up           — Start full stack"
	@echo "  make down         — Stop stack"
	@echo "  make restart      — Restart stack"
	@echo "  make logs         — Tail all container logs"
	@echo "  make ps           — Show running containers"
	@echo ""
	@echo "  Testing"
	@echo "  make test         — Run unit tests"
	@echo "  make lint         — Run linters"
	@echo "  make load-test    — Run k6 stress test"
	@echo "  make smoke-test   — Run k6 smoke test"
	@echo ""
	@echo "  Kubernetes"
	@echo "  make kind-create  — Create Kind cluster"
	@echo "  make k8s-apply    — Apply all manifests"
	@echo "  make k8s-delete   — Delete all manifests"
	@echo "  make helm-install — Deploy with Helm"
	@echo "  make argocd-install — Install ArgoCD"
	@echo ""
	@echo "  Monitoring"
	@echo "  make monitor      — Open monitoring URLs"
	@echo "  make alerts       — Check active alerts"
	@echo ""
	@echo "  Terraform"
	@echo "  make tf-init      — Terraform init (dev)"
	@echo "  make tf-plan      — Terraform plan (dev)"
	@echo "  make tf-apply     — Terraform apply (dev)"
	@echo "  make tf-destroy   — Terraform destroy (dev)"
	@echo ""

setup:
	cd apps/api && npm ci
	cd apps/auth-service && npm ci
	cd apps/user-service && npm ci

build:
	docker build -t devops-local-platform-api:latest apps/api/
	docker build -t devops-auth-service:latest apps/auth-service/
	docker build -t devops-user-service:latest apps/user-service/

up:
	$(COMPOSE) up -d
	@echo ""
	@echo "  Stack running:"
	@echo "  API          → http://localhost:3000"
	@echo "  Auth         → http://localhost:3001"
	@echo "  Users        → http://localhost:3002"
	@echo "  NGINX        → http://localhost:80"
	@echo "  Prometheus   → http://localhost:9090"
	@echo "  Grafana      → http://localhost:3030  (admin/admin123)"
	@echo "  Alertmanager → http://localhost:9093"
	@echo "  Loki         → http://localhost:3100"
	@echo ""

down:
	$(COMPOSE) down

restart:
	$(COMPOSE) restart

ps:
	$(COMPOSE) ps

logs:
	$(COMPOSE) logs -f --tail=50

logs-%:
	$(COMPOSE) logs -f --tail=100 $*

lint:
	cd apps/api && npm run lint
	cd apps/auth-service && npm run lint 2>/dev/null || true
	cd apps/user-service && npm run lint 2>/dev/null || true
	$(HELM) lint helm/devops-platform/

test:
	cd apps/api && npm test
	cd apps/auth-service && npm test 2>/dev/null || true
	cd apps/user-service && npm test 2>/dev/null || true

load-test:
	mkdir -p tests/load/results
	k6 run tests/load/stress-test.js

smoke-test:
	mkdir -p tests/load/results
	k6 run tests/load/smoke-test.js

spike-test:
	mkdir -p tests/load/results
	k6 run tests/load/spike-test.js

kind-create:
	kind create cluster --name $(KIND_CLUSTER)
	kubectl cluster-info --context kind-$(KIND_CLUSTER)

kind-load:
	kind load docker-image devops-local-platform-api:latest --name $(KIND_CLUSTER)

k8s-apply:
	$(KUBECTL) apply -f k8s/namespace.yaml
	$(KUBECTL) apply -f k8s/configmap.yaml
	$(KUBECTL) apply -f k8s/secret.yaml
	$(KUBECTL) apply -f k8s/deployment.yaml
	$(KUBECTL) apply -f k8s/service.yaml
	$(KUBECTL) apply -f k8s/ingress.yaml
	$(KUBECTL) apply -f k8s/hpa.yaml
	$(KUBECTL) rollout status deployment/devops-api -n $(NAMESPACE)

k8s-delete:
	$(KUBECTL) delete -f k8s/ --ignore-not-found

helm-install:
	$(HELM) upgrade --install devops-platform helm/devops-platform/ \
		-f helm/devops-platform/values.yaml \
		--namespace $(NAMESPACE) \
		--create-namespace \
		--wait

helm-uninstall:
	$(HELM) uninstall devops-platform --namespace $(NAMESPACE)

argocd-install:
	kubectl apply -f gitops/argocd/install/argocd-namespace.yaml
	kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
	kubectl wait --for=condition=available deployment/argocd-server -n argocd --timeout=120s
	kubectl apply -f gitops/argocd/projects/
	kubectl apply -f gitops/argocd/apps/

monitor:
	@echo "Opening monitoring dashboards..."
	@echo "  Grafana      → http://localhost:3030"
	@echo "  Prometheus   → http://localhost:9090"
	@echo "  Alertmanager → http://localhost:9093"

alerts:
	@curl -s http://localhost:9093/api/v2/alerts | python3 -m json.tool 2>/dev/null || \
	  curl -s http://localhost:9093/api/v2/alerts

tf-init:
	cd terraform/environments/dev && terraform init

tf-plan:
	cd terraform/environments/dev && terraform plan

tf-apply:
	cd terraform/environments/dev && terraform apply

tf-destroy:
	cd terraform/environments/dev && terraform destroy

deploy: build k8s-apply

clean:
	$(COMPOSE) down -v --remove-orphans
	docker image prune -f
