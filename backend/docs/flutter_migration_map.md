# Flutter Service Replacement Map

## Current Flutter files

- `lib/common/services/callable_service.dart`
- `lib/features/campaigns/data/campaign_repository.dart`
- `lib/features/campaigns/data/application_repository.dart`
- `lib/features/campaigns/data/submission_repository.dart`
- `lib/features/wallet/data/wallet_repository.dart`

## Target Laravel API mapping

- `depositCredits` -> `POST /api/wallet/deposit`
- `approveCreator` -> `POST /api/campaigns/{campaignId}/applications/{applicationId}/approve`
- `approveProof` -> `POST /api/campaigns/{campaignId}/applications/{applicationId}/approve-proof`
- `refundHold` -> `POST /api/holds/refund`
- `watchPublishedCampaigns` -> `GET /api/campaigns`
- `createCampaign` -> `POST /api/campaigns`
- `apply` -> `POST /api/campaigns/{campaignId}/apply`
- `create submission` -> `POST /api/applications/{applicationId}/submissions`
- `wallet + ledger` -> `GET /api/wallet`
- `withdraw request` -> `POST /api/wallet/withdraw-request`

## Suggested migration order

1. Replace callable functions first (wallet/hold/payout critical path).
2. Replace campaign/application/submission reads+writes.
3. Keep Storage URLs the same during transition.
4. Finally retire Firebase Firestore/Functions dependencies.

## Auth note

- Flutter uses backend-issued bearer token from `/api/auth/login` and `/api/auth/register`.
- Backend middleware `api.auth` verifies token hash in `users.api_token`.
