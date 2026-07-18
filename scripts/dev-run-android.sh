#!/usr/bin/env bash
set -euo pipefail

APP_ROOT="${APP_ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"
DEVICE_ID="${DEVICE_ID:-9ebc65d2}"
API_BASE_URL="${API_BASE_URL:-http://127.0.0.1:8000}"
ENABLE_VERBOSE_API_LOGS="${ENABLE_VERBOSE_API_LOGS:-true}"
API_TIMEOUT_MS="${API_TIMEOUT_MS:-12000}"
API_RETRY_COUNT="${API_RETRY_COUNT:-2}"
API_RETRY_NON_IDEMPOTENT="${API_RETRY_NON_IDEMPOTENT:-false}"
FLUTTER_BIN="${FLUTTER_BIN:-flutter}"
ADB_BIN="${ADB_BIN:-adb}"

echo "[dev-run-android] device: $DEVICE_ID"
echo "[dev-run-android] api: $API_BASE_URL"

if [[ "$API_BASE_URL" == "http://127.0.0.1:8000" || "$API_BASE_URL" == "http://localhost:8000" ]]; then
  echo "[dev-run-android] configuring adb reverse tcp:8000 -> tcp:8000"
  "$ADB_BIN" -s "$DEVICE_ID" reverse --remove-all || true
  "$ADB_BIN" -s "$DEVICE_ID" reverse tcp:8000 tcp:8000
  "$ADB_BIN" -s "$DEVICE_ID" reverse --list
fi

cd "$APP_ROOT"
"$FLUTTER_BIN" run -d "$DEVICE_ID" \
  --dart-define="LARAVEL_API_BASE_URL=$API_BASE_URL" \
  --dart-define="ENABLE_VERBOSE_API_LOGS=$ENABLE_VERBOSE_API_LOGS" \
  --dart-define="API_TIMEOUT_MS=$API_TIMEOUT_MS" \
  --dart-define="API_RETRY_COUNT=$API_RETRY_COUNT" \
  --dart-define="API_RETRY_NON_IDEMPOTENT=$API_RETRY_NON_IDEMPOTENT"
