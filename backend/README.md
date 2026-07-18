# Promo Zone Laravel + MySQL Blueprint

This folder contains a production-oriented backend blueprint to replace Firebase progressively.

## What is included

- MySQL migrations for all core entities:
  - `users`, `creator_profiles`, `creator_handles`, `business_profiles`
  - `campaigns`, campaign media/hashtags
  - `applications`, `submissions`
  - `wallets`, `wallet_ledger`, `holds`, `withdraw_requests`
- Transactional ledger service:
  - `depositCredits`
  - `approveCreator` (creates hold)
  - `approveProof` (releases hold + payout)
  - `refundHold`
- State machine service for application transitions
- API controllers/routes for campaigns, applications, submissions, wallet actions
- Token-based auth middleware + onboarding profile sync endpoint
- OpenAPI contract at `backend/docs/openapi.yaml`

## Laravel setup steps

1. Create Laravel app (Laravel 11+), copy these files into it.
2. Register/login uses backend-issued API token (`/api/auth/register`, `/api/auth/login`).
3. Ensure API routing + middleware aliases are configured in `bootstrap/app.php`:
   - `api: __DIR__.'/../routes/api.php'`
   - `'api.auth' => \App\Http\Middleware\AuthenticateApiToken::class`
   - `'role' => \App\Http\Middleware\EnsureRole::class`
4. Configure MySQL in `.env`.
5. Run migrations:
   - `php artisan migrate`
6. Serve API:
   - `php artisan serve`
7. Enable public uploads:
   - `php artisan storage:link`

## Data integrity rules in this design

- Wallet operations are server-only and transactional.
- `lockForUpdate()` is used on wallets/holds/applications to prevent race conditions.
- App status transitions are checked with a state machine.
- Hold lifecycle states are explicit: `active -> released|refunded`.

## Flutter migration path (incremental)

1. Login/register from Flutter against Laravel API and store bearer token locally.
2. Call `POST /api/auth/sync-profile` after onboarding completion (implemented in Flutter `AuthRepository`).
3. Replace these services one-by-one in Flutter:
   - `callable_service.dart` -> REST `POST /approve`, `POST /approve-proof`, `POST /deposit`, `POST /holds/refund`
   - campaign/application/submission repositories -> REST endpoints
4. Upload media through `/api/uploads` (implemented for Flutter `StorageService`).

## Recommended next additions

- Policy classes for campaign/application ownership checks.
- Full FormRequest classes per endpoint.
- Idempotency keys for payment/ledger endpoints.
- Queue workers for payout processing and webhooks.
- Feature tests for all state transitions and ledger invariants.

## Deployment Aids

- cPanel SSH checklist: `backend/docs/cpanel_deployment_checklist.md`
- Middleware alias snippets: `backend/docs/kernel_middleware_snippets.md`
- Production env template: `backend/.env.production.example`
- Release runbook: `docs/release_runbook.md`
- Demo data seeder: `php artisan db:seed --class=PromoMarketplaceSeeder`
- Nginx config template: `deploy/nginx/promozone.conf`
- Supervisor worker template: `deploy/supervisor/promozone-worker.conf`
- One-command deploy script: `scripts/deploy.sh`

## Production hardening knobs

- `API_RATE_LIMIT_PER_MINUTE` (default `120`)
- `AUTH_RATE_LIMIT_PER_MINUTE` (default `20`)
- `API_TOKEN_TTL_MINUTES` (default `43200`, 30 days)
- `CORS_ALLOWED_ORIGINS` (comma-separated, use explicit domains in production)
- `IDEMPOTENCY_ENABLED`, `IDEMPOTENCY_TTL_SECONDS`, `IDEMPOTENCY_PROCESSING_LOCK_SECONDS`
- Logs now include request context (`request_id`) and apply sensitive-key redaction.
- API adds security response headers and an app readiness probe at `/api/ready`.
- Financial write endpoints support `Idempotency-Key` replay protection.

## Ops scripts (repo root `scripts/`)

- `release-dry-run.sh`: analyze/test + backend test + endpoint readiness checks
- `load-smoke.sh` / `load-smoke.ps1`: quick HTTP smoke load for `/up`, `/api/health`, `/api/ready`, `/api/campaigns`
- `db-backup.sh` / `db-backup.ps1`: MySQL backup
- `db-restore.sh` / `db-restore.ps1`: MySQL restore
- `rollback.sh`: cache-safe rollback helper with optional `migrate:rollback`
