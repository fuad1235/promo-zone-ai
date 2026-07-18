#!/usr/bin/env bash
set -euo pipefail

APP_ROOT="${APP_ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"
BACKEND_DIR="${BACKEND_DIR:-$APP_ROOT/backend}"
PHP_BIN="${PHP_BIN:-php}"
SEED_CLASS="${SEED_CLASS:-PromoMarketplaceSeeder}"

echo "[dev-reset] backend dir: $BACKEND_DIR"
cd "$BACKEND_DIR"

echo "[dev-reset] clearing caches"
"$PHP_BIN" artisan optimize:clear

echo "[dev-reset] rebuilding schema and seeding sample data"
"$PHP_BIN" artisan migrate:fresh --seed --seeder="$SEED_CLASS"

echo "[dev-reset] done"
