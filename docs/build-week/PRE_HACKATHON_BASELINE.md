# Promo Zone pre-hackathon baseline

Recorded on July 18, 2026 before Build Week product changes.

Promo Zone existed before the OpenAI Build Week submission period. The
existing source files in this workspace are dated between February and April
2026. The project did not have usable Git history when this Build Week effort
started: the `.git` directory was empty.

## Baseline fingerprint

Before changing product code, the source tree was fingerprinted with:

```bash
find lib backend/app backend/config backend/database backend/routes \
  backend/tests test docs functions/src -type f | sort \
  | xargs sha256sum | sha256sum
```

Aggregate SHA-256:

```text
527a93c378f6fefe602c449e7b700f0f11f54d0dece9e1da201fc39cc22e4891
```

This fingerprint covers the pre-existing Flutter application, Laravel API,
database schema and seeders, Firebase functions, tests, and documentation. It
does not cover generated dependencies or build output.

## Functionality that already existed

- Creator and business registration, login, role selection, and onboarding.
- Public campaign browsing, search, platform filters, and payout filters.
- Business campaign creation, publishing, and applicant review.
- Creator application, sample submission, posting, and proof submission.
- Business sample/proof review.
- Transactional wallet holds, releases, refunds, creator payouts, and ledger
  records.
- Uploads, demo seed data, local development scripts, and basic CI checks.

## Functionality that did not exist

- No OpenAI API integration.
- No GPT-5.6 model usage.
- No AI campaign brief generation.
- No AI creator ideation or draft review.
- No Build Week evidence, judging narrative, demo script, or submission copy.

## Build Week boundary

The baseline commit is an import of the existing project plus this disclosure
and repository-hygiene exclusions. Every commit after the baseline is intended
to represent work performed during OpenAI Build Week. The Build Week changelog
will map those commits to the new functionality.
