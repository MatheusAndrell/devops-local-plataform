# Runbook: API Down

**Alert:** `APIDown`
**Severity:** Critical
**SLO Impact:** 100% (full outage)

## Detection

Alert fires when `up{job="devops-api"} == 0` for 1 minute.

## Immediate Actions

1. Verify container status:
```bash
docker ps | grep devops-api
kubectl get pods -n devops-platform -l app=devops-api
```

2. Check recent logs:
```bash
docker logs devops-api --tail=50
kubectl logs -l app=devops-api -n devops-platform --tail=50
```

3. Check health endpoint manually:
```bash
curl -v http://localhost:3000/health
```

## Common Causes & Fixes

| Cause | Fix |
|---|---|
| OOMKilled | Increase memory limit in values.yaml or docker-compose.yml |
| CrashLoopBackOff | Check app logs for startup error |
| DB connection refused | Verify postgres is running and credentials are correct |
| Redis connection refused | Verify redis is running |
| Image pull error | Check image tag and registry access |

## Escalation

If not resolved in 15 minutes, escalate to on-call engineer.

## Post-Incident

- Document root cause
- Add test to prevent regression
- Update this runbook if needed
