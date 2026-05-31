#!/usr/bin/env bash
# Creates .dockerconfigjson for Kustomize from `docker login ghcr.io` or env vars.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
DOCKER_CONFIG="${DOCKER_CONFIG:-$HOME/.docker/config.json}"

write_from_docker_config() {
  local dest="$1"
  if [[ ! -f "$DOCKER_CONFIG" ]]; then
    echo "Missing $DOCKER_CONFIG — run: docker login ghcr.io" >&2
    exit 1
  fi
  cp "$DOCKER_CONFIG" "$dest"
  echo "Wrote $dest from $DOCKER_CONFIG"
}

write_from_env() {
  local dest="$1"
  : "${GHCR_USERNAME:?Set GHCR_USERNAME}"
  : "${GHCR_TOKEN:?Set GHCR_TOKEN (GitHub PAT with read:packages)}"
  local email="${GHCR_EMAIL:-${GHCR_USERNAME}@users.noreply.github.com}"
  local auth
  auth="$(printf '%s:%s' "$GHCR_USERNAME" "$GHCR_TOKEN" | base64 | tr -d '\n')"
  cat >"$dest" <<EOF
{
  "auths": {
    "ghcr.io": {
      "username": "${GHCR_USERNAME}",
      "password": "${GHCR_TOKEN}",
      "email": "${email}",
      "auth": "${auth}"
    }
  }
}
EOF
  echo "Wrote $dest from GHCR_USERNAME/GHCR_TOKEN"
}

for dir in "${ROOT}/components/ghcr-secret" "${ROOT}/components/ghcr-secret-hotel-app"; do
  dest="${dir}/.dockerconfigjson"
  if [[ -n "${GHCR_USERNAME:-}" && -n "${GHCR_TOKEN:-}" ]]; then
    write_from_env "$dest"
  else
    write_from_docker_config "$dest"
  fi
done

echo "Done. Apply any overlay, e.g.: kubectl apply -k user-service/overlays/dev"
