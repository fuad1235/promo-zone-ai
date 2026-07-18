# cPanel SSH Deployment Checklist

Target API URL:

- `https://promozone.boldtechai.com`

The production probe on July 18, 2026 confirmed that the API is mounted at the
domain root. Do not append the legacy `/promozone` suffix.

Assumptions:

- You can SSH into cPanel host.
- Laravel project root is available (adjust path below).

## 1. SSH and go to project

```bash
ssh <cpanel-user>@<cpanel-host>
cd ~/public_html/promozone
```

If your Laravel app is in another folder, use that folder instead.

## 2. Pull/upload latest backend code

If Git is used:

```bash
git pull origin main
```

If not using Git, upload changed files from `backend/` into your Laravel app structure.

## 3. Install PHP dependencies

```bash
composer install --no-dev --optimize-autoloader
```

## 4. Configure `.env`

Confirm these keys exist:

```env
APP_ENV=production
APP_DEBUG=false
APP_URL=https://promozone.boldtechai.com

DB_CONNECTION=mysql
DB_HOST=...
DB_PORT=3306
DB_DATABASE=...
DB_USERNAME=...
DB_PASSWORD=...
```

## 5. Run migrations

```bash
php artisan migrate --force
```

This applies new columns including `users.api_token`.

## 6. Enable public uploads URL

```bash
php artisan storage:link
```

## 7. Clear/cache config and routes

```bash
php artisan optimize:clear
php artisan config:cache
php artisan route:cache
```

## 8. Verify middleware aliases

- For Laravel 10: `app/Http/Kernel.php`
- For Laravel 11: `bootstrap/app.php`

Use snippets from `backend/docs/kernel_middleware_snippets.md`:

- `api.auth` => `AuthenticateApiToken`
- `role` => `EnsureRole`

## 9. Smoke test API by curl

```bash
curl -i -X POST "https://promozone.boldtechai.com/api/auth/register" \
  -H "Content-Type: application/json" \
  -d '{"email":"test1@example.com","password":"secret123"}'
```

Expected: `201` with JSON containing `token` and `user`.

Then:

```bash
TOKEN="<paste_token_here>"
curl -i "https://promozone.boldtechai.com/api/auth/me" \
  -H "Authorization: Bearer ${TOKEN}" \
  -H "Accept: application/json"
```

Expected: `200` with current user.

## 10. Flutter app run/build flags

Local run:

```bash
flutter run --dart-define=LARAVEL_API_BASE_URL=https://promozone.boldtechai.com
```

Android release:

```bash
flutter build apk --release \
  --dart-define=LARAVEL_API_BASE_URL=https://promozone.boldtechai.com
```

## 11. Post-deploy validation flow

1. Register new user in app.
2. Login succeeds and persists session after app restart.
3. Onboarding saves role/profile via `/api/auth/sync-profile`.
4. Business can create campaign, deposit, approve applicant.
5. Creator can apply, submit sample/proof, wallet reflects updates.
6. Media uploads return URL from `/api/uploads` and render in app.
