# Codex collaboration record

Codex was the primary engineering collaborator for the Build Week extension.
This record explains how it was used, what decisions it influenced, and where
the resulting evidence lives.

## Collaboration sequence

1. **Baseline audit**
   - Inspected the Flutter, Laravel, test, and operations structure.
   - Confirmed the project predated Build Week and contained no OpenAI
     integration.
   - Fingerprinted the pre-existing source tree and created baseline commit
     `4fdbe4e` before changing product code.
2. **Hackathon and API research**
   - Checked the official Build Week rules, required deliverables, track
     definitions, and judging criteria.
   - Selected Work & Productivity because the product automates a real
     brand-to-creator workflow rather than presenting a generic chat surface.
   - Checked official OpenAI model, Responses API, and Structured Outputs
     documentation before implementation.
3. **Architecture**
   - Kept the OpenAI key and calls in Laravel instead of the mobile app.
   - Designed two role-specific features that use live application context.
   - Chose strict JSON-schema responses so Flutter renders typed product UI
     instead of parsing prose.
4. **Implementation**
   - Added the OpenAI service, exceptions, configuration, controller, routes,
     rate limiter, tests, Flutter repositories/models, and both user
     experiences.
   - Preserved the existing campaign, workflow, and financial systems rather
     than replacing them with AI.
5. **Verification and debugging**
   - Ran PHP syntax checks, Laravel formatting/tests, Dart formatting, Flutter
     analysis/tests, and Android builds.
   - Diagnosed an Android plugin registration failure to a corrupted
     incremental APK, then proved a clean cache-free package fixed it.
   - Diagnosed a missing Laravel development router and restored `server.php`.
   - Logged into seeded business and creator accounts on an emulator and
     inspected both AI workflows.
   - Exercised the missing-key path on device to confirm a safe user-facing
     error.
6. **Submission preparation**
   - Produced the old-vs-new changelog, judge guide, Devpost narrative,
     under-three-minute script, and owner checklist.
   - Probed the existing production API, identified its actual domain-root
     mount, and confirmed that the old deployment was healthy but did not yet
     contain the Build Week AI routes.
   - Built and inspected the production-targeted Android artifact, corrected
     its visible product name, and disabled cleartext HTTP in release builds.

## Important decisions

| Question | Decision | Reason |
| --- | --- | --- |
| Where should OpenAI calls live? | Laravel only | A mobile bundle cannot safely hold a secret; the server also owns trusted campaign and role context. |
| How should model output reach Flutter? | Strict JSON-schema Structured Outputs | Typed fields are testable, renderable, and safer than brittle prose parsing. |
| Should AI choose payout and target values? | No; overwrite them with business input after generation | These are business and financial decisions, not creative suggestions. |
| Should coaching affect approval? | No; advisory result only | Businesses retain accountability and financial authorization. |
| What context should Creator Coach use? | Published campaign plus relevant authenticated creator profile | This makes the feature materially more useful than a generic rewrite prompt. |
| How should user-provided instructions be handled? | Mark all embedded context as untrusted data | Campaigns and drafts can contain prompt-injection-like text. |
| Should Responses be stored by OpenAI? | `store: false` | The features do not need server-side response retention. |
| How should failures appear? | Generic `502`/`503` messages; safe metadata in logs | Prevent prompt, key, and upstream-body exposure. |
| Which Build Week track fits? | Work & Productivity | The app reduces campaign setup and rework inside an operational workflow. |

## Commit evidence

```text
e84350e chore(release): polish app identity and require HTTPS
6b118af docs(deploy): correct production API base URL
02e964a docs(build-week): add judge and Devpost submission package
e4d9115 feat(app): add GPT-5.6 campaign and creator workflows
82b4b82 fix(dev): restore clean local build and Android runtime
44e8173 feat(api): add GPT-5.6 campaign architect and creator coach
4fdbe4e chore: import pre-Build Week Promo Zone baseline
```

Review:

```bash
git log --format=fuller --reverse
git diff 4fdbe4e..HEAD
```

## Key implementation locations

- `backend/app/Services/OpenAiCampaignService.php`
- `backend/app/Http/Controllers/Api/AiCampaignController.php`
- `backend/tests/Feature/AiCampaignFeatureTest.php`
- `lib/features/ai/`
- `lib/features/business/presentation/edit_campaign_page.dart`
- `lib/features/creator/presentation/campaign_detail_page.dart`

## Codex session ID

The submission owner must run `/feedback` in the Build Week Codex session and
copy the resulting session ID into Devpost before submission.

```text
CODEX_SESSION_ID=ADD_FROM_SLASH_FEEDBACK
```

This repository intentionally does not invent or infer a session ID.
