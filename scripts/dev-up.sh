#!/usr/bin/env bash
set -euo pipefail

APP_ROOT="${APP_ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"
BACKEND_DIR="${BACKEND_DIR:-$APP_ROOT/backend}"
PHP_BIN="${PHP_BIN:-php}"
HOST="${HOST:-127.0.0.1}"
PORT="${PORT:-8000}"
WITH_RESET="${WITH_RESET:-false}"

if [[ "$WITH_RESET" == "true" ]]; then
  bash "$APP_ROOT/scripts/dev-reset.sh"
fi

echo "[dev-up] backend dir: $BACKEND_DIR"
echo "[dev-up] serving on http://$HOST:$PORT"
echo "[dev-up] health endpoint: http://$HOST:$PORT/api/health"

cd "$BACKEND_DIR"
"$PHP_BIN" artisan serve --host="$HOST" --port="$PORT"
