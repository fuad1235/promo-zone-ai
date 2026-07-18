# PromoZone Release Runbook

## 1. Pre-Release Gate

Run these checks locally:

```bash
flutter pub get
flutter analyze
flutter test
```

```bash
cd backend
composer install
php artisan test
./vendor/bin/pint --test
```

All commands must pass before cutting a release.

## 2. Backend Environment

1. Copy `backend/.env.production.example` to `.env`.
2. Set:
   - `APP_ENV=production`
   - `APP_DEBUG=false`
   - strong DB credentials
   - production SMTP credentials
   - restrictive `CORS_ALLOWED_ORIGINS` (no wildcard)
   - `API_TOKEN_TTL_MINUTES` per your security policy
3. Generate app key if missing:

```bash
php artisan key:generate --force
```

## 3. Backend Deploy

```bash
cd backend
composer install --no-dev --optimize-autoloader
php artisan migrate --force
php artisan db:seed --class=PromoMarketplaceSeeder --force
php artisan config:cache
php artisan route:cache
php artisan event:cache
php artisan storage:link
```

Health checks:

```bash
curl -sS https://api.promozone.example/up
curl -sS https://api.promozone.example/api/health
curl -sS https://api.promozone.example/api/ready
```

`/api/health` must return JSON with `status: "ok"`.
`/api/ready` must return HTTP 200 with `status: "ready"`.

### Native Nginx + Supervisor Setup (No Docker)

Install configs:

```bash
sudo cp deploy/nginx/promozone.conf /etc/nginx/sites-available/promozone.conf
sudo ln -sf /etc/nginx/sites-available/promozone.conf /etc/nginx/sites-enabled/promozone.conf
sudo cp deploy/supervisor/promozone-worker.conf /etc/supervisor/conf.d/promozone-worker.conf
```

Reload daemons:

```bash
sudo nginx -t
sudo systemctl reload nginx
sudo supervisorctl reread
sudo supervisorctl update
sudo supervisorctl restart promozone-worker:*
```

One-command deploy from repo root:

```bash
bash scripts/deploy.sh
```

Useful flags:

```bash
SEED_DEMO_DATA=true bash scripts/deploy.sh
API_BASE_URL=https://api.promozone.example bash scripts/post-deploy-check.sh
DRY_RUN=true bash scripts/deploy.sh
```

## 3.1 Release Dry-Run (Required)

Run full preflight against a staging or local environment:

```bash
API_BASE_URL=https://api.promozone.example bash scripts/release-dry-run.sh
```

PowerShell:

```powershell
$env:API_BASE_URL="https://api.promozone.example"
powershell -ExecutionPolicy Bypass -File .\scripts\release-dry-run.ps1
```

## 3.2 Smoke Load Check

Quick latency and availability pass:

```bash
API_BASE_URL=https://api.promozone.example ITERATIONS=40 bash scripts/load-smoke.sh
```

PowerShell:

```powershell
$env:API_BASE_URL="https://api.promozone.example"
$env:ITERATIONS="40"
powershell -ExecutionPolicy Bypass -File .\scripts\load-smoke.ps1
```

## 4. Android Device QA (USB)

Keep backend running and tunnel local API:

```bash
adb -s <device_id> reverse --remove-all
adb -s <device_id> reverse tcp:8000 tcp:8000
```

Launch app:

```bash
flutter run -d <device_id> --dart-define=LARAVEL_API_BASE_URL=http://127.0.0.1:8000
```

Smoke test flow:

1. App opens at Home campaign list.
2. Campaign details open from list.
3. Register/login works.
4. Creator can apply to a campaign.
5. Business can review applications.

## 5. Rollback

1. Keep prior release artifact available.
2. Re-point traffic to previous backend build.
3. Run:

```bash
php artisan config:clear
php artisan route:clear
php artisan event:clear
```

4. Validate `/up`, `/api/health`, and `/api/ready`.

Automated rollback helper:

```bash
API_BASE_URL=https://api.promozone.example bash scripts/rollback.sh
```

PowerShell:

```powershell
$env:API_BASE_URL="https://api.promozone.example"
powershell -ExecutionPolicy Bypass -File .\scripts\rollback.ps1
```

Optional DB rollback step:

```bash
RUN_MIGRATE_ROLLBACK=true ROLLBACK_STEPS=1 API_BASE_URL=https://api.promozone.example bash scripts/rollback.sh
```

## 6. Backup and Restore

Database backup:

```bash
DB_HOST=127.0.0.1 DB_PORT=3306 DB_NAME=promozone DB_USER=promozone_user DB_PASSWORD=... bash scripts/db-backup.sh
```

Database restore:

```bash
DB_HOST=127.0.0.1 DB_PORT=3306 DB_NAME=promozone DB_USER=promozone_user DB_PASSWORD=... bash scripts/db-restore.sh ./backups/promozone_YYYYMMDD_HHMMSS.sql.gz
```
