# k8s

GitOps repository: **[https://github.com/niridoy/k8s-gitops](https://github.com/niridoy/k8s-gitops)** (local clone folder may still be named `k8s`).

Each app owns **Deployment + Service**; edge routing is split by boundary.

## Ingress design

| Module | Scope | Why separate |
|--------|--------|----------------|
| `platform-ingress/` | `user-service`, `product-service` (default namespace) | Same edge: path-based API on one hostname |
| `sample-php/base/ingress.yml` | `hotel-app` namespace | Different namespace and host (`nginx.local`) |

### Deploy order (per environment)

1. Microservices (workloads + ClusterIP):

   ```bash
   kubectl apply -k user-service/overlays/dev
   kubectl apply -k product-service/overlays/dev
   ```

2. Shared platform ingress (after Services exist):

   ```bash
   kubectl apply -k platform-ingress/overlays/dev
   ```

3. Sample app (independent stack):

   ```bash
   kubectl apply -k sample-php/overlays/dev
   ```

### Environments

- **dev** — path-only rules (no host); suitable for local / IP access
- **stg** — host `api.stg.example.com`
- **prd** — host `api.example.com` + TLS secret `platform-tls` (provision via cert-manager or your PKI)

Replace example hostnames and `ingressClassName` if your cluster uses a different ingress controller.

## Local MySQL (`mysql.db.local`)

```bash
cp .env.example .env
./scripts/setup-local-mysql.sh
kubectl apply -k user-service/overlays/dev
kubectl apply -k product-service/overlays/dev
```

See [local-dev/README.md](local-dev/README.md).

## Argo CD

Register all dev apps (after pushing to `main`):

```bash
./scripts/setup-ghcr-pull-secret.sh
kubectl apply -f argocd/applications/dev/
```

See [argocd/README.md](argocd/README.md) for repo URL migration and patching existing Applications.

## GHCR image pull (`ghcr-secret`)

Private images from `ghcr.io` need a pull secret. Deployments reference `imagePullSecrets: ghcr-secret`.

Create secrets in **default** and **hotel-app** (required before deploy or Argo CD sync):

```bash
chmod +x scripts/setup-ghcr-pull-secret.sh
docker login ghcr.io   # or: export GHCR_USERNAME=... GHCR_TOKEN=...
./scripts/setup-ghcr-pull-secret.sh
```

## Validate manifests

```bash
kustomize build platform-ingress/overlays/dev
kustomize build user-service/overlays/dev
kustomize build product-service/overlays/dev
kustomize build sample-php/overlays/dev
```
