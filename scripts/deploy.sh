#!/usr/bin/env bash
set -euo pipefail

APP_ROOT="${APP_ROOT:-/var/www/promozone}"
BACKEND_DIR="${BACKEND_DIR:-$APP_ROOT/backend}"
PHP_BIN="${PHP_BIN:-php}"
COMPOSER_BIN="${COMPOSER_BIN:-composer}"
SEED_DEMO_DATA="${SEED_DEMO_DATA:-false}"
RUN_MIGRATIONS="${RUN_MIGRATIONS:-true}"
RESTART_SERVICES="${RESTART_SERVICES:-true}"
DRY_RUN="${DRY_RUN:-false}"

run_cmd() {
  echo "+ $*"
  if [[ "$DRY_RUN" != "true" ]]; then
    "$@"
  fi
}

echo "[deploy] app root: $APP_ROOT"
echo "[deploy] backend dir: $BACKEND_DIR"

cd "$BACKEND_DIR"

echo "[deploy] installing dependencies"
run_cmd "$COMPOSER_BIN" install --no-dev --optimize-autoloader --no-interaction --prefer-dist

if [[ "$RUN_MIGRATIONS" == "true" ]]; then
  echo "[deploy] running migrations"
  run_cmd "$PHP_BIN" artisan migrate --force
fi

if [[ "$SEED_DEMO_DATA" == "true" ]]; then
  echo "[deploy] seeding demo marketplace data"
  run_cmd "$PHP_BIN" artisan db:seed --class=PromoMarketplaceSeeder --force
fi

echo "[deploy] caching framework config"
run_cmd "$PHP_BIN" artisan optimize:clear
run_cmd "$PHP_BIN" artisan config:cache
run_cmd "$PHP_BIN" artisan route:cache
run_cmd "$PHP_BIN" artisan event:cache
run_cmd "$PHP_BIN" artisan view:cache

echo "[deploy] ensuring storage symlink exists"
if [[ "$DRY_RUN" == "true" ]]; then
  echo "+ $PHP_BIN artisan storage:link"
else
  "$PHP_BIN" artisan storage:link || true
fi

if [[ "$RESTART_SERVICES" == "true" ]]; then
  echo "[deploy] reloading php-fpm, nginx, and supervisor worker"
  if [[ "$DRY_RUN" == "true" ]]; then
    echo "+ sudo systemctl reload php8.2-fpm"
    echo "+ sudo systemctl reload nginx"
    echo "+ sudo supervisorctl reread"
    echo "+ sudo supervisorctl update"
    echo "+ sudo supervisorctl restart promozone-worker:*"
  else
    sudo systemctl reload php8.2-fpm || true
    sudo systemctl reload nginx || true
    sudo supervisorctl reread || true
    sudo supervisorctl update || true
    sudo supervisorctl restart promozone-worker:* || true
  fi
fi

echo "[deploy] running post-deploy checks"
if [[ "$DRY_RUN" == "true" ]]; then
  echo "+ bash $APP_ROOT/scripts/post-deploy-check.sh"
else
  bash "$APP_ROOT/scripts/post-deploy-check.sh"
fi

echo "[deploy] completed successfully"
