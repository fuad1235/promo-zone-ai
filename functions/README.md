# Promo Zone Cloud Functions

Callable functions enforcing server-side wallet and hold logic:

- `depositCredits(businessId, amount)`
- `approveCreator(campaignId, applicationId)`
- `approveProof(campaignId, applicationId)`
- `refundHold(holdId)`

## Run

1. `cd functions`
2. `npm install`
3. `npm run build`
4. `firebase emulators:start --only functions`

## Notes

- Functions use Firestore transactions for ledger + wallet + hold integrity.
- All direct wallet/ledger writes are blocked by Firestore rules.
