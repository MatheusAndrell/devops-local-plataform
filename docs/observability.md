# Observability

## Stack

| Component | Role | Port |
|---|---|---|
| Prometheus | Metrics collection & alerting | 9090 |
| Alertmanager | Alert routing & notification | 9093 |
| Grafana | Dashboards, logs, alerts UI | 3030 |
| Loki | Log aggregation | 3100 |
| Promtail | Log shipping (Docker & k8s) | 9080 |
| node-exporter | Host OS metrics | 9100 |
| cAdvisor | Container metrics | 8080 |

## Metrics

Each service exposes `/metrics` in Prometheus format.

Custom metrics (apps/api):
- `http_request_duration_seconds` — Histogram: p50/p95/p99 per route
- `http_requests_total` — Counter: total by method/route/status
- `http_requests_in_flight` — Gauge: concurrent in-flight requests

Default Node.js metrics (prefix `api_`):
- `api_nodejs_heap_size_used_bytes`
- `api_process_cpu_user_seconds_total`
- `api_process_uptime_seconds`

## Alert Rules

### API Alerts (`monitoring/prometheus/rules/api-alerts.yml`)
- **APIDown** — Critical: API unreachable for 1m
- **HighErrorRate** — Warning: 5xx rate > 5% for 2m
- **HighLatencyP99** — Warning: P99 > 1s for 2m
- **HighMemoryUsage** — Warning: heap > 90% for 5m

### Infrastructure Alerts (`monitoring/prometheus/rules/infrastructure-alerts.yml`)
- **HighCPU** — Warning: CPU > 85% for 5m
- **HighMemory** — Critical: memory > 90% for 5m
- **DiskSpaceLow** — Warning: disk < 15%

## Grafana Dashboards

Access: http://localhost:3030 (admin/admin123)

Auto-provisioned dashboards:
- **DevOps API Dashboard** — status, request rate, heap, uptime

## Logs

Loki collects logs from all Docker containers via Promtail.

Query examples in Grafana Explore (Loki datasource):
```logql
{service="devops-api"} |= "error"
{container="devops-api"} | json | level="error"
{namespace="devops-platform"} |~ "timeout|failed"
```
