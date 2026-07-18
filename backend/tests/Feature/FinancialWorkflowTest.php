<?php

namespace Tests\Feature;

use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Str;
use Tests\TestCase;

class FinancialWorkflowTest extends TestCase
{
    use RefreshDatabase;

    public function test_approve_creator_creates_hold_and_updates_wallets(): void
    {
        [$business, $businessToken] = $this->createUser('business');
        [$creator] = $this->createUser('creator');
        $this->createWallet($business['id'], 'business', 1000, 0);
        $this->createWallet($creator['id'], 'creator', 0, 0);

        $campaignId = $this->createCampaign($business['id'], [
            'payout_amount_ghs' => 300,
            'target_views' => 1000,
            'status' => 'published',
        ]);
        $applicationId = $this->createApplicationRecord($campaignId, $business['id'], $creator['id'], 'applied');

        $response = $this
            ->withHeader('Authorization', "Bearer {$businessToken}")
            ->postJson("/api/campaigns/{$campaignId}/applications/{$applicationId}/approve");

        $response->assertOk()->assertJson(['ok' => true]);

        $application = DB::table('applications')->where('id', $applicationId)->first();
        $this->assertSame('approved_by_business', $application->status);
        $this->assertNotNull($application->hold_id);

        $hold = DB::table('holds')->where('id', $application->hold_id)->first();
        $this->assertNotNull($hold);
        $this->assertSame('active', $hold->status);
        $this->assertSame(300, (int) $hold->amount);

        $wallet = DB::table('wallets')->where('user_id', $business['id'])->first();
        $this->assertSame(700, (int) $wallet->available_balance);
        $this->assertSame(300, (int) $wallet->held_balance);

        $this->assertDatabaseHas('wallet_ledger', [
            'wallet_user_id' => $business['id'],
            'type' => 'hold',
            'direction' => 'out',
            'amount' => 300,
            'application_id' => $applicationId,
        ]);
    }

    public function test_approve_proof_releases_hold_and_pays_creator(): void
    {
        [$business, $businessToken] = $this->createUser('business');
        [$creator] = $this->createUser('creator');
        $this->createWallet($business['id'], 'business', 700, 300);
        $this->createWallet($creator['id'], 'creator', 0, 0);

        $campaignId = $this->createCampaign($business['id'], [
            'payout_amount_ghs' => 300,
            'target_views' => 1000,
            'status' => 'published',
        ]);
        $applicationId = $this->createApplicationRecord(
            $campaignId,
            $business['id'],
            $creator['id'],
            'proof_submitted'
        );
        $holdId = (string) Str::uuid();

        DB::table('holds')->insert([
            'id' => $holdId,
            'business_id' => $business['id'],
            'creator_id' => $creator['id'],
            'campaign_id' => $campaignId,
            'application_id' => $applicationId,
            'amount' => 300,
            'status' => 'active',
            'created_at' => now(),
            'updated_at' => now(),
        ]);

        DB::table('applications')->where('id', $applicationId)->update([
            'hold_id' => $holdId,
        ]);

        $submissionId = (string) Str::uuid();
        DB::table('submissions')->insert([
            'id' => $submissionId,
            'application_id' => $applicationId,
            'type' => 'proof',
            'message' => 'Proof data',
            'post_url' => 'https://example.com/post/1',
            'declared_views' => 1200,
            'status' => 'pending',
            'created_at' => now(),
            'updated_at' => now(),
        ]);

        $response = $this
            ->withHeader('Authorization', "Bearer {$businessToken}")
            ->postJson("/api/campaigns/{$campaignId}/applications/{$applicationId}/approve-proof");

        $response->assertOk()->assertJson(['ok' => true]);

        $application = DB::table('applications')->where('id', $applicationId)->first();
        $this->assertSame('paid', $application->status);

        $hold = DB::table('holds')->where('id', $holdId)->first();
        $this->assertSame('released', $hold->status);

        $businessWallet = DB::table('wallets')->where('user_id', $business['id'])->first();
        $creatorWallet = DB::table('wallets')->where('user_id', $creator['id'])->first();
        $this->assertSame(0, (int) $businessWallet->held_balance);
        $this->assertSame(300, (int) $creatorWallet->available_balance);

        $this->assertDatabaseHas('wallet_ledger', [
            'wallet_user_id' => $business['id'],
            'type' => 'release',
            'amount' => 300,
            'hold_id' => $holdId,
        ]);
        $this->assertDatabaseHas('wallet_ledger', [
            'wallet_user_id' => $creator['id'],
            'type' => 'payout',
            'amount' => 300,
            'hold_id' => $holdId,
        ]);
        $this->assertDatabaseHas('submissions', [
            'id' => $submissionId,
            'status' => 'approved',
        ]);
    }

    public function test_refund_hold_returns_business_funds(): void
    {
        [$business, $businessToken] = $this->createUser('business');
        [$creator] = $this->createUser('creator');
        $this->createWallet($business['id'], 'business', 700, 300);
        $this->createWallet($creator['id'], 'creator', 0, 0);

        $campaignId = $this->createCampaign($business['id'], [
            'payout_amount_ghs' => 300,
            'status' => 'published',
        ]);
        $applicationId = $this->createApplicationRecord(
            $campaignId,
            $business['id'],
            $creator['id'],
            'approved_by_business'
        );
        $holdId = (string) Str::uuid();

        DB::table('holds')->insert([
            'id' => $holdId,
            'business_id' => $business['id'],
            'creator_id' => $creator['id'],
            'campaign_id' => $campaignId,
            'application_id' => $applicationId,
            'amount' => 300,
            'status' => 'active',
            'created_at' => now(),
            'updated_at' => now(),
        ]);

        DB::table('applications')->where('id', $applicationId)->update(['hold_id' => $holdId]);

        $response = $this
            ->withHeader('Authorization', "Bearer {$businessToken}")
            ->postJson('/api/holds/refund', ['holdId' => $holdId]);

        $response->assertOk()->assertJson(['ok' => true]);

        $wallet = DB::table('wallets')->where('user_id', $business['id'])->first();
        $this->assertSame(1000, (int) $wallet->available_balance);
        $this->assertSame(0, (int) $wallet->held_balance);
        $this->assertDatabaseHas('holds', [
            'id' => $holdId,
            'status' => 'refunded',
        ]);
        $this->assertDatabaseHas('wallet_ledger', [
            'wallet_user_id' => $business['id'],
            'type' => 'refund',
            'amount' => 300,
            'hold_id' => $holdId,
        ]);
    }

    public function test_invalid_transition_is_rejected_and_state_unchanged(): void
    {
        [$business, $businessToken] = $this->createUser('business');
        [$creator] = $this->createUser('creator');
        $this->createWallet($business['id'], 'business', 1000, 0);
        $this->createWallet($creator['id'], 'creator', 0, 0);

        $campaignId = $this->createCampaign($business['id'], ['status' => 'published']);
        $applicationId = $this->createApplicationRecord($campaignId, $business['id'], $creator['id'], 'applied');

        $response = $this
            ->withHeader('Authorization', "Bearer {$businessToken}")
            ->postJson("/api/applications/{$applicationId}/transition", [
                'to' => 'paid',
            ]);

        $response->assertStatus(422);
        $response->assertJsonPath('message', 'Invalid state transition.');
        $this->assertDatabaseHas('applications', [
            'id' => $applicationId,
            'status' => 'applied',
        ]);
    }

    public function test_approve_creator_fails_when_business_balance_is_insufficient(): void
    {
        [$business, $businessToken] = $this->createUser('business');
        [$creator] = $this->createUser('creator');
        $this->createWallet($business['id'], 'business', 100, 0);
        $this->createWallet($creator['id'], 'creator', 0, 0);

        $campaignId = $this->createCampaign($business['id'], [
            'payout_amount_ghs' => 300,
            'status' => 'published',
        ]);
        $applicationId = $this->createApplicationRecord($campaignId, $business['id'], $creator['id'], 'applied');

        $response = $this
            ->withHeader('Authorization', "Bearer {$businessToken}")
            ->postJson("/api/campaigns/{$campaignId}/applications/{$applicationId}/approve");

        $response->assertStatus(422);
        $response->assertJsonPath('message', 'Insufficient available balance for hold.');

        $this->assertDatabaseMissing('holds', [
            'application_id' => $applicationId,
        ]);
        $this->assertDatabaseHas('applications', [
            'id' => $applicationId,
            'status' => 'applied',
        ]);
    }

    public function test_approve_proof_fails_when_declared_views_below_target(): void
    {
        [$business, $businessToken] = $this->createUser('business');
        [$creator] = $this->createUser('creator');
        $this->createWallet($business['id'], 'business', 700, 300);
        $this->createWallet($creator['id'], 'creator', 0, 0);

        $campaignId = $this->createCampaign($business['id'], [
            'target_views' => 1500,
            'payout_amount_ghs' => 300,
            'status' => 'published',
        ]);
        $applicationId = $this->createApplicationRecord(
            $campaignId,
            $business['id'],
            $creator['id'],
            'proof_submitted'
        );
        $holdId = (string) Str::uuid();

        DB::table('holds')->insert([
            'id' => $holdId,
            'business_id' => $business['id'],
            'creator_id' => $creator['id'],
            'campaign_id' => $campaignId,
            'application_id' => $applicationId,
            'amount' => 300,
            'status' => 'active',
            'created_at' => now(),
            'updated_at' => now(),
        ]);
        DB::table('applications')->where('id', $applicationId)->update(['hold_id' => $holdId]);

        DB::table('submissions')->insert([
            'id' => (string) Str::uuid(),
            'application_id' => $applicationId,
            'type' => 'proof',
            'message' => 'Low-views proof',
            'post_url' => 'https://example.com/post/2',
            'declared_views' => 1499,
            'status' => 'pending',
            'created_at' => now(),
            'updated_at' => now(),
        ]);

        $response = $this
            ->withHeader('Authorization', "Bearer {$businessToken}")
            ->postJson("/api/campaigns/{$campaignId}/applications/{$applicationId}/approve-proof");

        $response->assertStatus(422);
        $response->assertJsonPath('message', 'Declared views are below campaign target.');

        $this->assertDatabaseHas('applications', [
            'id' => $applicationId,
            'status' => 'proof_submitted',
        ]);
        $this->assertDatabaseHas('holds', [
            'id' => $holdId,
            'status' => 'active',
        ]);
    }

    public function test_refund_hold_fails_for_non_owner_business(): void
    {
        [$ownerBusiness] = $this->createUser('business');
        [$otherBusiness, $otherBusinessToken] = $this->createUser('business');
        [$creator] = $this->createUser('creator');
        $this->createWallet($ownerBusiness['id'], 'business', 700, 300);
        $this->createWallet($otherBusiness['id'], 'business', 1000, 0);
        $this->createWallet($creator['id'], 'creator', 0, 0);

        $campaignId = $this->createCampaign($ownerBusiness['id'], [
            'payout_amount_ghs' => 300,
            'status' => 'published',
        ]);
        $applicationId = $this->createApplicationRecord(
            $campaignId,
            $ownerBusiness['id'],
            $creator['id'],
            'approved_by_business'
        );
        $holdId = (string) Str::uuid();
        DB::table('holds')->insert([
            'id' => $holdId,
            'business_id' => $ownerBusiness['id'],
            'creator_id' => $creator['id'],
            'campaign_id' => $campaignId,
            'application_id' => $applicationId,
            'amount' => 300,
            'status' => 'active',
            'created_at' => now(),
            'updated_at' => now(),
        ]);

        $response = $this
            ->withHeader('Authorization', "Bearer {$otherBusinessToken}")
            ->postJson('/api/holds/refund', ['holdId' => $holdId]);

        $response->assertStatus(422);
        $response->assertJsonPath('message', 'Forbidden: only owner business can refund hold.');
        $this->assertDatabaseHas('holds', [
            'id' => $holdId,
            'status' => 'active',
        ]);
    }

    public function test_refund_hold_fails_when_hold_not_active(): void
    {
        [$business, $businessToken] = $this->createUser('business');
        [$creator] = $this->createUser('creator');
        $this->createWallet($business['id'], 'business', 1000, 0);
        $this->createWallet($creator['id'], 'creator', 0, 0);

        $campaignId = $this->createCampaign($business['id'], [
            'payout_amount_ghs' => 300,
            'status' => 'published',
        ]);
        $applicationId = $this->createApplicationRecord(
            $campaignId,
            $business['id'],
            $creator['id'],
            'paid'
        );
        $holdId = (string) Str::uuid();
        DB::table('holds')->insert([
            'id' => $holdId,
            'business_id' => $business['id'],
            'creator_id' => $creator['id'],
            'campaign_id' => $campaignId,
            'application_id' => $applicationId,
            'amount' => 300,
            'status' => 'released',
            'created_at' => now(),
            'updated_at' => now(),
        ]);

        $response = $this
            ->withHeader('Authorization', "Bearer {$businessToken}")
            ->postJson('/api/holds/refund', ['holdId' => $holdId]);

        $response->assertStatus(422);
        $response->assertJsonPath('message', 'Only active hold can be refunded.');
        $this->assertDatabaseMissing('wallet_ledger', [
            'wallet_user_id' => $business['id'],
            'type' => 'refund',
            'hold_id' => $holdId,
        ]);
    }

    public function test_idempotency_key_replays_deposit_without_double_credit(): void
    {
        [$business, $businessToken] = $this->createUser('business');
        $this->createWallet($business['id'], 'business', 100, 0);

        $key = 'deposit-001';
        $first = $this
            ->withHeader('Authorization', "Bearer {$businessToken}")
            ->withHeader('Idempotency-Key', $key)
            ->postJson('/api/wallet/deposit', ['amount' => 50]);

        $first->assertOk()->assertJson(['ok' => true]);

        $second = $this
            ->withHeader('Authorization', "Bearer {$businessToken}")
            ->withHeader('Idempotency-Key', $key)
            ->postJson('/api/wallet/deposit', ['amount' => 50]);

        $second
            ->assertOk()
            ->assertJson(['ok' => true])
            ->assertHeader('X-Idempotent-Replay', 'true');

        $wallet = DB::table('wallets')->where('user_id', $business['id'])->first();
        $this->assertSame(150, (int) $wallet->available_balance);
        $this->assertDatabaseCount('wallet_ledger', 1);
    }

    /**
     * @return array{0: array{id: string, email: string}, 1: string}
     */
    private function createUser(string $role): array
    {
        $id = (string) Str::uuid();
        $token = Str::random(80);
        DB::table('users')->insert([
            'id' => $id,
            'email' => "{$role}-{$id}@example.test",
            'password' => bcrypt('secret123'),
            'api_token' => hash('sha256', $token),
            'api_token_expires_at' => now()->addDay(),
            'display_name' => ucfirst($role).' User',
            'role' => $role,
            'created_at' => now(),
            'updated_at' => now(),
        ]);

        return [['id' => $id, 'email' => "{$role}-{$id}@example.test"], $token];
    }

    private function createWallet(string $userId, string $role, int $available, int $held): void
    {
        DB::table('wallets')->insert([
            'user_id' => $userId,
            'role' => $role,
            'available_balance' => $available,
            'held_balance' => $held,
            'version' => 0,
            'created_at' => now(),
            'updated_at' => now(),
        ]);
    }

    private function createCampaign(string $businessId, array $override = []): string
    {
        $id = (string) Str::uuid();
        DB::table('campaigns')->insert(array_merge([
            'id' => $id,
            'business_id' => $businessId,
            'title' => 'Test Campaign',
            'description' => 'Campaign description',
            'platform' => 'TikTok',
            'target_views' => 1000,
            'payout_amount_ghs' => 300,
            'creators_needed' => 1,
            'mention' => '@brand',
            'do_dont' => 'No unsafe content',
            'start_date' => now(),
            'end_date' => now()->addDays(7),
            'status' => 'published',
            'applicants_count' => 0,
            'approved_count' => 0,
            'created_at' => now(),
            'updated_at' => now(),
        ], $override));

        return $id;
    }

    private function createApplicationRecord(
        string $campaignId,
        string $businessId,
        string $creatorId,
        string $status
    ): string {
        $id = (string) Str::uuid();
        DB::table('applications')->insert([
            'id' => $id,
            'campaign_id' => $campaignId,
            'business_id' => $businessId,
            'creator_id' => $creatorId,
            'status' => $status,
            'applied_at' => now(),
            'created_at' => now(),
            'updated_at' => now(),
        ]);

        return $id;
    }
}
