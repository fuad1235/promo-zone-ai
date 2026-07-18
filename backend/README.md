# Promo Zone Laravel API

Laravel 12 API for Promo Zone AI. It owns authentication, campaign and creator
context, OpenAI requests, workflow state, wallet holds, ledger entries, and
payout decisions.

## Included systems

- Bearer-token registration, login, profile sync, and role middleware.
- Campaign, application, submission, upload, and wallet endpoints.
- Transactional ledger service using row locks for holds, releases, refunds,
  and simulated deposits.
- Idempotency protection for financial writes.
- GPT-5.6 Campaign Architect and Creator Coach.
- Health/readiness probes, request IDs, security headers, rate limits, and
  sensitive-log redaction.
- OpenAPI contract at `docs/openapi.yaml`.

## Local setup

Requirements: PHP 8.2+, Composer, and an OpenAI API key for real AI calls.

```bash
composer install
cp .env.example .env
touch database/database.sqlite
php artisan key:generate
php artisan migrate:fresh --seed
php artisan serve --no-reload
```

The local template uses SQLite. Production configuration in
`.env.production.example` uses MySQL.

The included `server.php` is the development router Laravel's built-in server
uses. It is not involved in Nginx/Apache production deployments.

## OpenAI configuration

Set these values in the ignored `.env` file or your host's secret manager:

```dotenv
OPENAI_API_KEY=your_server_side_key
OPENAI_MODEL=gpt-5.6
OPENAI_BASE_URL=https://api.openai.com/v1
OPENAI_REASONING_EFFORT=low
OPENAI_TIMEOUT_SECONDS=45
OPENAI_MAX_OUTPUT_TOKENS=2200
AI_RATE_LIMIT_PER_MINUTE=10
```

Never expose `OPENAI_API_KEY` through a Flutter `--dart-define`, mobile bundle,
public environment file, log, or response.

Both features call the Responses API directly through Laravel's HTTP client.
Requests use strict JSON-schema Structured Outputs and `store: false`.

### Campaign Architect

```http
POST /api/ai/campaign-brief
Authorization: Bearer <business-token>
Content-Type: application/json
```

The request includes product facts, audience, goal, platform, tone, target
views, payout, creators needed, and an optional brand mention. The response
includes an editable title, brief, hashtags, content guardrails, ideal creator
profile, success signal, and three content angles.

Platform, target views, payout, creator count, and mention are enforced from
business input after generation; GPT-5.6 cannot silently change them.

### Creator Coach

```http
POST /api/ai/campaigns/{campaignId}/creator-coach
Authorization: Bearer <creator-token>
Content-Type: application/json

{"draft":"My proposed hook, caption, voiceover, or script..."}
```

Laravel loads the published campaign and relevant authenticated creator
profile. GPT-5.6 returns a score, verdict, checklist, strengths, missing
requirements, risk flags, revised hook, revised draft, and shot list.

The endpoint is advisory only. It cannot apply to a campaign, approve work,
change workflow state, create a hold, or release funds.

## Failure behavior

- `401`: unauthenticated
- `403`: wrong role; returned before any OpenAI request
- `422`: invalid input
- `429`: AI rate limit exceeded
- `502`: OpenAI is unreachable or returns an invalid response
- `503`: server has no OpenAI key/model configuration

Client-facing errors are intentionally generic. Logs contain the feature,
authenticated user ID, request ID, exception class, and safe message—not the
prompt, draft, API key, or upstream response body.

## Demo data

```bash
php artisan migrate:fresh --seed
```

All demo users use `Password@123`.

- Business: `sparkbrew@promozone.test`
- Creator: `ama.creator@promozone.test`

The seeder includes additional brands, creators, active campaigns, creator
profiles, wallets, and workflow examples.

## Tests and formatting

```bash
php artisan test
./vendor/bin/pint --test
```

The current suite contains 15 passing tests and 70 assertions. AI tests mock
the OpenAI HTTP boundary while asserting the real request model, schema mode,
`store: false`, role protection, context inclusion, response parsing, and safe
configuration failure.

## Data integrity

- Wallet operations are server-only and transactional.
- `lockForUpdate()` protects wallets, holds, and application state.
- Application transitions use an explicit state machine.
- Hold lifecycle is `active -> released|refunded`.
- Financial writes support `Idempotency-Key` replay protection.
- AI output is never trusted as authorization or financial input.

## Production

Use `.env.production.example`, the root
[`docs/release_runbook.md`](../docs/release_runbook.md), and the provided Nginx
and Supervisor templates. Production must use HTTPS, an explicit CORS allow
list, host-managed secrets, backed-up MySQL, and `APP_DEBUG=false`.
