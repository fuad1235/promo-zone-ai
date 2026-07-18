# Demo script — target 2:45

The final video must be public on YouTube, under three minutes, and include
spoken audio. Record at 1080p with large emulator text and no API keys visible.

## Before recording

- Deploy Laravel behind HTTPS with `OPENAI_API_KEY` in the host secret manager.
- Build Flutter with the public API URL.
- Seed the database.
- Test both generations once.
- Sign out and begin on the guest Browse screen.
- Keep a terminal ready with `git log --oneline` and the passing test summaries.

## Script

### 0:00–0:15 — Problem

**Visual:** Promo Zone campaign browse.

**Voice:**

“Small brands often have a product idea, but not a creator-ready brief.
Creators then film from scattered requirements and discover too late that they
missed a mention, restriction, or deliverable. Promo Zone AI fixes both sides
inside the campaign workflow.”

### 0:15–0:27 — Product

**Visual:** Quickly show Business Hub, creator Browse, and wallet/workflow
screens.

**Voice:**

“It is a Flutter and Laravel marketplace with applications, proof review, and
ledger-backed credit holds. During Build Week, we added two contextual GPT-5.6
workflows.”

### 0:27–1:08 — Campaign Architect

**Visual:** Login as `sparkbrew@promozone.test`. Open Work → Create → Build
brief with GPT-5.6. Show prepared input, tap Generate, then scroll through the
result and editable campaign form.

**Voice:**

“Campaign Architect takes product facts, audience, goal, platform, and tone.
GPT-5.6 returns a strict structured brief, guardrails, creator profile, success
signal, hashtags, and three distinct content angles. The output fills the
normal editable form. Target views, payout, creator count, platform, and
mention remain business-controlled, and AI never publishes automatically.”

### 1:08–1:52 — Creator Coach

**Visual:** Login as `ama.creator@promozone.test`. Open a campaign, scroll to
Creator Coach, paste the deliberately imperfect draft, tap Review, and show
score, checklist, risks, revised hook/draft, and shot list.

**Voice:**

“Creator Coach loads this live campaign and Ama’s relevant profile on the
server. I’ll paste a draft with a missing mention and an unsupported claim.
GPT-5.6 scores it, checks each campaign requirement, flags the claim, identifies
what is missing, and proposes a stronger hook, draft, and shot list. This is
coaching only—the business still controls approval and payout.”

### 1:52–2:21 — Technical implementation

**Visual:** Split screen or quick cuts:

- `OpenAiCampaignService.php` showing `model`, `json_schema`, `strict`, and
  `store`.
- `AiCampaignController.php` role/context flow.
- tests passing.

**Voice:**

“The OpenAI key stays in Laravel. We use the Responses API with `gpt-5.6`,
strict JSON-schema Structured Outputs, low reasoning effort, and `store`
disabled. Both endpoints are authenticated, role-protected, validated, and
rate-limited. User and campaign text is treated as untrusted data, and model
output cannot mutate workflow or financial state.”

### 2:21–2:38 — Codex and evidence

**Visual:** `git log --oneline`, baseline document, then Flutter/Laravel test
results.

**Voice:**

“Codex helped us fingerprint the pre-existing baseline, research the API,
design and implement both workflows, write tests, diagnose Android packaging,
and verify the app on an emulator. The timestamped commits clearly separate
the original marketplace from 2,500-plus lines of Build Week product work.”

### 2:38–2:52 — Close

**Visual:** Alternate between the generated business brief and creator coaching
result; finish on the Promo Zone AI name.

**Voice:**

“Promo Zone AI turns campaign ambiguity into executable work and catches
expensive mistakes before creators shoot—while humans remain accountable for
every business and payout decision.”

## Editing notes

- Aim for 2:45–2:52; never exceed 2:59.
- Keep generation waits short by cutting between tap and result.
- Show the GPT-5.6 label in both product screens.
- Show at least one real generated result, not test fixture output.
- Do not show `.env`, bearer tokens, API keys, personal notifications, or local
  paths containing sensitive names.
- Add captions for model name, safeguards, test counts, and commit boundary.
- Use only music/assets you are allowed to publish.
