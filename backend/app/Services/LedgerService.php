<?php

namespace App\Services;

use Illuminate\Support\Facades\DB;
use Illuminate\Support\Str;
use RuntimeException;

class LedgerService
{
    public function depositCredits(string $businessId, int $amount): void
    {
        if ($amount <= 0) {
            throw new RuntimeException('Amount must be greater than zero.');
        }

        DB::transaction(function () use ($businessId, $amount): void {
            $wallet = DB::table('wallets')->where('user_id', $businessId)->lockForUpdate()->first();
            if (!$wallet) {
                throw new RuntimeException('Business wallet not found.');
            }

            DB::table('wallets')->where('user_id', $businessId)->update([
                'available_balance' => $wallet->available_balance + $amount,
                'version' => $wallet->version + 1,
                'updated_at' => now(),
            ]);

            DB::table('wallet_ledger')->insert([
                'id' => (string) Str::uuid(),
                'wallet_user_id' => $businessId,
                'type' => 'deposit',
                'amount' => $amount,
                'direction' => 'in',
                'status' => 'posted',
                'created_at' => now(),
                'updated_at' => now(),
            ]);
        });
    }

    public function approveCreator(string $businessId, string $campaignId, string $applicationId): void
    {
        DB::transaction(function () use ($businessId, $campaignId, $applicationId): void {
            $application = DB::table('applications')->where('id', $applicationId)->lockForUpdate()->first();
            if (!$application || $application->campaign_id !== $campaignId) {
                throw new RuntimeException('Application not found.');
            }
            if ($application->business_id !== $businessId) {
                throw new RuntimeException('Forbidden: only campaign business can approve.');
            }
            if ($application->status !== 'applied') {
                throw new RuntimeException('Application must be in applied state.');
            }

            $campaign = DB::table('campaigns')->where('id', $campaignId)->first();
            if (!$campaign) {
                throw new RuntimeException('Campaign not found.');
            }

            $wallet = DB::table('wallets')->where('user_id', $businessId)->lockForUpdate()->first();
            if (!$wallet) {
                throw new RuntimeException('Business wallet not found.');
            }

            $amount = (int) $campaign->payout_amount_ghs;
            if ((int) $wallet->available_balance < $amount) {
                throw new RuntimeException('Insufficient available balance for hold.');
            }

            $holdId = (string) Str::uuid();
            DB::table('holds')->insert([
                'id' => $holdId,
                'business_id' => $businessId,
                'creator_id' => $application->creator_id,
                'campaign_id' => $campaignId,
                'application_id' => $applicationId,
                'amount' => $amount,
                'status' => 'active',
                'created_at' => now(),
                'updated_at' => now(),
            ]);

            DB::table('wallets')->where('user_id', $businessId)->update([
                'available_balance' => $wallet->available_balance - $amount,
                'held_balance' => $wallet->held_balance + $amount,
                'version' => $wallet->version + 1,
                'updated_at' => now(),
            ]);

            DB::table('wallet_ledger')->insert([
                'id' => (string) Str::uuid(),
                'wallet_user_id' => $businessId,
                'type' => 'hold',
                'amount' => $amount,
                'direction' => 'out',
                'status' => 'posted',
                'campaign_id' => $campaignId,
                'application_id' => $applicationId,
                'hold_id' => $holdId,
                'created_at' => now(),
                'updated_at' => now(),
            ]);

            DB::table('applications')->where('id', $applicationId)->update([
                'status' => 'approved_by_business',
                'approved_at' => now(),
                'hold_id' => $holdId,
                'updated_at' => now(),
            ]);

            DB::table('campaigns')->where('id', $campaignId)->update([
                'approved_count' => DB::raw('approved_count + 1'),
                'updated_at' => now(),
            ]);
        });
    }

    public function approveProof(string $businessId, string $campaignId, string $applicationId): void
    {
        DB::transaction(function () use ($businessId, $campaignId, $applicationId): void {
            $application = DB::table('applications')->where('id', $applicationId)->lockForUpdate()->first();
            if (!$application || $application->campaign_id !== $campaignId) {
                throw new RuntimeException('Application not found.');
            }
            if ($application->business_id !== $businessId) {
                throw new RuntimeException('Forbidden: only campaign business can approve proof.');
            }
            if ($application->status !== 'proof_submitted') {
                throw new RuntimeException('Application must be in proof_submitted state.');
            }

            $campaign = DB::table('campaigns')->where('id', $campaignId)->first();
            if (!$campaign) {
                throw new RuntimeException('Campaign not found.');
            }

            $proof = DB::table('submissions')
                ->where('application_id', $applicationId)
                ->where('type', 'proof')
                ->orderByDesc('created_at')
                ->first();
            if (!$proof) {
                throw new RuntimeException('Proof submission not found.');
            }
            if (!$proof->post_url) {
                throw new RuntimeException('postUrl is required for proof approval.');
            }
            if ((int) $proof->declared_views < (int) $campaign->target_views) {
                throw new RuntimeException('Declared views are below campaign target.');
            }

            $hold = DB::table('holds')->where('id', $application->hold_id)->lockForUpdate()->first();
            if (!$hold || $hold->status !== 'active') {
                throw new RuntimeException('Active hold not found.');
            }

            $businessWallet = DB::table('wallets')->where('user_id', $businessId)->lockForUpdate()->first();
            $creatorWallet = DB::table('wallets')->where('user_id', $application->creator_id)->lockForUpdate()->first();
            if (!$businessWallet || !$creatorWallet) {
                throw new RuntimeException('Wallet not found.');
            }

            $amount = (int) $hold->amount;

            DB::table('wallets')->where('user_id', $businessId)->update([
                'held_balance' => max(0, (int) $businessWallet->held_balance - $amount),
                'version' => $businessWallet->version + 1,
                'updated_at' => now(),
            ]);

            DB::table('wallets')->where('user_id', $application->creator_id)->update([
                'available_balance' => $creatorWallet->available_balance + $amount,
                'version' => $creatorWallet->version + 1,
                'updated_at' => now(),
            ]);

            DB::table('wallet_ledger')->insert([
                [
                    'id' => (string) Str::uuid(),
                    'wallet_user_id' => $businessId,
                    'type' => 'release',
                    'amount' => $amount,
                    'direction' => 'in',
                    'status' => 'posted',
                    'campaign_id' => $campaignId,
                    'application_id' => $applicationId,
                    'hold_id' => $hold->id,
                    'created_at' => now(),
                    'updated_at' => now(),
                ],
                [
                    'id' => (string) Str::uuid(),
                    'wallet_user_id' => $application->creator_id,
                    'type' => 'payout',
                    'amount' => $amount,
                    'direction' => 'in',
                    'status' => 'posted',
                    'campaign_id' => $campaignId,
                    'application_id' => $applicationId,
                    'hold_id' => $hold->id,
                    'created_at' => now(),
                    'updated_at' => now(),
                ],
            ]);

            DB::table('holds')->where('id', $hold->id)->update([
                'status' => 'released',
                'updated_at' => now(),
            ]);

            DB::table('submissions')->where('id', $proof->id)->update([
                'status' => 'approved',
                'updated_at' => now(),
            ]);

            DB::table('applications')->where('id', $applicationId)->update([
                'status' => 'paid',
                'proof_approved_at' => now(),
                'paid_at' => now(),
                'updated_at' => now(),
            ]);
        });
    }

    public function refundHold(string $businessId, string $holdId): void
    {
        DB::transaction(function () use ($businessId, $holdId): void {
            $hold = DB::table('holds')->where('id', $holdId)->lockForUpdate()->first();
            if (!$hold) {
                throw new RuntimeException('Hold not found.');
            }
            if ($hold->business_id !== $businessId) {
                throw new RuntimeException('Forbidden: only owner business can refund hold.');
            }
            if ($hold->status !== 'active') {
                throw new RuntimeException('Only active hold can be refunded.');
            }

            $wallet = DB::table('wallets')->where('user_id', $businessId)->lockForUpdate()->first();
            if (!$wallet) {
                throw new RuntimeException('Business wallet not found.');
            }

            DB::table('wallets')->where('user_id', $businessId)->update([
                'available_balance' => $wallet->available_balance + $hold->amount,
                'held_balance' => max(0, $wallet->held_balance - $hold->amount),
                'version' => $wallet->version + 1,
                'updated_at' => now(),
            ]);

            DB::table('wallet_ledger')->insert([
                'id' => (string) Str::uuid(),
                'wallet_user_id' => $businessId,
                'type' => 'refund',
                'amount' => $hold->amount,
                'direction' => 'in',
                'status' => 'posted',
                'campaign_id' => $hold->campaign_id,
                'application_id' => $hold->application_id,
                'hold_id' => $hold->id,
                'created_at' => now(),
                'updated_at' => now(),
            ]);

            DB::table('holds')->where('id', $hold->id)->update([
                'status' => 'refunded',
                'updated_at' => now(),
            ]);
        });
    }
}
