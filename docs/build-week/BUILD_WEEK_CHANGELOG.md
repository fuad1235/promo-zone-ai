# Build Week changelog

Recorded for OpenAI Build Week 2026 on July 18, 2026.

## Eligibility disclosure

Promo Zone is an existing project that was meaningfully extended during the
submission period. Before Build Week it already supported creator/business
accounts, campaigns, applications, proof review, wallet holds, payouts, and
ledger records.

It did not contain an OpenAI client, GPT-5.6 usage, AI-generated campaign
briefs, AI draft coaching, or Build Week submission materials.

The complete baseline disclosure and source fingerprint are in
[`PRE_HACKATHON_BASELINE.md`](PRE_HACKATHON_BASELINE.md).

## Timestamped commit boundary

| Commit | UTC time | Scope |
| --- | --- | --- |
| `4fdbe4e` | 2026-07-18 10:33:28 | Imported the disclosed pre-Build Week baseline and recorded its aggregate SHA-256 |
| `44e8173` | 2026-07-18 10:43:04 | Added secure Laravel GPT-5.6 Campaign Architect and Creator Coach endpoints |
| `82b4b82` | 2026-07-18 11:42:49 | Restored a clean Flutter 3.44 local build/runtime and Laravel dev router |
| `e4d9115` | 2026-07-18 11:43:04 | Added both GPT-5.6 Flutter workflows, result models, tests, and human-control UX |
| `02e964a` | 2026-07-18 11:56:20 | Added the judge guide, Devpost copy, demo script, and submission checklist |
| `6b118af` | 2026-07-18 12:01:32 | Corrected deployment documentation to the verified production API root |
| `e84350e` | 2026-07-18 12:09:35 | Aligned release branding and required HTTPS in production mobile builds |

From baseline commit `4fdbe4e` through product commit `e4d9115`, the Build Week
extension changed 24 files with 2,561 additions and 13 deletions.

Use this command to inspect only the Build Week product work:

```bash
git diff --stat 4fdbe4e..e4d9115
git diff 4fdbe4e..e4d9115
```

## New during Build Week

### Campaign Architect

- Business-only `POST /api/ai/campaign-brief`.
- Product, audience, goal, platform, tone, brand mention, target, payout, and
  creator count input.
- GPT-5.6 strict structured output containing an editable title, brief,
  hashtags, guardrails, ideal creator profile, success signal, and three
  distinct content angles.
- Server-side preservation of business-controlled platform, target views,
  payout, creator count, and mention.
- Flutter generation sheet and review state; AI never publishes.

### Creator Coach

- Creator-only `POST /api/ai/campaigns/{campaignId}/creator-coach`.
- Server-loaded published campaign, hashtags, creator bio, niches, audience
  metrics, and relevant platform handle.
- GPT-5.6 strict structured output containing a score, verdict, checklist,
  strengths, missing requirements, risk flags, recommended hook, revised draft,
  and shot list.
- Flutter coaching sheet with a refine-and-review loop.
- Explicit advisory boundary; AI never applies, approves, or releases funds.

### Shared AI infrastructure

- OpenAI Responses API integration through Laravel's HTTP client.
- `gpt-5.6`, low reasoning effort, strict JSON Schema, and `store: false`.
- Server-only key configuration.
- Authentication, role checks, validation, and a dedicated 10/minute AI rate
  limiter.
- Prompt-injection boundaries that treat all business/campaign/creator/draft
  content as data rather than instructions.
- Safe `502`/`503` responses and logging that excludes prompts and upstream
  bodies.
- Provider/model/response/time/token metadata in successful envelopes.

### Evidence and submission work

- Baseline fingerprint and old-vs-new disclosure.
- AI API feature tests and Flutter AI model/widget tests.
- Emulator inspection of both complete mobile workflows.
- Judge guide, Codex collaboration record, Devpost copy, video script, and
  submission checklist.

## Verification record

Verified July 18, 2026:

- `flutter analyze`: no issues.
- `flutter test`: 7 tests passed.
- `php artisan test`: 15 tests passed, 70 assertions.
- `php -l server.php`: no syntax errors.
- Debug Android APK: clean cache-free build succeeded on Flutter 3.44.2.
- Final local debug APK: 162,228,625 bytes.
- APK SHA-256:
  `06e8f9f9eb83b3ed4f67e3860c930420630c50aed9e098c52d36481e3f32178b`.
- Production-targeted release APK: 56,497,051 bytes.
- Release APK SHA-256:
  `6dc8b83fc8eb32017705305cc38dba1ad35a3c768db0f106895dd0c8416651b8`.
- Release APK verified with Android Signature Scheme v2, label
  `Promo Zone AI`, target SDK 36, minimum SDK 24, and
  `usesCleartextTraffic=false`.
- Device: Android API 36.1 emulator.
- Business flow inspected: login → Work → Create → Campaign Architect sheet.
- Creator flow inspected: login → Browse → campaign → Creator Coach sheet.
- Safe missing-key behavior inspected on device: the app showed
  `AI features are not configured on this server.` without crashing or leaking
  configuration details.

Automated OpenAI tests mock only the upstream HTTP boundary. They assert the
actual model value, strict schema mode, `store: false`, role enforcement,
context inclusion, response parsing, and safe failure.

### Production deployment verification

Verified July 18, 2026 at approximately 13:27 UTC:

- Public API: `https://promozone.boldtechai.com`.
- The pre-deployment production route/provider hashes exactly matched baseline
  commit `4fdbe4e`.
- A private rollback archive was created before any production file changed.
- The uploaded backend overlay matched local SHA-256
  `322bf59c258e834fef1fe1c7cf29c8b70a9d44dcdb3fb8e7888c7f5a27b49a20`.
- All seven deployed PHP files passed syntax checks on Hostinger.
- Laravel configuration and route caches rebuilt successfully.
- Both protected AI routes appear in the production route table.
- `/api/health` and `/api/ready` returned `200`.
- The existing public campaign API continued to return `200`.
- An unauthenticated AI request returned `401`, proving the route and
  authentication boundary are active.
- An authenticated business request returned the designed safe `503` while
  `OPENAI_API_KEY` remained empty.

The submission owner then installed `OPENAI_API_KEY` privately and activated
API credits. Verified July 18, 2026 at approximately 17:04 UTC:

- Laravel configuration and route caches rebuilt successfully with
  `OPENAI_MODEL=gpt-5.6`.
- `/api/health` and `/api/ready` both returned `200`.
- A real authenticated Campaign Architect request returned `200`, requested
  `gpt-5.6`, was served by `gpt-5.6-sol`, and returned all required structured
  fields plus three content angles.
- The server preserved the submitted platform, target views, payout, creator
  count, and brand mention exactly.
- A real authenticated Creator Coach request returned `200`, requested
  `gpt-5.6`, was served by `gpt-5.6-sol`, and returned a valid score, verdict,
  and nine-item campaign checklist.
- Protected temporary bearer tokens and raw response files were deleted after
  validation. No API key value was read or recorded.

### Public product and Android release verification

Verified July 19, 2026 at approximately 06:23 UTC:

- Public product page: `https://promozone.boldtechai.com`.
- Public Android release:
  `https://github.com/fuad1235/promo-zone-ai/releases/tag/v1.0.0-build-week`.
- The release is published from `main` with one fully uploaded APK asset.
- The public APK downloaded successfully at exactly `56,497,051` bytes and
  matched SHA-256
  `6dc8b83fc8eb32017705305cc38dba1ad35a3c768db0f106895dd0c8416651b8`.
- The default Laravel root was replaced with a responsive Promo Zone AI product
  page linking to the APK, source, API status, demo accounts, and judge guide.
- The candidate Blade template compiled with production PHP before deployment.
- A private copy of the previous root view was retained for rollback.
- After deployment, `/`, `/api/health`, `/api/ready`, and `/api/campaigns`
  returned `200`; an unauthenticated AI request still returned `401`.

### Judge APK reliability refresh

Verified July 19, 2026 at approximately 21:22 UTC:

- Increased the Flutter API timeout default and both Android run-helper
  defaults from 12 seconds to 60 seconds. This accommodates the backend's
  45-second OpenAI processing window without changing campaign behavior,
  authorization, approvals, or financial controls.
- Added a regression test for the production timeout default.
- `flutter analyze` completed with no issues.
- `flutter test` passed all 8 tests.
- Built a clean production-targeted universal APK with explicit
  `API_TIMEOUT_MS=60000`.
- The APK contains `armeabi-v7a`, `arm64-v8a`, and `x86_64` Flutter/app
  libraries.
- Replacement APK size: `56,496,807` bytes.
- Replacement APK SHA-256:
  `648a2c374fbff4ae51c67d9eed6b2d337bd3b0ae4b976b441c0bf3ad02afb672`.
- Android inspection confirmed package `com.promozone.promozone`, version
  `1.0.0`, minimum SDK 24, target SDK 36, label `Promo Zone AI`, and
  `usesCleartextTraffic=false`.
- APK Signature Scheme v2 verification passed.
- The exact candidate installed and cold-launched on the API 36.1 x86_64
  emulator, loaded production campaign data, and returned a complete live
  Campaign Architect result from GPT-5.6.
- The GitHub release asset was replaced under the existing stable download
  URL, downloaded again anonymously, and matched the tested local APK's exact
  `56,496,807`-byte size and SHA-256
  `648a2c374fbff4ae51c67d9eed6b2d337bd3b0ae4b976b441c0bf3ad02afb672`.

## Deliberate boundaries

- Real Mobile Money/bank settlement and payment-provider webhooks remain out of
  scope; the app uses simulated credits with real transactional ledger logic.
- AI output is advisory and cannot mutate approval or financial state.
- The direct-install judge APK uses the local Android debug certificate because
  no production upload keystore is present; it is not a Play Store artifact.
- The YouTube demo, Devpost form, and Codex `/feedback` session ID require the
  submission owner's authenticated accounts.
