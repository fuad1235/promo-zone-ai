<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Str;

class CampaignController extends Controller
{
    public function index(Request $request): JsonResponse
    {
        $query = DB::table('campaigns')->where('status', 'published');

        if ($request->filled('platform')) {
            $query->where('platform', $request->string('platform'));
        }
        if ($request->filled('minPayout')) {
            $query->where('payout_amount_ghs', '>=', (int) $request->input('minPayout'));
        }
        if ($request->filled('maxPayout')) {
            $query->where('payout_amount_ghs', '<=', (int) $request->input('maxPayout'));
        }

        $campaigns = $query->orderByDesc('created_at')->limit(50)->get();
        return response()->json(['data' => $this->enrichCampaigns($campaigns)]);
    }

    public function myCampaigns(Request $request): JsonResponse
    {
        $campaigns = DB::table('campaigns')
            ->where('business_id', $request->user()->id)
            ->orderByDesc('created_at')
            ->limit(50)
            ->get();

        return response()->json(['data' => $this->enrichCampaigns($campaigns)]);
    }

    public function show(Request $request, string $campaignId): JsonResponse
    {
        $campaign = DB::table('campaigns')->where('id', $campaignId)->first();
        if (!$campaign) {
            return response()->json(['message' => 'Campaign not found'], 404);
        }

        if ($campaign->status !== 'published') {
            $user = $request->user();
            $ownsCampaign = $user && $user->id === $campaign->business_id;
            if (!$ownsCampaign) {
                return response()->json(['message' => 'Campaign not found'], 404);
            }
        }

        return response()->json($this->enrichCampaign($campaign));
    }

    public function store(Request $request): JsonResponse
    {
        $data = $request->validate([
            'title' => ['required', 'string', 'max:180'],
            'description' => ['required', 'string'],
            'platform' => ['required', 'string', 'max:50'],
            'targetViews' => ['required', 'integer', 'min:1'],
            'payoutAmountGhs' => ['required', 'integer', 'min:1'],
            'creatorsNeeded' => ['required', 'integer', 'min:1'],
            'hashtags' => ['array'],
            'hashtags.*' => ['string', 'max:40'],
            'mention' => ['nullable', 'string', 'max:120'],
            'doDont' => ['required', 'string'],
            'productImages' => ['array'],
            'productImages.*' => ['string'],
            'startDate' => ['required', 'date'],
            'endDate' => ['required', 'date', 'after_or_equal:startDate'],
            'status' => ['required', 'in:draft,published'],
        ]);

        $campaignId = (string) Str::uuid();

        DB::transaction(function () use ($request, $data, $campaignId): void {
            DB::table('campaigns')->insert([
                'id' => $campaignId,
                'business_id' => $request->user()->id,
                'title' => $data['title'],
                'description' => $data['description'],
                'platform' => $data['platform'],
                'target_views' => $data['targetViews'],
                'payout_amount_ghs' => $data['payoutAmountGhs'],
                'creators_needed' => $data['creatorsNeeded'],
                'mention' => $data['mention'] ?? null,
                'do_dont' => $data['doDont'],
                'start_date' => $data['startDate'],
                'end_date' => $data['endDate'],
                'status' => $data['status'],
                'created_at' => now(),
                'updated_at' => now(),
            ]);

            foreach ($data['hashtags'] ?? [] as $hashtag) {
                DB::table('campaign_hashtags')->insert([
                    'campaign_id' => $campaignId,
                    'hashtag' => $hashtag,
                    'created_at' => now(),
                    'updated_at' => now(),
                ]);
            }

            foreach ($data['productImages'] ?? [] as $url) {
                DB::table('campaign_media')->insert([
                    'campaign_id' => $campaignId,
                    'url' => $url,
                    'created_at' => now(),
                    'updated_at' => now(),
                ]);
            }
        });

        return response()->json(['id' => $campaignId], 201);
    }

    public function update(Request $request, string $campaignId): JsonResponse
    {
        $campaign = DB::table('campaigns')->where('id', $campaignId)->first();
        if (!$campaign) {
            return response()->json(['message' => 'Campaign not found'], 404);
        }
        if ($campaign->business_id !== $request->user()->id) {
            return response()->json(['message' => 'Forbidden'], 403);
        }

        $data = $request->validate([
            'title' => ['sometimes', 'string', 'max:180'],
            'description' => ['sometimes', 'string'],
            'platform' => ['sometimes', 'string', 'max:50'],
            'targetViews' => ['sometimes', 'integer', 'min:1'],
            'payoutAmountGhs' => ['sometimes', 'integer', 'min:1'],
            'creatorsNeeded' => ['sometimes', 'integer', 'min:1'],
            'hashtags' => ['sometimes', 'array'],
            'hashtags.*' => ['string', 'max:40'],
            'mention' => ['nullable', 'string', 'max:120'],
            'doDont' => ['sometimes', 'string'],
            'productImages' => ['sometimes', 'array'],
            'productImages.*' => ['string'],
            'startDate' => ['sometimes', 'date'],
            'endDate' => ['sometimes', 'date'],
            'status' => ['sometimes', 'in:draft,published,closed'],
        ]);

        DB::transaction(function () use ($campaignId, $data): void {
            $update = [];
            if (isset($data['title'])) $update['title'] = $data['title'];
            if (isset($data['description'])) $update['description'] = $data['description'];
            if (isset($data['platform'])) $update['platform'] = $data['platform'];
            if (isset($data['targetViews'])) $update['target_views'] = $data['targetViews'];
            if (isset($data['payoutAmountGhs'])) $update['payout_amount_ghs'] = $data['payoutAmountGhs'];
            if (isset($data['creatorsNeeded'])) $update['creators_needed'] = $data['creatorsNeeded'];
            if (array_key_exists('mention', $data)) $update['mention'] = $data['mention'];
            if (isset($data['doDont'])) $update['do_dont'] = $data['doDont'];
            if (isset($data['startDate'])) $update['start_date'] = $data['startDate'];
            if (isset($data['endDate'])) $update['end_date'] = $data['endDate'];
            if (isset($data['status'])) $update['status'] = $data['status'];
            $update['updated_at'] = now();

            if (!empty($update)) {
                DB::table('campaigns')->where('id', $campaignId)->update($update);
            }

            if (isset($data['hashtags'])) {
                DB::table('campaign_hashtags')->where('campaign_id', $campaignId)->delete();
                foreach ($data['hashtags'] as $hashtag) {
                    DB::table('campaign_hashtags')->insert([
                        'campaign_id' => $campaignId,
                        'hashtag' => $hashtag,
                        'created_at' => now(),
                        'updated_at' => now(),
                    ]);
                }
            }

            if (isset($data['productImages'])) {
                DB::table('campaign_media')->where('campaign_id', $campaignId)->delete();
                foreach ($data['productImages'] as $url) {
                    DB::table('campaign_media')->insert([
                        'campaign_id' => $campaignId,
                        'url' => $url,
                        'created_at' => now(),
                        'updated_at' => now(),
                    ]);
                }
            }
        });

        return response()->json(['ok' => true]);
    }

    private function enrichCampaigns($campaigns): array
    {
        return collect($campaigns)->map(fn ($campaign) => $this->enrichCampaign($campaign))->all();
    }

    private function enrichCampaign(object $campaign): array
    {
        $hashtags = DB::table('campaign_hashtags')
            ->where('campaign_id', $campaign->id)
            ->pluck('hashtag')
            ->values()
            ->all();

        $images = DB::table('campaign_media')
            ->where('campaign_id', $campaign->id)
            ->pluck('url')
            ->values()
            ->all();

        return [
            'id' => $campaign->id,
            'business_id' => $campaign->business_id,
            'title' => $campaign->title,
            'description' => $campaign->description,
            'platform' => $campaign->platform,
            'target_views' => $campaign->target_views,
            'payout_amount_ghs' => $campaign->payout_amount_ghs,
            'creators_needed' => $campaign->creators_needed,
            'mention' => $campaign->mention,
            'do_dont' => $campaign->do_dont,
            'start_date' => $campaign->start_date,
            'end_date' => $campaign->end_date,
            'status' => $campaign->status,
            'applicants_count' => $campaign->applicants_count,
            'approved_count' => $campaign->approved_count,
            'product_images' => $images,
            'hashtags' => $hashtags,
            'created_at' => $campaign->created_at,
            'updated_at' => $campaign->updated_at,
        ];
    }
}
