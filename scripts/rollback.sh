#!/usr/bin/env bash
set -euo pipefail

APP_ROOT="${APP_ROOT:-/var/www/promozone}"
BACKEND_DIR="${BACKEND_DIR:-$APP_ROOT/backend}"
PHP_BIN="${PHP_BIN:-php}"
RUN_MIGRATE_ROLLBACK="${RUN_MIGRATE_ROLLBACK:-false}"
ROLLBACK_STEPS="${ROLLBACK_STEPS:-1}"

cd "$BACKEND_DIR"

echo "[rollback] clearing runtime caches"
"$PHP_BIN" artisan optimize:clear

if [[ "$RUN_MIGRATE_ROLLBACK" == "true" ]]; then
  echo "[rollback] running migrate:rollback --step=$ROLLBACK_STEPS"
  "$PHP_BIN" artisan migrate:rollback --step="$ROLLBACK_STEPS" --force
fi

echo "[rollback] rebuilding safe runtime caches"
"$PHP_BIN" artisan config:cache
"$PHP_BIN" artisan route:cache
"$PHP_BIN" artisan event:cache

echo "[rollback] verify endpoints"
curl -fsS "${API_BASE_URL:-http://127.0.0.1}/up" >/dev/null
curl -fsS "${API_BASE_URL:-http://127.0.0.1}/api/health" >/dev/null
curl -fsS "${API_BASE_URL:-http://127.0.0.1}/api/ready" >/dev/null

echo "[rollback] completed"
