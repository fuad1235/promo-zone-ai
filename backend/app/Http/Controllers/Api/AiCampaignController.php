<?php

namespace App\Http\Controllers\Api;

use App\Exceptions\OpenAiConfigurationException;
use App\Http\Controllers\Controller;
use App\Services\OpenAiCampaignService;
use Illuminate\Http\Client\ConnectionException;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Log;
use Throwable;

class AiCampaignController extends Controller
{
    public function campaignBrief(
        Request $request,
        OpenAiCampaignService $service,
    ): JsonResponse {
        $data = $request->validate([
            'productName' => ['required', 'string', 'max:120'],
            'productDescription' => [
                'required',
                'string',
                'min:20',
                'max:1500',
            ],
            'audience' => ['required', 'string', 'min:3', 'max:500'],
            'campaignGoal' => ['required', 'string', 'min:3', 'max:500'],
            'platform' => ['required', 'in:TikTok,Instagram,YouTube,X'],
            'tone' => ['required', 'string', 'max:120'],
            'targetViews' => [
                'required',
                'integer',
                'min:1',
                'max:1000000000',
            ],
            'payoutAmountGhs' => [
                'required',
                'integer',
                'min:1',
                'max:100000000',
            ],
            'creatorsNeeded' => [
                'required',
                'integer',
                'min:1',
                'max:10000',
            ],
            'brandMention' => ['nullable', 'string', 'max:120'],
        ]);

        try {
            return response()->json($service->generateCampaignBrief($data));
        } catch (Throwable $exception) {
            return $this->failure($request, 'campaign_architect', $exception);
        }
    }

    public function creatorCoach(
        Request $request,
        OpenAiCampaignService $service,
        string $campaignId,
    ): JsonResponse {
        $data = $request->validate([
            'draft' => ['required', 'string', 'min:20', 'max:5000'],
        ]);

        $campaign = DB::table('campaigns')->where('id', $campaignId)->first();
        if (! $campaign || $campaign->status !== 'published') {
            return response()->json(['message' => 'Campaign not found'], 404);
        }

        $hashtags = DB::table('campaign_hashtags')
            ->where('campaign_id', $campaignId)
            ->pluck('hashtag')
            ->values()
            ->all();

        $profile = DB::table('creator_profiles')
            ->where('user_id', $request->user()->id)
            ->first();
        $niches = DB::table('creator_niches')
            ->where('user_id', $request->user()->id)
            ->pluck('niche')
            ->values()
            ->all();
        $handle = DB::table('creator_handles')
            ->where('user_id', $request->user()->id)
            ->where('platform', $campaign->platform)
            ->first();

        $campaignContext = [
            'title' => $campaign->title,
            'description' => $campaign->description,
            'platform' => $campaign->platform,
            'target_views' => (int) $campaign->target_views,
            'mention' => $campaign->mention ?? '',
            'hashtags' => $hashtags,
            'do_dont' => $campaign->do_dont,
            'end_date' => $campaign->end_date,
        ];
        $creatorContext = [
            'display_name' => $request->user()->display_name,
            'bio' => $profile->bio ?? '',
            'niches' => $niches,
            'followers' => (int) ($profile->followers ?? 0),
            'average_views' => (int) ($profile->avg_views ?? 0),
            'engagement_rate' => (float) ($profile->engagement_rate ?? 0),
            'platform_username' => $handle->username ?? '',
        ];

        try {
            return response()->json(
                $service->coachCreatorDraft(
                    $campaignContext,
                    $creatorContext,
                    $data['draft'],
                ),
            );
        } catch (Throwable $exception) {
            return $this->failure($request, 'creator_coach', $exception);
        }
    }

    private function failure(
        Request $request,
        string $feature,
        Throwable $exception,
    ): JsonResponse {
        Log::warning('openai_feature_failed', [
            'feature' => $feature,
            'user_id' => $request->user()?->id,
            'request_id' => $request->attributes->get('request_id'),
            'exception' => $exception::class,
            'message' => $exception->getMessage(),
        ]);

        if ($exception instanceof OpenAiConfigurationException) {
            return response()->json([
                'message' => 'AI features are not configured on this server.',
            ], 503);
        }

        $message = $exception instanceof ConnectionException
            ? 'AI service could not be reached. Please try again.'
            : 'AI service is temporarily unavailable. Please try again.';

        return response()->json(['message' => $message], 502);
    }
}
