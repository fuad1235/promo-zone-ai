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
- Device: Android API 36.1 emulator.
- Business flow inspected: login → Work → Create → Campaign Architect sheet.
- Creator flow inspected: login → Browse → campaign → Creator Coach sheet.
- Safe missing-key behavior inspected on device: the app showed
  `AI features are not configured on this server.` without crashing or leaking
  configuration details.

Automated OpenAI tests mock only the upstream HTTP boundary. They assert the
actual model value, strict schema mode, `store: false`, role enforcement,
context inclusion, response parsing, and safe failure. A real generation
requires the submission deployment's server-side `OPENAI_API_KEY`.

## Deliberate boundaries

- Real Mobile Money/bank settlement and payment-provider webhooks remain out of
  scope; the app uses simulated credits with real transactional ledger logic.
- AI output is advisory and cannot mutate approval or financial state.
- A public repository, hosted API, YouTube demo, Devpost form, and Codex
  `/feedback` session ID require the submission owner's authenticated accounts.
