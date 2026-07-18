<?php

namespace Database\Seeders;

use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Hash;

class PromoMarketplaceSeeder extends Seeder
{
    public function run(): void
    {
        $now = now();
        $passwordHash = Hash::make('Password@123');

        $businessUsers = [
            [
                'id' => '11111111-1111-4111-8111-111111111111',
                'email' => 'sparkbrew@promozone.test',
                'display_name' => 'Spark Brew Ghana',
                'company_name' => 'Spark Brew Beverages',
                'website' => 'https://sparkbrew.example',
            ],
            [
                'id' => '11111111-1111-4111-8111-111111111112',
                'email' => 'vitalglow@promozone.test',
                'display_name' => 'Vital Glow Labs',
                'company_name' => 'Vital Glow Labs',
                'website' => 'https://vitalglow.example',
            ],
            [
                'id' => '11111111-1111-4111-8111-111111111113',
                'email' => 'tekdrive@promozone.test',
                'display_name' => 'TekDrive Mobile',
                'company_name' => 'TekDrive Mobile',
                'website' => 'https://tekdrive.example',
            ],
        ];

        $creatorUsers = [
            [
                'id' => '22222222-2222-4222-8222-222222222221',
                'email' => 'ama.creator@promozone.test',
                'display_name' => 'Ama Creates',
                'phone' => '+233240000101',
                'bio' => 'UGC creator focused on beauty, lifestyle, and short-form product reviews.',
                'niches' => ['Beauty', 'Lifestyle', 'UGC'],
                'followers' => 42800,
                'avg_views' => 15300,
                'engagement_rate' => 7.80,
                'handle' => [
                    'id' => '44444444-4444-4444-8444-444444444441',
                    'platform' => 'TikTok',
                    'username' => '@ama.creates',
                    'profile_url' => 'https://www.tiktok.com/@ama.creates',
                ],
            ],
            [
                'id' => '22222222-2222-4222-8222-222222222222',
                'email' => 'kwame.reviews@promozone.test',
                'display_name' => 'Kwame Reviews',
                'phone' => '+233240000102',
                'bio' => 'Tech and gadgets storyteller. Product demos, unboxing, and conversion-focused hooks.',
                'niches' => ['Tech', 'Gadgets', 'Reviews'],
                'followers' => 69300,
                'avg_views' => 27100,
                'engagement_rate' => 6.25,
                'handle' => [
                    'id' => '44444444-4444-4444-8444-444444444442',
                    'platform' => 'Instagram',
                    'username' => '@kwamereviews',
                    'profile_url' => 'https://www.instagram.com/kwamereviews',
                ],
            ],
        ];

        foreach ($businessUsers as $business) {
            DB::table('users')->updateOrInsert(
                ['email' => $business['email']],
                [
                    'id' => $business['id'],
                    'password' => $passwordHash,
                    'display_name' => $business['display_name'],
                    'role' => 'business',
                    'phone' => null,
                    'updated_at' => $now,
                    'created_at' => $now,
                ]
            );
        }

        foreach ($creatorUsers as $creator) {
            DB::table('users')->updateOrInsert(
                ['email' => $creator['email']],
                [
                    'id' => $creator['id'],
                    'password' => $passwordHash,
                    'display_name' => $creator['display_name'],
                    'role' => 'creator',
                    'phone' => $creator['phone'],
                    'updated_at' => $now,
                    'created_at' => $now,
                ]
            );
        }

        $businessIdsByEmail = DB::table('users')
            ->whereIn('email', array_map(fn (array $business): string => $business['email'], $businessUsers))
            ->pluck('id', 'email')
            ->all();

        $creatorIdsByEmail = DB::table('users')
            ->whereIn('email', array_map(fn (array $creator): string => $creator['email'], $creatorUsers))
            ->pluck('id', 'email')
            ->all();

        foreach ($businessUsers as $business) {
            $businessId = $businessIdsByEmail[$business['email']] ?? null;
            if (!$businessId) {
                continue;
            }

            DB::table('business_profiles')->updateOrInsert(
                ['user_id' => $businessId],
                [
                    'company_name' => $business['company_name'],
                    'website' => $business['website'],
                    'contact_phone' => null,
                    'verified' => true,
                    'updated_at' => $now,
                    'created_at' => $now,
                ]
            );

            DB::table('wallets')->updateOrInsert(
                ['user_id' => $businessId],
                [
                    'role' => 'business',
                    'available_balance' => 250000,
                    'held_balance' => 0,
                    'version' => 0,
                    'updated_at' => $now,
                    'created_at' => $now,
                ]
            );
        }

        foreach ($creatorUsers as $creator) {
            $creatorId = $creatorIdsByEmail[$creator['email']] ?? null;
            if (!$creatorId) {
                continue;
            }

            DB::table('creator_profiles')->updateOrInsert(
                ['user_id' => $creatorId],
                [
                    'bio' => $creator['bio'],
                    'country' => 'Ghana',
                    'city' => 'Accra',
                    'payout_type' => 'momo',
                    'payout_network' => 'MTN',
                    'payout_number' => $creator['phone'],
                    'followers' => $creator['followers'],
                    'avg_views' => $creator['avg_views'],
                    'engagement_rate' => $creator['engagement_rate'],
                    'updated_at' => $now,
                    'created_at' => $now,
                ]
            );

            DB::table('creator_niches')->where('user_id', $creatorId)->delete();
            foreach ($creator['niches'] as $niche) {
                DB::table('creator_niches')->insert([
                    'user_id' => $creatorId,
                    'niche' => $niche,
                    'created_at' => $now,
                    'updated_at' => $now,
                ]);
            }

            DB::table('creator_handles')->updateOrInsert(
                ['id' => $creator['handle']['id']],
                [
                    'user_id' => $creatorId,
                    'platform' => $creator['handle']['platform'],
                    'username' => $creator['handle']['username'],
                    'profile_url' => $creator['handle']['profile_url'],
                    'verified' => true,
                    'updated_at' => $now,
                    'created_at' => $now,
                ]
            );

            DB::table('wallets')->updateOrInsert(
                ['user_id' => $creatorId],
                [
                    'role' => 'creator',
                    'available_balance' => 32000,
                    'held_balance' => 4000,
                    'version' => 0,
                    'updated_at' => $now,
                    'created_at' => $now,
                ]
            );
        }

        $campaigns = [
            [
                'id' => '33333333-3333-4333-8333-333333333331',
                'business_email' => 'sparkbrew@promozone.test',
                'title' => 'Spark Brew Mango Rush Launch',
                'description' => 'Create a fast-paced unboxing + first-sip reaction reel for our new Mango Rush energy drink.',
                'platform' => 'TikTok',
                'target_views' => 180000,
                'payout' => 420,
                'creators_needed' => 12,
                'mention' => '@sparkbrewgh',
                'do_dont' => 'Do: energetic hooks and close-up product shots. Dont: claim medical benefits.',
                'start_days' => -2,
                'end_days' => 10,
                'hashtags' => ['#SparkBrew', '#MangoRush', '#SipTheRush'],
                'images' => [
                    'https://images.unsplash.com/photo-1544145945-f90425340c7e',
                    'https://images.unsplash.com/photo-1513558161293-cdaf765ed2fd',
                ],
            ],
            [
                'id' => '33333333-3333-4333-8333-333333333332',
                'business_email' => 'vitalglow@promozone.test',
                'title' => 'Vital Glow 14-Day Skin Reset',
                'description' => 'Show your morning routine using our cleanser and serum combo with before/after storytelling.',
                'platform' => 'Instagram',
                'target_views' => 130000,
                'payout' => 360,
                'creators_needed' => 9,
                'mention' => '@vitalglowlabs',
                'do_dont' => 'Do: real routine shots. Dont: edit skin texture aggressively.',
                'start_days' => -1,
                'end_days' => 14,
                'hashtags' => ['#VitalGlow', '#SkinReset', '#GlowRoutine'],
                'images' => [
                    'https://images.unsplash.com/photo-1556228720-195a672e8a03',
                    'https://images.unsplash.com/photo-1522335789203-aabd1fc54bc9',
                ],
            ],
            [
                'id' => '33333333-3333-4333-8333-333333333333',
                'business_email' => 'tekdrive@promozone.test',
                'title' => 'TekDrive SnapCharge Powerbank Demo',
                'description' => 'Film a practical day-in-the-life test proving battery recovery speed during commute and work.',
                'platform' => 'YouTube',
                'target_views' => 220000,
                'payout' => 700,
                'creators_needed' => 6,
                'mention' => '@tekdrivemobile',
                'do_dont' => 'Do: battery percentage proof shots. Dont: compare against unnamed competitors.',
                'start_days' => -3,
                'end_days' => 18,
                'hashtags' => ['#TekDrive', '#SnapCharge', '#TechDaily'],
                'images' => [
                    'https://images.unsplash.com/photo-1511707171634-5f897ff02aa9',
                    'https://images.unsplash.com/photo-1512499617640-c74ae3a79d37',
                ],
            ],
            [
                'id' => '33333333-3333-4333-8333-333333333334',
                'business_email' => 'sparkbrew@promozone.test',
                'title' => 'Spark Brew Campus Vibes Challenge',
                'description' => 'Create trend-led UGC around study breaks and sports moments featuring Spark Brew cans.',
                'platform' => 'TikTok',
                'target_views' => 90000,
                'payout' => 240,
                'creators_needed' => 15,
                'mention' => '@sparkbrewgh',
                'do_dont' => 'Do: energetic transitions. Dont: unsafe stunts.',
                'start_days' => 0,
                'end_days' => 8,
                'hashtags' => ['#CampusVibes', '#SparkBrew', '#EnergyMoments'],
                'images' => [
                    'https://images.unsplash.com/photo-1470337458703-46ad1756a187',
                ],
            ],
            [
                'id' => '33333333-3333-4333-8333-333333333335',
                'business_email' => 'vitalglow@promozone.test',
                'title' => 'Night Repair Routine UGC',
                'description' => 'Capture a calm night skincare routine featuring Vital Glow Night Repair drops.',
                'platform' => 'Instagram',
                'target_views' => 76000,
                'payout' => 280,
                'creators_needed' => 10,
                'mention' => '@vitalglowlabs',
                'do_dont' => 'Do: natural lighting and honest texture shots. Dont: make treatment claims.',
                'start_days' => -4,
                'end_days' => 7,
                'hashtags' => ['#NightRepair', '#VitalGlow', '#SkincareUGC'],
                'images' => [
                    'https://images.unsplash.com/photo-1617897903246-719242758050',
                ],
            ],
            [
                'id' => '33333333-3333-4333-8333-333333333336',
                'business_email' => 'tekdrive@promozone.test',
                'title' => 'Wireless Earbuds Office Test',
                'description' => 'Record call quality, noise cancellation, and comfort in a real office environment.',
                'platform' => 'X',
                'target_views' => 64000,
                'payout' => 310,
                'creators_needed' => 8,
                'mention' => '@tekdrivemobile',
                'do_dont' => 'Do: include sound test snippets. Dont: use copyrighted background music.',
                'start_days' => -2,
                'end_days' => 9,
                'hashtags' => ['#TekDriveAudio', '#WorkFromAnywhere', '#CreatorReview'],
                'images' => [
                    'https://images.unsplash.com/photo-1505740420928-5e560c06d30e',
                ],
            ],
            [
                'id' => '33333333-3333-4333-8333-333333333337',
                'business_email' => 'sparkbrew@promozone.test',
                'title' => 'Spark Brew Street Fitness Collab',
                'description' => 'Show your pre-workout routine and post-session refresh with Spark Brew Zero Sugar.',
                'platform' => 'Instagram',
                'target_views' => 115000,
                'payout' => 390,
                'creators_needed' => 7,
                'mention' => '@sparkbrewgh',
                'do_dont' => 'Do: authentic workout footage. Dont: include unsafe exercise form tips.',
                'start_days' => 1,
                'end_days' => 12,
                'hashtags' => ['#SparkBrewZero', '#FitnessFuel', '#CreatorCollab'],
                'images' => [
                    'https://images.unsplash.com/photo-1517836357463-d25dfeac3438',
                ],
            ],
            [
                'id' => '33333333-3333-4333-8333-333333333338',
                'business_email' => 'vitalglow@promozone.test',
                'title' => 'Hydra Mist Desk Reset',
                'description' => 'Create short productivity clips and include a refresh moment using Vital Glow Hydra Mist.',
                'platform' => 'TikTok',
                'target_views' => 88000,
                'payout' => 260,
                'creators_needed' => 11,
                'mention' => '@vitalglowlabs',
                'do_dont' => 'Do: showcase practical everyday use. Dont: over-edit color tones.',
                'start_days' => -1,
                'end_days' => 11,
                'hashtags' => ['#HydraMist', '#DeskReset', '#DailyGlow'],
                'images' => [
                    'https://images.unsplash.com/photo-1596462502278-27bfdc403348',
                ],
            ],
        ];

        foreach ($campaigns as $campaign) {
            $businessId = $businessIdsByEmail[$campaign['business_email']] ?? null;
            if (!$businessId) {
                continue;
            }

            $startDate = now()->addDays($campaign['start_days']);
            $endDate = now()->addDays($campaign['end_days']);

            DB::table('campaigns')->updateOrInsert(
                ['id' => $campaign['id']],
                [
                    'business_id' => $businessId,
                    'title' => $campaign['title'],
                    'description' => $campaign['description'],
                    'platform' => $campaign['platform'],
                    'target_views' => $campaign['target_views'],
                    'payout_amount_ghs' => $campaign['payout'],
                    'creators_needed' => $campaign['creators_needed'],
                    'mention' => $campaign['mention'],
                    'do_dont' => $campaign['do_dont'],
                    'start_date' => $startDate,
                    'end_date' => $endDate,
                    'status' => 'published',
                    'updated_at' => $now,
                    'created_at' => $now,
                ]
            );

            DB::table('campaign_hashtags')->where('campaign_id', $campaign['id'])->delete();
            foreach ($campaign['hashtags'] as $hashtag) {
                DB::table('campaign_hashtags')->insert([
                    'campaign_id' => $campaign['id'],
                    'hashtag' => $hashtag,
                    'created_at' => $now,
                    'updated_at' => $now,
                ]);
            }

            DB::table('campaign_media')->where('campaign_id', $campaign['id'])->delete();
            foreach ($campaign['images'] as $url) {
                DB::table('campaign_media')->insert([
                    'campaign_id' => $campaign['id'],
                    'url' => $url,
                    'created_at' => $now,
                    'updated_at' => $now,
                ]);
            }
        }

        $applications = [
            [
                'id' => '55555555-5555-4555-8555-555555555551',
                'campaign_id' => '33333333-3333-4333-8333-333333333331',
                'creator_email' => 'ama.creator@promozone.test',
                'creator_handle_id' => '44444444-4444-4444-8444-444444444441',
                'status' => 'proof_submitted',
            ],
            [
                'id' => '55555555-5555-4555-8555-555555555552',
                'campaign_id' => '33333333-3333-4333-8333-333333333332',
                'creator_email' => 'ama.creator@promozone.test',
                'creator_handle_id' => '44444444-4444-4444-8444-444444444441',
                'status' => 'sample_approved',
            ],
            [
                'id' => '55555555-5555-4555-8555-555555555553',
                'campaign_id' => '33333333-3333-4333-8333-333333333333',
                'creator_email' => 'kwame.reviews@promozone.test',
                'creator_handle_id' => '44444444-4444-4444-8444-444444444442',
                'status' => 'approved_by_business',
            ],
            [
                'id' => '55555555-5555-4555-8555-555555555554',
                'campaign_id' => '33333333-3333-4333-8333-333333333336',
                'creator_email' => 'kwame.reviews@promozone.test',
                'creator_handle_id' => '44444444-4444-4444-8444-444444444442',
                'status' => 'paid',
            ],
        ];

        foreach ($applications as $application) {
            $creatorId = $creatorIdsByEmail[$application['creator_email']] ?? null;
            $campaign = DB::table('campaigns')->where('id', $application['campaign_id'])->first();
            if (!$creatorId || !$campaign) {
                continue;
            }

            $status = $application['status'];
            DB::table('applications')->updateOrInsert(
                ['id' => $application['id']],
                [
                    'campaign_id' => $application['campaign_id'],
                    'business_id' => $campaign->business_id,
                    'creator_id' => $creatorId,
                    'creator_handle_id' => $application['creator_handle_id'],
                    'status' => $status,
                    'applied_at' => now()->subDays(3),
                    'approved_at' => in_array($status, [
                        'approved_by_business',
                        'sample_submitted',
                        'sample_approved',
                        'sample_rejected',
                        'posted',
                        'proof_submitted',
                        'proof_approved',
                        'proof_rejected',
                        'paid',
                    ], true) ? now()->subDays(2) : null,
                    'sample_submitted_at' => in_array($status, [
                        'sample_submitted',
                        'sample_approved',
                        'sample_rejected',
                        'posted',
                        'proof_submitted',
                        'proof_approved',
                        'proof_rejected',
                        'paid',
                    ], true) ? now()->subDay() : null,
                    'sample_approved_at' => in_array($status, [
                        'sample_approved',
                        'posted',
                        'proof_submitted',
                        'proof_approved',
                        'proof_rejected',
                        'paid',
                    ], true) ? now()->subDay() : null,
                    'posted_at' => in_array($status, [
                        'posted',
                        'proof_submitted',
                        'proof_approved',
                        'proof_rejected',
                        'paid',
                    ], true) ? now()->subHours(20) : null,
                    'proof_submitted_at' => in_array($status, [
                        'proof_submitted',
                        'proof_approved',
                        'proof_rejected',
                        'paid',
                    ], true) ? now()->subHours(8) : null,
                    'proof_approved_at' => in_array($status, [
                        'proof_approved',
                        'paid',
                    ], true) ? now()->subHours(2) : null,
                    'paid_at' => $status === 'paid' ? now()->subHour() : null,
                    'updated_at' => $now,
                    'created_at' => $now,
                ]
            );
        }

        $campaignIds = array_map(fn (array $campaign): string => $campaign['id'], $campaigns);
        $applicationCounts = DB::table('applications')
            ->whereIn('campaign_id', $campaignIds)
            ->selectRaw('campaign_id, COUNT(*) as applicants_count')
            ->groupBy('campaign_id')
            ->pluck('applicants_count', 'campaign_id')
            ->all();

        $approvedCounts = DB::table('applications')
            ->whereIn('campaign_id', $campaignIds)
            ->whereIn('status', [
                'approved_by_business',
                'sample_submitted',
                'sample_approved',
                'posted',
                'proof_submitted',
                'proof_approved',
                'paid',
            ])
            ->selectRaw('campaign_id, COUNT(*) as approved_count')
            ->groupBy('campaign_id')
            ->pluck('approved_count', 'campaign_id')
            ->all();

        foreach ($campaignIds as $campaignId) {
            DB::table('campaigns')->where('id', $campaignId)->update([
                'applicants_count' => $applicationCounts[$campaignId] ?? 0,
                'approved_count' => $approvedCounts[$campaignId] ?? 0,
                'updated_at' => $now,
            ]);
        }
    }
}
