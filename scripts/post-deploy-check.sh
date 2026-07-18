#!/usr/bin/env bash
set -euo pipefail

API_BASE_URL="${API_BASE_URL:-http://127.0.0.1}"
HEALTH_ENDPOINT="${HEALTH_ENDPOINT:-$API_BASE_URL/api/health}"
READY_ENDPOINT="${READY_ENDPOINT:-$API_BASE_URL/api/ready}"
UP_ENDPOINT="${UP_ENDPOINT:-$API_BASE_URL/up}"
SUPERVISOR_PROGRAM="${SUPERVISOR_PROGRAM:-promozone-worker:promozone-worker_00}"

echo "[check] probing $UP_ENDPOINT"
curl -fsS "$UP_ENDPOINT" >/dev/null
echo "[check] /up OK"

echo "[check] probing $HEALTH_ENDPOINT"
HEALTH_JSON="$(curl -fsS "$HEALTH_ENDPOINT")"
echo "[check] /api/health -> $HEALTH_JSON"

echo "[check] probing $READY_ENDPOINT"
READY_JSON="$(curl -fsS "$READY_ENDPOINT")"
echo "[check] /api/ready -> $READY_JSON"

if command -v supervisorctl >/dev/null 2>&1; then
  echo "[check] supervisor status"
  supervisorctl status "$SUPERVISOR_PROGRAM" || true
fi

echo "[check] done"
