# Troubleshooting

## Docker Compose

**Containers not starting**
```bash
make logs           # tail all logs
make logs-api       # tail specific service
docker compose -f docker/docker-compose.yml ps
```

**Port conflicts**
Check if ports 80, 3000-3002, 3030, 5432, 6379, 9090, 9093, 9100, 3100 are free:
```bash
netstat -tulnp | grep -E '80|3000|5432|6379'
```

**PostgreSQL health failing**
```bash
docker exec devops-postgres pg_isready -U devops -d devops_platform
docker logs devops-postgres --tail=30
```

**Redis not responding**
```bash
docker exec devops-redis redis-cli ping
```

## Kubernetes

**Pods in CrashLoopBackOff**
```bash
kubectl describe pod <pod-name> -n devops-platform
kubectl logs <pod-name> -n devops-platform --previous
```

**HPA not scaling**
Check metrics-server is running:
```bash
kubectl get deployment metrics-server -n kube-system
kubectl top pods -n devops-platform
```

**Ingress not routing**
```bash
kubectl get ingress -n devops-platform
kubectl describe ingress devops-api-ingress -n devops-platform
```

## Helm

**Rollback a bad release**
```bash
helm history devops-platform -n devops-platform
helm rollback devops-platform <revision> -n devops-platform
```

## Prometheus / Grafana

**No data in dashboard**
- Verify scrape targets: http://localhost:9090/targets
- Check service annotations: `prometheus.io/scrape: "true"`

**Alerts not firing**
```bash
curl http://localhost:9090/api/v1/rules
curl http://localhost:9093/api/v2/alerts
```

## ArgoCD

**Application out of sync**
```bash
kubectl get application -n argocd
argocd app sync devops-api
argocd app diff devops-api
```

**Force refresh**
```bash
argocd app get devops-api --refresh
```
