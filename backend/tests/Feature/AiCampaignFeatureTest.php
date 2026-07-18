<?php

namespace Tests\Feature;

use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Http\Client\Request as ClientRequest;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Http;
use Illuminate\Support\Str;
use Tests\TestCase;

class AiCampaignFeatureTest extends TestCase
{
    use RefreshDatabase;

    public function test_business_can_generate_structured_campaign_brief_with_gpt_5_6(): void
    {
        [, $token] = $this->createUser('business');
        $this->configureOpenAi();

        $brief = [
            'title' => 'Mango Rush: First Sip Energy',
            'description' => 'Show a genuine first-sip reaction during a busy day.',
            'platform' => 'TikTok',
            'target_views' => 180000,
            'payout_amount_ghs' => 420,
            'creators_needed' => 12,
            'mention' => '@sparkbrewgh',
            'hashtags' => ['#SparkBrew', '#MangoRush', '#SipTheRush'],
            'do_dont' => 'Do show the can clearly. Do not make health claims.',
            'creator_profile' => 'Energetic Ghanaian lifestyle creators.',
            'success_metric' => 'Clear product recall and authentic reactions.',
            'content_angles' => [
                ['hook' => 'My 3pm reset', 'concept' => 'Desk-to-gym transition'],
                ['hook' => 'First sip check', 'concept' => 'Honest reaction'],
                ['hook' => 'Busy day fuel', 'concept' => 'Day-in-the-life'],
            ],
        ];
        Http::fake([
            'https://api.openai.com/v1/responses' => Http::response(
                $this->openAiEnvelope($brief),
            ),
        ]);

        $response = $this
            ->withHeader('Authorization', "Bearer {$token}")
            ->postJson('/api/ai/campaign-brief', [
                'productName' => 'Spark Brew Mango Rush',
                'productDescription' => 'A mango-flavoured energy drink for busy young adults.',
                'audience' => 'Ghanaian university students and young professionals',
                'campaignGoal' => 'Drive product awareness and authentic trial',
                'platform' => 'TikTok',
                'tone' => 'Energetic, credible, and playful',
                'targetViews' => 180000,
                'payoutAmountGhs' => 420,
                'creatorsNeeded' => 12,
                'brandMention' => '@sparkbrewgh',
            ]);

        $response
            ->assertOk()
            ->assertJsonPath('data.title', $brief['title'])
            ->assertJsonPath('data.content_angles.1.hook', 'First sip check')
            ->assertJsonPath('meta.requested_model', 'gpt-5.6')
            ->assertJsonPath('meta.model', 'gpt-5.6-sol')
            ->assertJsonPath('meta.feature', 'campaign_architect');

        Http::assertSent(function (ClientRequest $request): bool {
            return $request->url() === 'https://api.openai.com/v1/responses'
                && $request['model'] === 'gpt-5.6'
                && $request['store'] === false
                && $request['text']['format']['type'] === 'json_schema'
                && $request['text']['format']['strict'] === true
                && $request['text']['format']['name'] === 'campaign_architect'
                && str_contains(
                    $request['input'],
                    'Spark Brew Mango Rush',
                );
        });
    }

    public function test_creator_coach_uses_campaign_and_creator_context(): void
    {
        [$business] = $this->createUser('business');
        [$creator, $token] = $this->createUser('creator');
        $campaignId = $this->createCampaign($business['id']);
        $this->createCreatorProfile($creator['id']);
        DB::table('campaign_hashtags')->insert([
            'campaign_id' => $campaignId,
            'hashtag' => '#MangoRush',
            'created_at' => now(),
            'updated_at' => now(),
        ]);
        $this->configureOpenAi();

        $coach = [
            'score' => 78,
            'verdict' => 'revise',
            'summary' => 'Strong hook, but two campaign requirements are missing.',
            'strengths' => ['Authentic opening', 'Clear product moment'],
            'missing_requirements' => ['Add @sparkbrewgh', 'Add #MangoRush'],
            'risk_flags' => ['Remove the unsupported health claim'],
            'recommended_hook' => 'My honest 3pm Mango Rush reset',
            'revised_draft' => 'My honest 3pm reset with @sparkbrewgh.',
            'shot_list' => ['Show unopened can', 'Capture first sip reaction'],
            'checklist' => [
                [
                    'requirement' => 'Brand mention',
                    'status' => 'missing',
                    'evidence' => 'The draft does not include @sparkbrewgh.',
                ],
            ],
        ];
        Http::fake([
            'https://api.openai.com/v1/responses' => Http::response(
                $this->openAiEnvelope($coach),
            ),
        ]);

        $response = $this
            ->withHeader('Authorization', "Bearer {$token}")
            ->postJson("/api/ai/campaigns/{$campaignId}/creator-coach", [
                'draft' => 'This drink cures tiredness. Watch my first sip before class!',
            ]);

        $response
            ->assertOk()
            ->assertJsonPath('data.score', 78)
            ->assertJsonPath('data.verdict', 'revise')
            ->assertJsonPath(
                'data.missing_requirements.0',
                'Add @sparkbrewgh',
            )
            ->assertJsonPath('meta.feature', 'creator_coach');

        Http::assertSent(function (ClientRequest $request): bool {
            return $request['text']['format']['name'] === 'creator_coach'
                && str_contains($request['input'], 'Lifestyle creator in Accra')
                && str_contains($request['input'], '#MangoRush')
                && str_contains($request['input'], 'cures tiredness');
        });
    }

    public function test_ai_endpoints_enforce_roles_before_spending_tokens(): void
    {
        [, $creatorToken] = $this->createUser('creator');
        $this->configureOpenAi();
        Http::fake();

        $this
            ->withHeader('Authorization', "Bearer {$creatorToken}")
            ->postJson('/api/ai/campaign-brief', [
                'productName' => 'Test Product',
                'productDescription' => str_repeat('Description ', 3),
                'audience' => 'Creators',
                'campaignGoal' => 'Awareness',
                'platform' => 'TikTok',
                'tone' => 'Direct',
                'targetViews' => 1000,
                'payoutAmountGhs' => 100,
                'creatorsNeeded' => 1,
            ])
            ->assertForbidden();

        Http::assertNothingSent();
    }

    public function test_missing_openai_key_returns_safe_configuration_error(): void
    {
        [, $token] = $this->createUser('business');
        config()->set('openai.api_key', '');
        Http::fake();

        $this
            ->withHeader('Authorization', "Bearer {$token}")
            ->postJson('/api/ai/campaign-brief', [
                'productName' => 'Test Product',
                'productDescription' => str_repeat('Description ', 3),
                'audience' => 'Creators',
                'campaignGoal' => 'Awareness',
                'platform' => 'TikTok',
                'tone' => 'Direct',
                'targetViews' => 1000,
                'payoutAmountGhs' => 100,
                'creatorsNeeded' => 1,
            ])
            ->assertStatus(503)
            ->assertJson([
                'message' => 'AI features are not configured on this server.',
            ]);

        Http::assertNothingSent();
    }

    private function configureOpenAi(): void
    {
        config()->set('openai.api_key', 'test-key');
        config()->set('openai.base_url', 'https://api.openai.com/v1');
        config()->set('openai.model', 'gpt-5.6');
        config()->set('openai.reasoning_effort', 'low');
    }

    private function openAiEnvelope(array $data): array
    {
        return [
            'id' => 'resp_build_week_test',
            'model' => 'gpt-5.6-sol',
            'output' => [
                [
                    'type' => 'message',
                    'content' => [
                        [
                            'type' => 'output_text',
                            'text' => json_encode($data, JSON_THROW_ON_ERROR),
                        ],
                    ],
                ],
            ],
            'usage' => [
                'input_tokens' => 250,
                'output_tokens' => 400,
                'total_tokens' => 650,
            ],
        ];
    }

    /**
     * @return array{0: array{id: string}, 1: string}
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

        return [['id' => $id], $token];
    }

    private function createCampaign(string $businessId): string
    {
        $id = (string) Str::uuid();
        DB::table('campaigns')->insert([
            'id' => $id,
            'business_id' => $businessId,
            'title' => 'Spark Brew Mango Rush',
            'description' => 'Film an honest first-sip reaction before class.',
            'platform' => 'TikTok',
            'target_views' => 10000,
            'payout_amount_ghs' => 300,
            'creators_needed' => 2,
            'mention' => '@sparkbrewgh',
            'do_dont' => 'Show the can. Do not make health claims.',
            'start_date' => now(),
            'end_date' => now()->addWeek(),
            'status' => 'published',
            'applicants_count' => 0,
            'approved_count' => 0,
            'created_at' => now(),
            'updated_at' => now(),
        ]);

        return $id;
    }

    private function createCreatorProfile(string $creatorId): void
    {
        DB::table('creator_profiles')->insert([
            'user_id' => $creatorId,
            'bio' => 'Lifestyle creator in Accra',
            'country' => 'Ghana',
            'city' => 'Accra',
            'followers' => 42000,
            'avg_views' => 15000,
            'engagement_rate' => 7.5,
            'created_at' => now(),
            'updated_at' => now(),
        ]);
        DB::table('creator_niches')->insert([
            'user_id' => $creatorId,
            'niche' => 'Lifestyle',
            'created_at' => now(),
            'updated_at' => now(),
        ]);
        DB::table('creator_handles')->insert([
            'id' => (string) Str::uuid(),
            'user_id' => $creatorId,
            'platform' => 'TikTok',
            'username' => '@creator',
            'profile_url' => 'https://example.test/@creator',
            'verified' => true,
            'created_at' => now(),
            'updated_at' => now(),
        ]);
    }
}
