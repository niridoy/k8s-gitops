#!/usr/bin/env bash
# Creates ghcr-secret in the cluster (works with kubectl apply and Argo CD).
set -euo pipefail

create_secret() {
  local namespace="$1"
  local ns_flag=()
  if [[ -n "$namespace" ]]; then
    ns_flag=(--namespace "$namespace")
  fi

  if [[ -n "${GHCR_USERNAME:-}" && -n "${GHCR_TOKEN:-}" ]]; then
    kubectl create secret docker-registry ghcr-secret \
      --docker-server=ghcr.io \
      --docker-username="${GHCR_USERNAME}" \
      --docker-password="${GHCR_TOKEN}" \
      --docker-email="${GHCR_EMAIL:-${GHCR_USERNAME}@users.noreply.github.com}" \
      "${ns_flag[@]}" \
      --dry-run=client -o yaml | kubectl apply -f -
  elif [[ -f "${DOCKER_CONFIG:-$HOME/.docker/config.json}" ]]; then
    kubectl create secret generic ghcr-secret \
      --from-file=.dockerconfigjson="${DOCKER_CONFIG:-$HOME/.docker/config.json}" \
      --type=kubernetes.io/dockerconfigjson \
      "${ns_flag[@]}" \
      --dry-run=client -o yaml | kubectl apply -f -
  else
    echo "Run: docker login ghcr.io   OR set GHCR_USERNAME and GHCR_TOKEN" >&2
    exit 1
  fi
  echo "ghcr-secret ready in namespace: ${namespace:-default}"
}

create_secret ""
create_secret "hotel-app"

echo "Done. Deploy with kubectl or Argo CD (repo: https://github.com/niridoy/k8s-gitops.git)."
