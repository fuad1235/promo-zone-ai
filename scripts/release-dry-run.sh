#!/usr/bin/env bash
set -euo pipefail

APP_ROOT="${APP_ROOT:-$(pwd)}"
BACKEND_DIR="${BACKEND_DIR:-$APP_ROOT/backend}"
API_BASE_URL="${API_BASE_URL:-http://127.0.0.1:8000}"

echo "[dry-run] flutter quality gate"
cd "$APP_ROOT"
flutter analyze
flutter test

echo "[dry-run] backend quality gate"
cd "$BACKEND_DIR"
php artisan test

echo "[dry-run] endpoint checks"
curl -fsS "$API_BASE_URL/up" >/dev/null
curl -fsS "$API_BASE_URL/api/health" >/dev/null
curl -fsS "$API_BASE_URL/api/ready" >/dev/null

echo "[dry-run] deployment command preview"
echo "DRY_RUN=true bash scripts/deploy.sh"

echo "[dry-run] completed successfully"
