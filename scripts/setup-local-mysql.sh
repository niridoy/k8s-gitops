#!/usr/bin/env bash
# Start Docker MySQL and wire mysql.db.local for host + Minikube pods.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

if [[ -f .env ]]; then
  set -a
  # shellcheck disable=SC1091
  source .env
  set +a
fi

DB_USER="${DB_USER:-user}"
DB_PASSWORD="${DB_PASSWORD:-password}"
DB_NAME="${DB_NAME:-appdb}"
MYSQL_PORT="${MYSQL_PORT:-3306}"

detect_gateway_ip() {
  if [[ -n "${MYSQL_GATEWAY_IP:-}" ]]; then
    echo "$MYSQL_GATEWAY_IP"
    return
  fi
  if command -v minikube >/dev/null 2>&1 && minikube status >/dev/null 2>&1; then
    minikube ssh "getent hosts host.minikube.internal" 2>/dev/null | awk '{print $1}' && return
  fi
  ip -4 route show default 2>/dev/null | awk '{print $3; exit}'
}

echo "==> Starting MySQL..."
if docker ps -a --format '{{.Names}}' | grep -qx mysql; then
  docker start mysql >/dev/null 2>&1 || true
else
  docker compose up -d mysql
fi

echo "==> Waiting for MySQL to be healthy..."
until docker exec mysql mysqladmin ping -h 127.0.0.1 -u root -p"${DB_ROOT_PASSWORD:-rootpassword}" --silent 2>/dev/null; do
  sleep 2
done

GATEWAY_IP="$(detect_gateway_ip)"
if [[ -z "$GATEWAY_IP" ]]; then
  echo "Could not detect MYSQL_GATEWAY_IP. Set it in .env or local-dev/gateway.env" >&2
  exit 1
fi

mkdir -p local-dev
echo "MYSQL_GATEWAY_IP=${GATEWAY_IP}" > local-dev/gateway.env
echo "MYSQL_GATEWAY_IP=${GATEWAY_IP}" > user-service/overlays/dev/gateway.env
echo "MYSQL_GATEWAY_IP=${GATEWAY_IP}" > product-service/overlays/dev/gateway.env
echo "Wrote gateway.env files (Minikube host gateway: ${GATEWAY_IP})"

if grep -q "mysql.db.local" /etc/hosts 2>/dev/null; then
  echo "==> /etc/hosts already has mysql.db.local"
else
  echo "==> Add to /etc/hosts (sudo): 127.0.0.1 mysql.db.local"
  echo "127.0.0.1 mysql.db.local" | sudo tee -a /etc/hosts >/dev/null || {
    echo "Skipped /etc/hosts (no sudo). Add manually: 127.0.0.1 mysql.db.local"
  }
fi

echo "==> Applying Kubernetes Service mysql → host:${MYSQL_PORT} (gateway ${GATEWAY_IP})..."
sed "s/PLACEHOLDER_GATEWAY_IP/${GATEWAY_IP}/" local-dev/mysql-external.yaml | kubectl apply -f -

echo ""
echo "Local MySQL ready."
echo "  Host machine:  mysql.db.local:${MYSQL_PORT}  (127.0.0.1)"
echo "  Inside pods:   mysql.db.local:3306  (via hostAliases) or mysql:3306 (Service)"
echo "  Credentials:   ${DB_USER} / ${DB_PASSWORD}  database: ${DB_NAME}"
echo ""
echo "Redeploy dev services: kubectl apply -k user-service/overlays/dev && kubectl apply -k product-service/overlays/dev"
