# Judge guide

This is the shortest path to run and evaluate Promo Zone AI locally.

## What to evaluate

The two Build Week features are:

1. **Campaign Architect** for authenticated business users.
2. **Creator Coach** for authenticated creator users.

Both use the OpenAI Responses API with `gpt-5.6` and strict JSON-schema output.
The Laravel server—not Flutter—holds the key and trusted context.

## Prerequisites

- PHP 8.2+ and Composer
- Flutter 3.44+ and Dart 3.12+
- Android emulator/device
- OpenAI API key with GPT-5.6 access

## Start Laravel

```bash
cd backend
composer install
cp .env.example .env
touch database/database.sqlite
php artisan key:generate
```

Add the key only to ignored `backend/.env`:

```dotenv
OPENAI_API_KEY=your_server_side_key
OPENAI_MODEL=gpt-5.6
```

Seed and start:

```bash
php artisan migrate:fresh --seed
php artisan serve --no-reload
```

Check:

```bash
curl http://127.0.0.1:8000/api/health
curl http://127.0.0.1:8000/api/ready
```

Expected: `status` is `ok` and `ready`.

## Start Flutter

```bash
flutter pub get
adb reverse tcp:8000 tcp:8000
flutter run --dart-define=LARAVEL_API_BASE_URL=http://127.0.0.1:8000
```

Release builds require an HTTPS API URL. HTTP localhost is accepted in debug
builds for development.

## Demo 1: Campaign Architect

Login:

```text
sparkbrew@promozone.test
Password@123
```

Navigate: **Work → Create → Build brief with GPT-5.6**

Suggested input:

```text
Product: Spark Brew Mango Rush
Facts: A mango-flavoured energy drink for busy young adults. Show the can
clearly and do not make medical or guaranteed-performance claims.
Audience: Ghanaian university students and young professionals
Goal: Drive authentic first trial and product recall
Platform: TikTok
Tone: Energetic, credible, and playful
Mention: @sparkbrewgh
```

Expected:

- GPT-5.6 fills an editable campaign title and description.
- The screen displays hashtags, guardrails, ideal creator, success signal, and
  three different content angles.
- Target views, payout, creator count, platform, and mention remain the
  business's values.
- Nothing is published until the business reviews and submits the normal form.

## Demo 2: Creator Coach

Login:

```text
ama.creator@promozone.test
Password@123
```

Navigate: **Browse → any published campaign → Creator Coach → Coach my draft**

Suggested deliberately imperfect draft:

```text
This serum cures every breakout overnight. Watch my quick night routine before
bed—no filters, just my first reaction.
```

Expected:

- GPT-5.6 scores the draft and labels it ready/revise/off-brief.
- The result cites campaign requirements through a met/partial/missing
  checklist.
- Unsupported claims appear in risk flags.
- Missing mentions/hashtags appear as missing requirements.
- The result provides a better hook, revised draft, and shot list.
- The screen states that coaching is not approval.

## Direct API check

Get a business token:

```bash
curl -sS http://127.0.0.1:8000/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"sparkbrew@promozone.test","password":"Password@123"}'
```

Copy the returned `token`, then:

```bash
curl -sS http://127.0.0.1:8000/api/ai/campaign-brief \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "productName":"Spark Brew Mango Rush",
    "productDescription":"A mango-flavoured energy drink for busy young adults.",
    "audience":"Ghanaian university students and young professionals",
    "campaignGoal":"Drive authentic trial and product recall",
    "platform":"TikTok",
    "tone":"Energetic, credible, and playful",
    "targetViews":180000,
    "payoutAmountGhs":420,
    "creatorsNeeded":12,
    "brandMention":"@sparkbrewgh"
  }'
```

The full contract is in `backend/docs/openapi.yaml`.

## Tests

```bash
flutter analyze
flutter test
```

Expected: no analyzer issues and 8 passing tests.

```bash
cd backend
php artisan test
./vendor/bin/pint --test
```

Expected: 15 passing tests / 70 assertions and clean Laravel formatting.

## APK

Public product and Android release:

```text
Product: https://promozone.boldtechai.com
Release: https://github.com/fuad1235/promo-zone-ai/releases/tag/v1.0.0-build-week
APK: https://github.com/fuad1235/promo-zone-ai/releases/download/v1.0.0-build-week/Promo-Zone-AI-Android-e84350e.apk
```

Matching production-targeted local artifact (ignored from Git):

```text
artifacts/Promo-Zone-AI-Android-e84350e.apk
```

Rebuilt July 19, 2026 at 21:13:02 UTC:

```text
Size: 56,496,807 bytes
SHA-256: 648a2c374fbff4ae51c67d9eed6b2d337bd3b0ae4b976b441c0bf3ad02afb672
API base URL: https://promozone.boldtechai.com
API timeout: 60,000 milliseconds
Application label: Promo Zone AI
Android: minimum SDK 24, target SDK 36
Architectures: armeabi-v7a, arm64-v8a, x86_64
Manifest: usesCleartextTraffic=false
Signature: verified with APK Signature Scheme v2
```

This direct-install Android build falls back to the local Android debug
certificate because no production upload keystore is present. It contains the
complete app and is suitable for direct testing, but not for Play Store
publication.

This exact APK was installed on an API 36.1 x86_64 emulator. It cold-launched
successfully, loaded live production campaigns, and returned a complete
Campaign Architect result from GPT-5.6 without the earlier 12-second client
timeout.

Reproduce it with:

```bash
flutter build apk --release \
  --dart-define=LARAVEL_API_BASE_URL=https://promozone.boldtechai.com \
  --dart-define=API_TIMEOUT_MS=60000
```

The GPT-5.6 backend overlay is deployed, both live AI flows pass, and the
artifact is publicly available. For local emulator evaluation, use a debug
build with `http://127.0.0.1:8000` plus `adb reverse`.

## Troubleshooting

- **AI features are not configured**: set `OPENAI_API_KEY` in `backend/.env`,
  then run `php artisan config:clear`.
- **Android cannot reach localhost**: run
  `adb reverse tcp:8000 tcp:8000`.
- **Campaign list shows an old connection error**: restart the debug app after
  starting Laravel; providers reload on process start.
- **Release refuses HTTP**: deploy Laravel behind HTTPS and rebuild with that
  base URL.
- **Wrong role**: Campaign Architect requires a business token; Creator Coach
  requires a creator token.
