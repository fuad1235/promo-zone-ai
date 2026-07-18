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

Expected: no analyzer issues and 7 passing tests.

```bash
cd backend
php artisan test
./vendor/bin/pint --test
```

Expected: 15 passing tests / 70 assertions and clean Laravel formatting.

## APK

Production-targeted local handoff artifact (ignored from Git; upload it to the
public test-build URL before submission):

```text
artifacts/Promo-Zone-AI-Android-e84350e.apk
```

Built July 18, 2026 at 12:08:57 UTC:

```text
Size: 56,497,051 bytes
SHA-256: 6dc8b83fc8eb32017705305cc38dba1ad35a3c768db0f106895dd0c8416651b8
API base URL: https://promozone.boldtechai.com
Application label: Promo Zone AI
Android: minimum SDK 24, target SDK 36
Manifest: usesCleartextTraffic=false
Signature: verified with APK Signature Scheme v2
```

This direct-install judge build falls back to the local Android debug
certificate because no production upload keystore is present. It is suitable
for an APK test link, but not for Play Store publication.

Reproduce it with:

```bash
flutter build apk --release \
  --dart-define=LARAVEL_API_BASE_URL=https://promozone.boldtechai.com
```

Do not publish the artifact until the GPT-5.6 backend overlay is deployed and
both live AI flows pass. For local emulator evaluation, use a debug build with
`http://127.0.0.1:8000` plus `adb reverse`.

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
