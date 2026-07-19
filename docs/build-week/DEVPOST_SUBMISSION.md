# Copy-ready Devpost submission

Submission values and copy used for the Build Week entry.

## Project name

Promo Zone AI

## Elevator pitch

Promo Zone AI connects businesses with emerging and established creators to
promote products in social videos, using GPT-5.6 to build briefs and coach
creator drafts.

## Track

Work & Productivity

## Links

```text
Repository: https://github.com/fuad1235/promo-zone-ai
Demo video: https://www.youtube.com/watch?v=fu4yPJetCy8
Product: https://promozone.boldtechai.com
Android release: https://github.com/fuad1235/promo-zone-ai/releases/tag/v1.0.0-build-week
Direct APK: https://github.com/fuad1235/promo-zone-ai/releases/download/v1.0.0-build-week/Promo-Zone-AI-Android-e84350e.apk
Codex session ID: 019f74b3-0d8d-7c03-9045-a6708729aea8
```

If the repository is private, grant access to both:

```text
testing@devpost.com
build-week-event@openai.com
```

## What it does

Promo Zone AI is a two-sided marketplace where businesses publish promotional
campaigns and emerging or established social-media creators discover those
campaigns, apply, feature the product or service in their videos, submit their
work, and follow approval and payment status.

Businesses provide the product or service, platform, target views, payout,
number of creators, mentions, hashtags, content instructions, and
restrictions. They review applications and submissions and remain responsible
for every publishing, approval, and payout decision.

Campaign Architect uses GPT-5.6 to turn business context into an editable
creator brief, guardrails, ideal creator profile, success signal, hashtags,
and three content angles. Creator Coach reviews a creator's hook, caption,
voiceover, or script against the selected live campaign and returns a score,
checklist, risk flags, revised draft, and shot list.

The marketplace handles applications, proof review, ledger-backed credit
holds, and payouts. AI remains advisory and never publishes, approves, or
releases funds.

## Inspiration

Emerging and established social-media creators need genuine opportunities to
work with businesses, while businesses need authentic ways to introduce their
products and services through creator videos.

These partnerships are often managed through scattered messages and informal
agreements. Businesses struggle to find suitable creators and communicate
expectations, while creators struggle to discover opportunities, understand
requirements, submit work, and track approvals and payments. We built Promo
Zone AI to give both sides one structured marketplace, with GPT-5.6 improving
brief preparation and creator coaching inside that workflow.

## How we built it

The mobile app is Flutter with Riverpod and GoRouter. Laravel owns bearer
authentication, role checks, campaigns, creator profiles, workflow state,
uploads, wallet holds, and immutable ledger entries.

Laravel calls the OpenAI Responses API with `gpt-5.6`, low reasoning effort,
`store: false`, and strict JSON-schema Structured Outputs. That gives Flutter
typed fields it can render as product UI instead of brittle prose.

Campaign Architect treats business context as untrusted data and returns only
the requested schema. After generation, Laravel overwrites platform, target
views, payout, creator count, and mention with the original business inputs.

Creator Coach loads the published campaign and relevant authenticated creator
context server-side. It treats the campaign, profile, and draft as untrusted
data and is explicitly instructed that a human business reviewer controls
approval and payout.

The OpenAI key remains server-side. AI endpoints are authenticated,
role-protected, validated, and rate-limited before token spend. Safe error
responses do not reveal prompts, keys, or upstream payloads.

## How we used Codex

Codex was our primary engineering collaborator throughout Build Week. We used
it to audit and fingerprint the pre-existing baseline, research the official
rules and OpenAI API patterns, design the server-side architecture, implement
both backend and Flutter workflows, write tests, run Android builds, diagnose
platform/runtime failures, inspect both flows on an emulator, and prepare this
submission.

Two particularly useful Codex-driven decisions were using strict Structured
Outputs rather than parsing prose, and keeping model output entirely outside
authorization/financial state. The repository includes a timestamped baseline,
commit history, and a detailed Codex decision record.

## Challenges

The hardest product challenge was deciding what AI should not control. A
campaign generator that can silently change payout or creator count would be
convenient but unsafe. A draft score that doubles as approval would blur
accountability. We therefore designed both features as structured,
context-aware assistance with explicit human gates.

The hardest implementation issue appeared only on device: a corrupted
incremental Android package omitted a compiled plugin class, which stopped all
plugin registration. Codex traced the full Android stack to the missing class,
performed a clean cache-free build, reinstalled it, and verified the app on an
API 36.1 emulator. We also restored a missing Laravel development router that
the static test suite could not expose.

## Accomplishments

- Two non-trivial GPT-5.6 workflows embedded in a real two-sided marketplace.
- Strict, typed output with server-side business-constraint preservation.
- Live campaign and creator context in the coaching request.
- Human-controlled publishing, approval, proof review, and payouts.
- Prompt-injection boundaries, safe failures, rate limiting, and server-only
  secrets.
- 8 passing Flutter tests with zero analyzer issues.
- 15 passing Laravel tests with 70 assertions.
- Timestamped old-vs-new evidence for an existing project.
- End-to-end Android inspection for both roles.
- Live production validation of both authenticated GPT-5.6 workflows.

## What we learned

Structured Outputs are not only a parsing convenience; they make the model a
testable product component. We also learned that contextual AI is most useful
when it sits next to trusted domain state but remains separated from
authorization. Finally, device-level verification still matters: a clean test
suite cannot detect every packaging or platform-channel problem.

## What's next

- Add campaign performance feedback so future briefs learn from approved,
  high-performing content without letting AI make payout decisions.
- Add multilingual briefing and coaching for more African markets.
- Introduce business-owned reusable brand policy packs.
- Add creator consent controls for profile fields sent to AI.
- Add a dedicated required-video-duration field to campaign briefs.
- Integrate real Mobile Money settlement, webhooks, identity verification, and
  production fraud monitoring.

## Existing project disclosure

Promo Zone existed before Build Week with authentication, campaign operations,
applications, submissions, and ledger-backed wallet workflows. It had no
OpenAI integration, GPT-5.6 usage, Campaign Architect, Creator Coach, or Build
Week materials.

Baseline commit: `4fdbe4e`, recorded July 18, 2026 at 10:33:28 UTC.

Build Week product commits:

```text
44e8173 feat(api): add GPT-5.6 campaign architect and creator coach
82b4b82 fix(dev): restore clean local build and Android runtime
e4d9115 feat(app): add GPT-5.6 campaign and creator workflows
e84350e chore(release): polish app identity and require HTTPS
```

Submission evidence and deployment documentation were added in separate
timestamped commits. The repository contains the baseline fingerprint,
old-vs-new changelog, Codex record, setup instructions, sample data, tests, and
demo path.

## Built with

```text
OpenAI
GPT-5.6
Responses API
Structured Outputs
Codex
Flutter
Dart
Laravel
PHP
SQLite
MySQL
Riverpod
Android
```
