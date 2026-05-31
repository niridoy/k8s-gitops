# Argo CD

GitOps repo: **[niridoy/k8s-gitops](https://github.com/niridoy/k8s-gitops)**

Your local folder may still be named `k8s`; that is fine — only the GitHub repo name matters for Argo CD and CI.

## Register apps in Argo CD

1. Create GHCR pull secrets once:

   ```bash
   ./scripts/setup-ghcr-pull-secret.sh
   ```

2. Push to `main` on **k8s-gitops**, then:

   ```bash
   kubectl apply -f argocd/applications/dev/
   ```

Apps in the UI:

- `hotel-app`
- `user-service-dev`
- `product-service-dev`
- `platform-ingress-dev`

## Fix Argo CD still pointing at old `k8s` repo

```bash
kubectl patch application hotel-app -n argocd --type merge -p '{
  "spec": {
    "source": {
      "repoURL": "https://github.com/niridoy/k8s-gitops.git",
      "path": "sample-php/overlays/dev"
    }
  }
}'
```

## Update local git remote

```bash
git remote set-url origin https://github.com/niridoy/k8s-gitops.git
git remote -v
```

## CI in other repos

Use:

```yaml
GITOPS_REPO: niridoy/k8s-gitops
```
