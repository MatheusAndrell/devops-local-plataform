# devops-local-platform

![CI/CD](https://img.shields.io/github/actions/workflow/status/your-org/devops-local-platform/ci-cd.yml?label=CI%2FCD&logo=github-actions)
![Security](https://img.shields.io/github/actions/workflow/status/your-org/devops-local-platform/security.yml?label=Security&logo=trivy)
![Node](https://img.shields.io/badge/Node.js-20_LTS-green?logo=node.js)
![Docker](https://img.shields.io/badge/Docker-Compose-blue?logo=docker)
![Kubernetes](https://img.shields.io/badge/Kubernetes-Kind-326CE5?logo=kubernetes)
![Helm](https://img.shields.io/badge/Helm-3-0F1689?logo=helm)
![ArgoCD](https://img.shields.io/badge/GitOps-ArgoCD-orange?logo=argo)
![Terraform](https://img.shields.io/badge/IaC-Terraform-7B42BC?logo=terraform)
![Grafana](https://img.shields.io/badge/Observability-Grafana-F46800?logo=grafana)
![License](https://img.shields.io/badge/License-MIT-lightgrey)

> Production-grade DevOps platform running fully locally. Simulates a real cloud-native engineering environment with GitOps, observability, security, autoscaling, and microservices.

---

## Architecture

```
                        ┌──────────────────────────────────────┐
                        │     NGINX Gateway :80                │
                        │   rate limit · LB · sec headers      │
                        └────────┬──────────┬──────────┬───────┘
                                 │          │          │
                          ┌──────▼──┐ ┌─────▼──┐ ┌───▼──────┐
                          │devops-  │ │ auth-  │ │  user-   │
                          │  api    │ │service │ │ service  │
                          │ :3000   │ │ :3001  │ │  :3002   │
                          └────┬────┘ └────────┘ └────┬─────┘
                               │                      │
                    ┌──────────▼──────────────────────▼──────┐
                    │        PostgreSQL :5432                 │
                    └────────────────────────────────────────┘
                               │
                    ┌──────────▼──────────┐
                    │    Redis :6379      │
                    └─────────────────────┘

Observability:
  Prometheus :9090 → Alertmanager :9093 → Discord/Slack
       ↓
  Grafana :3030 ← Loki :3100 ← Promtail ← Docker logs
  node-exporter :9100 · cAdvisor :8080
```

## Stack

| Layer | Technology |
|---|---|
| Application | Node.js 20 + Express |
| Microservices | api / auth-service / user-service |
| Database | PostgreSQL 16 + Redis 7 |
| Containerization | Docker + Docker Compose |
| Orchestration | Kubernetes (Kind) + Helm 3 |
| GitOps | ArgoCD |
| CI/CD | GitHub Actions |
| Metrics | Prometheus + prom-client |
| Logs | Loki + Promtail |
| Dashboards | Grafana |
| Alerting | Alertmanager → Discord/Slack |
| Gateway | NGINX (rate limiting, security headers) |
| IaC | Terraform (kreuzwerker/docker) |
| Load Testing | k6 |
| Secret Scan | Gitleaks |
| Container Scan | Trivy |
| Autoscaling | Kubernetes HPA |

## Project Structure

```
devops-local-platform/
├── apps/
│   ├── api/               # Main API — Express, PostgreSQL, Redis, Prometheus metrics
│   ├── auth-service/      # JWT authentication service
│   └── user-service/      # User CRUD via PostgreSQL
├── docker/
│   └── docker-compose.yml # Full stack: 12 services
├── helm/
│   └── devops-platform/   # Helm chart with values per environment
├── k8s/
│   ├── base/              # Kustomize base manifests
│   ├── overlays/          # dev / staging / prod overlays
│   ├── deployment.yaml    # readinessProbe + livenessProbe + rolling update
│   └── hpa.yaml           # HorizontalPodAutoscaler (CPU + memory)
├── gitops/
│   └── argocd/            # AppProject + Application resources
├── terraform/
│   ├── modules/           # network + containers modules
│   └── environments/      # dev + prod configurations
├── monitoring/
│   ├── prometheus/        # prometheus.yml + alert rules + alertmanager
│   └── grafana/           # auto-provisioned dashboards + datasources
├── logging/
│   ├── loki/              # Loki config
│   └── promtail/          # Promtail scrape config
├── nginx/
│   └── nginx.conf         # Gateway: rate limiting, LB, security headers
├── tests/
│   └── load/              # k6: stress / spike / smoke
├── scripts/               # setup.sh, deploy.sh, kind-setup.sh
├── docs/                  # architecture, observability, security, runbooks
├── .github/workflows/     # ci-cd · security · load-test
├── Makefile               # All commands
└── README.md
```

## Prerequisites

- [Docker](https://docs.docker.com/get-docker/) >= 24 + Compose v2
- [Node.js](https://nodejs.org/) 20
- [kubectl](https://kubernetes.io/docs/tasks/tools/) + [Kind](https://kind.sigs.k8s.io/)
- [Helm](https://helm.sh/docs/intro/install/) >= 3.14
- [Terraform](https://developer.hashicorp.com/terraform/install) >= 1.6
- [k6](https://grafana.com/docs/k6/latest/get-started/installation/) (load testing)

## Quick Start

```bash
# 1. Install dependencies and build images
make setup
make build

# 2. Start the full stack
make up
```

## Environment

Copy the example files to local `.env` files before running any service directly with Node.js or customizing the Docker Compose stack:

- `.env.example` → `.env`
- `apps/api/.env.example` → `apps/api/.env`
- `apps/auth-service/.env.example` → `apps/auth-service/.env`
- `apps/user-service/.env.example` → `apps/user-service/.env`

The Docker Compose stack keeps sane defaults, so these files are mainly for local service runs and overrides.

To enable Discord notifications from Alertmanager, set `DISCORD_WEBHOOK_URL` in `.env`.

| Service | URL | Credentials |
|---|---|---|
| API | http://localhost:3000 | — |
| Auth Service | http://localhost:3001 | — |
| User Service | http://localhost:3002 | — |
| NGINX Gateway | http://localhost:80 | — |
| Prometheus | http://localhost:9090 | — |
| Grafana | http://localhost:3030 | admin / admin123 |
| Alertmanager | http://localhost:9093 | — |
| Loki | http://localhost:3100 | — |

## API Endpoints

| Service | Method | Route | Description |
|---|---|---|---|
| api | GET | `/` | Service status |
| api | GET | `/health` | Enterprise healthcheck (DB + Redis + system) |
| api | GET | `/metrics` | Prometheus metrics |
| api | GET | `/cache-test` | Redis cache demo |
| auth | POST | `/auth/login` | Issue JWT token |
| auth | POST | `/auth/verify` | Verify JWT token |
| users | GET | `/users` | List users |
| users | POST | `/users` | Create user |
| users | GET | `/users/:id` | Get user by ID |

### Example: Login

```bash
curl -X POST http://localhost:3001/auth/login \
  -H "Content-Type: application/json" \
  -d '{"username":"admin","password":"admin123"}'
```

### Example: Enterprise Health Check

```bash
curl http://localhost:3000/health | jq
# {
#   "status": "healthy",
#   "checks": { "postgres": {"status":"healthy"}, "redis": {"status":"healthy"} },
#   "system": { "memory": {...}, "cpu": [...], "platform": "linux" },
#   "uptime": 142,
#   "responseTime": "4ms"
# }
```

## CI/CD Flow

```
push → main
  │
  ├── [gitleaks]        Secret leak detection (blocks on any finding)
  ├── [lint]            ESLint
  ├── [dependency-scan] npm audit --audit-level=high
  ├── [test]            Jest + coverage artifact
  ├── [build]           Docker multi-stage build
  ├── [trivy]           Container CVE scan (blocks on CRITICAL/HIGH)
  ├── [helm-lint]       Helm lint + template render
  └── [deploy]          Kind cluster + Helm + smoke test
```

PRs trigger: gitleaks + lint + test + dependency-scan + helm-lint only.

Weekly security workflow: full filesystem scan + dependency audit for all services.

## Kubernetes Deployment

```bash
# Create Kind cluster with Ingress + Metrics Server
bash scripts/kind-setup.sh

# Build and load image
make build
make kind-load

# Deploy with Helm
make helm-install

# Or with kubectl + Kustomize (prod overlay)
kubectl apply -k k8s/overlays/prod/

# Check HPA
kubectl get hpa -n devops-platform
kubectl top pods -n devops-platform
```

## GitOps (ArgoCD)

```bash
# Install ArgoCD
make argocd-install

# Access ArgoCD UI
kubectl port-forward svc/argocd-server -n argocd 8443:443
# https://localhost:8443  (admin / get password below)
kubectl -n argocd get secret argocd-initial-admin-secret \
  -o jsonpath="{.data.password}" | base64 -d
```

After updating `gitops/argocd/apps/api-app.yaml` with your repo URL, ArgoCD will auto-sync on every push to `main`.

## Load Testing

```bash
make smoke-test    # 1 VU, 30s — sanity check
make load-test     # stress: ramp to 200 VUs over 19m
make spike-test    # spike: 5 → 500 VUs in 10s
```

Results are saved to `tests/load/results/`.

## Multi-Environment

| Environment | Replicas | HPA | Image Tag |
|---|---|---|---|
| dev | 1 | disabled | latest |
| staging | 2 | 2–5 | staging |
| prod | 3 | 3–10 | stable |

```bash
# Helm deploy to staging
helm upgrade --install devops-platform helm/devops-platform/ \
  -f helm/devops-platform/values.yaml \
  -f helm/devops-platform/values-staging.yaml \
  --namespace devops-platform --create-namespace
```

## Terraform (IaC)

```bash
cd terraform/environments/dev
terraform init
terraform plan
terraform apply
# Outputs: api_url, grafana_url, prometheus_url
```

## Monitoring

Grafana auto-provisions:
- **Datasource**: Prometheus + Loki
- **Dashboard**: DevOps API Dashboard

Alert rules evaluate every 30s. Alerts route to Discord via webhook (set `DISCORD_WEBHOOK_URL` in `alertmanager.yml`).

Alert examples:
- `APIDown` → Critical → immediate Discord ping
- `HighLatencyP99 > 1s` → Warning
- `HighErrorRate > 5%` → Warning
- `HighCPU > 85%` → Warning

## Available Make Commands

```
make help         — List all commands
make up           — Start stack
make down         — Stop stack
make build        — Build images
make setup        — Install dependencies
make test         — Run unit tests
make lint         — Lint all services + Helm
make load-test    — k6 stress test
make smoke-test   — k6 smoke test
make monitor      — Show monitoring URLs
make alerts       — Check active alerts
make helm-install — Helm deploy to Kind
make kind-create  — Create Kind cluster
make argocd-install — Install ArgoCD
make tf-apply     — Terraform apply (dev)
make logs         — Tail all logs
make clean        — Remove containers + volumes
```

## Documentation

- [docs/architecture.md](docs/architecture.md) — System design + decisions
- [docs/observability.md](docs/observability.md) — Metrics, logs, alerts
- [docs/security.md](docs/security.md) — Security controls
- [docs/troubleshooting.md](docs/troubleshooting.md) — Common issues
- [docs/runbooks/api-down.md](docs/runbooks/api-down.md) — API outage runbook
- [docs/runbooks/high-latency.md](docs/runbooks/high-latency.md) — Latency runbook

## Roadmap

- [ ] Distributed tracing with Jaeger / Tempo
- [ ] mTLS between microservices (Istio / Linkerd)
- [ ] Vault for secret management
- [ ] KEDA for event-driven autoscaling
- [ ] Chaos engineering with LitmusChaos
- [ ] SLO tracking with Sloth

## License

MIT
