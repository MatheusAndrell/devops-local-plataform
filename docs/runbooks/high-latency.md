# Runbook: High Latency

**Alert:** `HighLatencyP99`
**Severity:** Warning
**SLO Impact:** Partial (latency SLO breach)

## Detection

Alert fires when P99 latency > 1s for 2 minutes on any route.

## Immediate Actions

1. Check P99 in Grafana: http://localhost:3030
   - Dashboard: DevOps API Dashboard → "HTTP Request Duration"

2. Identify slow routes:
```promql
histogram_quantile(0.99, sum(rate(http_request_duration_seconds_bucket[5m])) by (le, route))
```

3. Check in-flight requests:
```promql
http_requests_in_flight
```

4. Check DB query times:
```bash
docker exec devops-postgres psql -U devops -d devops_platform \
  -c "SELECT pid, query, state, query_start FROM pg_stat_activity WHERE state != 'idle';"
```

5. Check Redis latency:
```bash
docker exec devops-redis redis-cli --latency -i 1
```

## Common Causes & Fixes

| Cause | Fix |
|---|---|
| Slow DB queries | Add index, optimize query |
| Redis miss causing DB pressure | Increase TTL, warm cache |
| High traffic | Check HPA, increase replicas manually |
| Memory pressure causing GC pauses | Scale vertically, check heap metrics |
| Downstream dependency slow | Circuit breaker, timeout tuning |

## Mitigation

Scale API replicas immediately:
```bash
kubectl scale deployment devops-api --replicas=5 -n devops-platform
```

## Post-Incident

- Identify root cause via distributed traces
- Add p99 regression test to load test suite
