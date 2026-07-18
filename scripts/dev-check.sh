#!/usr/bin/env bash
set -euo pipefail

API_BASE_URL="${API_BASE_URL:-http://127.0.0.1:8000}"
ADB_DEVICE_ID="${ADB_DEVICE_ID:-9ebc65d2}"
ADB_BIN="${ADB_BIN:-adb}"

echo "[dev-check] API base: $API_BASE_URL"
echo "[dev-check] backend health:"
curl -fsS "$API_BASE_URL/api/health" || {
  echo "[dev-check] backend health check failed"
  exit 1
}
echo

if command -v "$ADB_BIN" >/dev/null 2>&1; then
  echo "[dev-check] adb devices:"
  "$ADB_BIN" devices
  echo "[dev-check] adb reverse list for $ADB_DEVICE_ID:"
  "$ADB_BIN" -s "$ADB_DEVICE_ID" reverse --list || true
else
  echo "[dev-check] adb not found in PATH"
fi

echo "[dev-check] done"
