# Promo Zone

Production-grade Flutter MVP for a creator-business promo marketplace with escrow-like credit holds, creator workflow approvals, proof submissions, and ledger-backed wallet accounting.

## Stack

- Flutter stable, Dart 3+
- Material 3 UI
- Riverpod (state)
- GoRouter (navigation)
- Laravel API + MySQL (token auth, campaigns, submissions, wallet/ledger)
- Laravel uploads endpoint for media files

## Project Structure

- `lib/main.dart`
- `lib/app/router.dart`
- `lib/features/auth/`
- `lib/features/creator/`
- `lib/features/business/`
- `lib/features/campaigns/`
- `lib/features/wallet/`
- `lib/common/widgets/`
- `lib/common/services/`
- `functions/` (TypeScript Cloud Functions)
- `firestore.rules`
- `firestore.indexes.json`

## Firebase Setup

1. Create a Firebase project.
2. Enable:
   - Authentication (Email/Password)
   - Cloud Firestore
   - Cloud Storage
   - Cloud Functions
3. Configure Flutter app IDs for Android and iOS.
4. Run (recommended):
   - `flutterfire configure`
5. Deploy rules/indexes:
   - `firebase deploy --only firestore:rules,firestore:indexes`
6. Deploy functions:
   - `cd functions && npm install && npm run build && firebase deploy --only functions`

## Run App

1. `flutter pub get`
2. Run with Laravel base URL:
   - `flutter run --dart-define=LARAVEL_API_BASE_URL=https://your-api-host`
   - Optional hardening flags:
     - `--dart-define=API_TIMEOUT_MS=12000`
     - `--dart-define=API_RETRY_COUNT=2`
     - `--dart-define=API_RETRY_NON_IDEMPOTENT=false`
     - `--dart-define=ENABLE_VERBOSE_API_LOGS=false`
   - Note: release builds now enforce `https://` API URLs.
3. Ensure backend token auth middleware is configured (see `backend/README.md`).

## Android Release Signing

1. Generate keystore (one-time):
   - `keytool -genkey -v -keystore C:\Users\Fuad\upload-keystore.jks -alias upload -keyalg RSA -keysize 2048 -validity 10000`
2. Copy `android/key.properties.example` to `android/key.properties` and set real values.
3. Build signed artifact:
   - APK: `flutter build apk --release --dart-define=LARAVEL_API_BASE_URL=https://api.your-domain.com`
   - AAB: `flutter build appbundle --release --dart-define=LARAVEL_API_BASE_URL=https://api.your-domain.com`

## Local Dev Shortcuts

- Local dev guide: `docs/local_dev.md`
- Reset DB + seed demo: `bash scripts/dev-reset.sh`
- Start backend: `bash scripts/dev-up.sh`
- Run on Android (with adb reverse + debug defines): `bash scripts/dev-run-android.sh`
- Quick health/adb diagnostics: `bash scripts/dev-check.sh`
- PowerShell equivalents:
  - `powershell -ExecutionPolicy Bypass -File .\scripts\dev-reset.ps1`
  - `powershell -ExecutionPolicy Bypass -File .\scripts\dev-up.ps1`
  - `powershell -ExecutionPolicy Bypass -File .\scripts\dev-run-android.ps1`
  - `powershell -ExecutionPolicy Bypass -File .\scripts\dev-check.ps1`

## Production Baseline

- CI workflow: `.github/workflows/ci.yml`
  - Flutter: `analyze` + `test`
  - Laravel: `composer validate --strict` + `artisan test`
- Release runbook: `docs/release_runbook.md`
- Backend production env template: `backend/.env.production.example`
- Readiness endpoint: `/api/ready` (DB + cache probe)
- Demo marketplace data seeder: `backend/database/seeders/PromoMarketplaceSeeder.php`
- Native deploy configs:
  - `deploy/nginx/promozone.conf`
  - `deploy/supervisor/promozone-worker.conf`
  - `scripts/deploy.sh`
  - `scripts/post-deploy-check.sh`
  - `scripts/release-dry-run.sh`
  - `scripts/load-smoke.sh`
  - `scripts/rollback.sh`
  - `scripts/db-backup.sh`
  - `scripts/db-restore.sh`

## Test

- `flutter test`

Included tests:
- status transition validation (`test/common/status_transition_test.dart`)
- campaign repository persistence (`test/features/campaign_repository_test.dart`)
- campaign list widget (`test/features/campaign_list_widget_test.dart`)

## Core Workflow

1. User registers, selects role, completes onboarding.
2. Business creates + publishes campaign.
3. Creator applies.
4. Business approves creator via Laravel API `/api/campaigns/{campaignId}/applications/{applicationId}/approve`.
   - Server checks wallet balance.
   - Server creates active hold and ledger entries.
5. Creator submits sample -> business approves/rejects.
6. Creator marks posted, submits proof.
7. Business approves proof via Laravel API `/api/campaigns/{campaignId}/applications/{applicationId}/approve-proof`.
   - Server validates status + proof + view target.
   - Server releases hold and posts payout to creator wallet.
8. Optional refund via Laravel API `/api/holds/refund`.

## Security Notes

- Wallet + ledger client writes are blocked in `firestore.rules`.
- Holds are server-managed only.
- State machine validation exists in app UX (`StatusMachine`) and should be fully enforced by functions.
- For production hardening, add stricter rules for each allowed status transition payload and immutable field checks.

## Firestore Index Notes

Configured in `firestore.indexes.json`:
- `campaigns`: `status + platform + payoutAmountGhs`
- `applications`: `creatorId + status`
- `applications`: `businessId + campaignId + status`

## Test Account Flow

- Business account:
  - Register -> choose Business -> onboarding -> create campaign -> deposit credits -> approve applicants.
- Creator account:
  - Register -> choose Creator -> onboarding -> apply -> submit sample/proof.

## Payments TODO (Intentional MVP Boundary)

- Real payout integrations (MoMo API/webhooks) are not implemented.
- Creator withdraw flow records `withdrawRequests` only.
- Settlement remains simulated through ledger + hold mechanics.
