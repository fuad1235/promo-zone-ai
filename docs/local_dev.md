# Local Development Workflow

This guide is for fast local iteration only (not production).

## 1. Reset DB + Seed Demo Data

```bash
bash scripts/dev-reset.sh
```

PowerShell:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\dev-reset.ps1
```

What it does:
- clears Laravel caches
- rebuilds DB schema (`migrate:fresh`)
- seeds sample promo products/gigs (`PromoMarketplaceSeeder`)

Seeded Build Week accounts all use `Password@123`:

- business: `sparkbrew@promozone.test`
- creator: `ama.creator@promozone.test`

## 1.1 Configure GPT-5.6

Add the key to ignored `backend/.env`; never put it in a Flutter define:

```dotenv
OPENAI_API_KEY=your_server_side_key
OPENAI_MODEL=gpt-5.6
```

After changing it:

```bash
cd backend
php artisan config:clear
```

Without a key, normal marketplace flows still work and AI endpoints return a
safe `503` configuration message.

## 2. Start Backend

```bash
bash scripts/dev-up.sh
```

PowerShell:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\dev-up.ps1
```

Options:

```bash
WITH_RESET=true bash scripts/dev-up.sh
HOST=0.0.0.0 PORT=8000 bash scripts/dev-up.sh
```

## 3. Run App on Android Device

```bash
bash scripts/dev-run-android.sh
```

PowerShell:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\dev-run-android.ps1
```

What it does:
- configures `adb reverse` when API URL is localhost
- runs Flutter with:
  - `LARAVEL_API_BASE_URL`
  - verbose API logs enabled by default
  - a 60-second API timeout by default, which allows GPT-5.6 requests to
    complete within the backend's configured processing window
  - retry dart defines

Useful overrides:

```bash
DEVICE_ID=your_device_id bash scripts/dev-run-android.sh
API_BASE_URL=http://192.168.8.14:8000 bash scripts/dev-run-android.sh
ENABLE_VERBOSE_API_LOGS=false bash scripts/dev-run-android.sh
```

## 4. Quick Diagnostics

```bash
bash scripts/dev-check.sh
```

PowerShell:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\dev-check.ps1
```

This checks:
- backend `/api/health`
- adb device list
- adb reverse mappings

## 5. Build Week demo paths

- Business: Work → Create → Build brief with GPT-5.6.
- Creator: Browse → campaign → Creator Coach → Coach my draft.

For the full expected output and troubleshooting, see
`docs/build-week/JUDGE_GUIDE.md`.
