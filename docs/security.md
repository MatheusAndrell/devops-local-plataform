# Security

## Pipeline Security Controls

| Stage | Tool | Blocks Pipeline |
|---|---|---|
| Secret detection | Gitleaks | Yes (on any push) |
| Dependency audit | npm audit | Yes (HIGH+) |
| Container scan | Trivy | Yes (CRITICAL+HIGH) |
| Dockerfile lint | Hadolint | Warning |
| Helm chart scan | Checkov | Soft fail |

## Container Security

All Dockerfiles enforce:
- Multi-stage builds (no build tools in final image)
- Non-root user (`nodeuser` uid 1001)
- `readOnlyRootFilesystem: true` in Helm values
- `allowPrivilegeEscalation: false`
- `capabilities.drop: [ALL]`

## Network Security

NGINX enforces:
- `X-Frame-Options: DENY`
- `X-Content-Type-Options: nosniff`
- `X-XSS-Protection: 1; mode=block`
- Rate limiting: 100 req/s (API), 20 req/s (auth)
- `/metrics` endpoint blocked externally (returns 403)

## Secret Management

Secrets should never be committed. Use:
- Kubernetes Secrets (base64, reference from `k8s/secret.yaml`)
- `.env` files (gitignored — copy from `.env.example`)
- In production: HashiCorp Vault, AWS Secrets Manager, or similar

## Kubernetes RBAC

The Helm chart creates a dedicated `ServiceAccount` per deployment.
ArgoCD AppProject limits source repos, destinations, and resource types.

## Dependency Policy

Run weekly audits automatically via the `security.yml` GitHub Actions workflow (runs every Monday at 03:00 UTC).
