# Architecture

## Overview

The devops-local-platform runs locally and demonstrates a complete DevOps workflow without cloud dependencies.

## System Diagram

```
                        ┌──────────────────────────────────────────────────┐
                        │                 NGINX Gateway :80                │
                        │  rate limiting · load balancing · sec headers   │
                        └────────────┬──────────────┬───────────────┬──────┘
                                     │              │               │
                              ┌──────▼──────┐ ┌────▼────┐  ┌───────▼───────┐
                              │   devops-api│ │  auth-  │  │  user-service │
                              │    :3000    │ │ service │  │     :3002     │
                              │  Express    │ │  :3001  │  │  Express + pg │
                              └──────┬──────┘ └─────────┘  └───────┬───────┘
                                     │                              │
                        ┌────────────▼──────────────────────────────▼──────┐
                        │              PostgreSQL :5432                     │
                        │         devops_platform database                  │
                        └───────────────────────────────────────────────────┘
                                     │
                        ┌────────────▼──────────────┐
                        │       Redis :6379          │
                        │    cache / sessions        │
                        └───────────────────────────┘

Observability Stack:
┌─────────────────────────────────────────────────────────────┐
│  Prometheus :9090  ←── scrape /metrics ───  all services    │
│       ↓ evaluate rules/alerts                               │
│  Alertmanager :9093 ──→ Discord / Slack webhook             │
│       ↓ feed datasource                                     │
│  Grafana :3030  ←── dashboards + alerts + logs              │
│       ↑                                                     │
│  Loki :3100  ←── Promtail ←── Docker/k8s container logs    │
└─────────────────────────────────────────────────────────────┘

Infrastructure Exporters:
  node-exporter :9100  — host OS metrics
  cAdvisor :8080       — container metrics
```

## GitOps Flow

```
Developer pushes code → GitHub
         │
         ▼
  GitHub Actions CI/CD
  ├── gitleaks (secret scan)
  ├── eslint (lint)
  ├── jest (tests + coverage)
  ├── npm audit (dependency scan)
  ├── docker buildx (multi-stage build)
  ├── trivy (container vuln scan — blocks on CRITICAL)
  ├── helm lint
  └── deploy (Kind + Helm)
         │
         ▼
  ArgoCD (GitOps operator)
  ├── watches Git repo
  ├── auto-syncs on change
  └── self-heals drift
```

## Microservices Communication

```
Client
  │
  ▼
NGINX Gateway
  ├── /          → devops-api (main service)
  ├── /auth/     → auth-service (JWT issuance/verification)
  └── /users/    → user-service (CRUD via PostgreSQL)
```

## Technology Decisions

| Decision | Choice | Rationale |
|---|---|---|
| Runtime | Node.js 20 LTS | Stable, wide ecosystem |
| Container build | Multi-stage Dockerfile | Minimal image size, no dev deps in prod |
| Orchestration | Kubernetes + Helm | Industry standard, parametrizable |
| GitOps | ArgoCD | Declarative, self-healing |
| Metrics | Prometheus + prom-client | De-facto standard |
| Logs | Loki + Promtail | Lightweight, Grafana-native |
| Alerts | Alertmanager | Native Prometheus integration |
| IaC | Terraform (docker provider) | Reproducible local infra |
| Load test | k6 | Modern, Grafana-native |
| Secret scan | Gitleaks | Pre-push protection |
| Container scan | Trivy | Fast, comprehensive CVE DB |
