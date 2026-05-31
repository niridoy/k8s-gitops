# k8s

GitOps layout: each app owns **Deployment + Service**; edge routing is split by boundary.

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

## GHCR image pull (`ghcr-secret`)

Private images from `ghcr.io` need a pull secret. Deployments reference `imagePullSecrets: ghcr-secret`.

### One-time setup (local or CI)

**Option A — after `docker login ghcr.io`:**

```bash
chmod +x scripts/setup-ghcr-pull-secret.sh
./scripts/setup-ghcr-pull-secret.sh
```

**Option B — GitHub PAT (no Docker on machine):**

```bash
export GHCR_USERNAME=your-github-user
export GHCR_TOKEN=ghp_xxxx          # PAT with read:packages
./scripts/setup-ghcr-pull-secret.sh
```

This writes gitignored `components/ghcr-secret/.dockerconfigjson` (default namespace) and `components/ghcr-secret-hotel-app/.dockerconfigjson` (`hotel-app` namespace). Overlays include these via Kustomize `components`.

**Option C — manual secret (no Kustomize secret file):**

```bash
kubectl create secret docker-registry ghcr-secret \
  --docker-server=ghcr.io \
  --docker-username=YOUR_USER \
  --docker-password=YOUR_PAT \
  --docker-email=YOUR_EMAIL

kubectl create secret docker-registry ghcr-secret \
  --docker-server=ghcr.io \
  --docker-username=YOUR_USER \
  --docker-password=YOUR_PAT \
  --docker-email=YOUR_EMAIL \
  -n hotel-app
```

If you use Option C only, remove the `components:` block from overlay `kustomization.yaml` files (secret is not generated from repo).

### Re-deploy after secret exists

```bash
kubectl apply -k user-service/overlays/dev
kubectl apply -k product-service/overlays/dev
kubectl delete pod -l app=product-service
kubectl delete pod -l app=user-service
```

## Validate manifests

```bash
kustomize build platform-ingress/overlays/dev
kustomize build user-service/overlays/dev
kustomize build product-service/overlays/dev
kustomize build sample-php/overlays/dev
```
