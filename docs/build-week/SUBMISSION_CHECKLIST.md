# Build Week submission checklist

Official deadline: **July 21, 2026 at 5:00 PM PDT**  
UTC equivalent: **July 22, 2026 at 00:00 UTC**

Verify the deadline and final requirements on the
[official Devpost page](https://openai.devpost.com/) before submitting.

## Implemented

- [x] Existing project baseline disclosed before product changes.
- [x] Timestamped baseline fingerprint and commit.
- [x] Meaningful GPT-5.6 Campaign Architect workflow.
- [x] Meaningful GPT-5.6 Creator Coach workflow.
- [x] OpenAI calls use server-side Responses API and strict Structured Outputs.
- [x] Codex used materially across audit, architecture, implementation,
      testing, debugging, and submission preparation.
- [x] Human publishing, approval, proof, and payout gates preserved.
- [x] Role checks, validation, rate limiting, safe errors, and server-only key.
- [x] Flutter analysis and tests pass.
- [x] Laravel tests pass.
- [x] Android build succeeds and both roles were inspected on device.
- [x] README includes setup, sample accounts, testing, GPT-5.6, Codex decisions,
      safety, and old-vs-new disclosure.
- [x] Devpost description and demo script prepared.

## Submission owner actions

- [ ] Add `OPENAI_API_KEY` to a server-side deployment secret.
- [ ] Deploy the Laravel API behind a public HTTPS URL.
- [ ] Run one real Campaign Architect request against GPT-5.6.
- [ ] Run one real Creator Coach request against GPT-5.6.
- [ ] Rebuild the Android artifact with the public HTTPS API URL.
- [ ] Upload the final APK/build to a stable judge-accessible URL.
- [ ] Create/push a public Git repository, or keep it private and grant access
      to:
  - [ ] `testing@devpost.com`
  - [ ] `build-week-event@openai.com`
- [ ] Confirm the repository contains the timestamped baseline and Build Week
      commits.
- [ ] Record the demo with spoken audio using `DEMO_SCRIPT.md`.
- [ ] Keep the final edit under three minutes.
- [ ] Upload the video publicly to YouTube.
- [ ] Create a 3:2 project thumbnail under Devpost's size limit.
- [ ] Run `/feedback` in the Build Week Codex session.
- [ ] Copy the returned Codex session ID into Devpost.
- [ ] Replace every `ADD_...` placeholder in `DEVPOST_SUBMISSION.md`.
- [ ] Select **Work & Productivity**.
- [ ] Add the public repository, video, and test-build URLs.
- [ ] Include the explicit pre-existing-vs-new disclosure.
- [ ] Test every link in a signed-out/incognito browser.
- [ ] Submit before the deadline.

## Final technical gate

```bash
flutter pub get
flutter analyze
flutter test
flutter build apk --release \
  --dart-define=LARAVEL_API_BASE_URL=https://YOUR_PUBLIC_API
```

```bash
cd backend
composer install --no-interaction
php artisan test
./vendor/bin/pint --test
php artisan route:list --path=api/ai
```

Then verify:

- [ ] Business account can generate and edit a brief.
- [ ] Creator account can receive campaign-specific coaching.
- [ ] Wrong roles get `403` without an OpenAI request.
- [ ] Missing key gets safe `503`.
- [ ] Health and readiness endpoints return success.
- [ ] No key/token appears in app logs, video, repository, or APK configuration.
- [ ] Payout and approval state cannot be changed by AI output.

## Devpost form audit

- [ ] Project name: Promo Zone AI.
- [ ] Track: Work & Productivity.
- [ ] Elevator pitch is under 200 characters.
- [ ] Detailed story covers inspiration, product, implementation, GPT-5.6,
      Codex, challenges, accomplishments, learnings, and next steps.
- [ ] “Built with” includes GPT-5.6, Responses API, Structured Outputs, Codex,
      Flutter, and Laravel.
- [ ] Video is public, plays without login, has audio, and is under three
      minutes.
- [ ] Test build works without requesting private credentials from judges.
- [ ] Repository access works for judges.
- [ ] Codex session ID is present.
