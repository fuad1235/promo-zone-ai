<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Services\ApplicationStateMachine;
use App\Services\LedgerService;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Str;
use RuntimeException;

class ApplicationController extends Controller
{
    public function __construct(
        private readonly LedgerService $ledgerService,
        private readonly ApplicationStateMachine $stateMachine,
    ) {
    }

    public function creatorApplications(Request $request): JsonResponse
    {
        $items = $this->baseApplicationsQuery()
            ->where('applications.creator_id', $request->user()->id)
            ->orderByDesc('applications.created_at')
            ->limit(100)
            ->get();

        return response()->json(['data' => $items]);
    }

    public function campaignApplications(Request $request, string $campaignId): JsonResponse
    {
        $campaign = DB::table('campaigns')->where('id', $campaignId)->first();
        if (!$campaign) {
            return response()->json(['message' => 'Campaign not found.'], 404);
        }
        if ($campaign->business_id !== $request->user()->id && $request->user()->role !== 'admin') {
            return response()->json(['message' => 'Forbidden'], 403);
        }

        $items = $this->baseApplicationsQuery()
            ->where('applications.campaign_id', $campaignId)
            ->orderByDesc('applications.created_at')
            ->limit(100)
            ->get();

        return response()->json(['data' => $items]);
    }

    public function apply(Request $request, string $campaignId): JsonResponse
    {
        $data = $request->validate([
            'creatorHandleId' => ['nullable', 'uuid'],
        ]);

        $campaign = DB::table('campaigns')->where('id', $campaignId)->first();
        if (!$campaign || $campaign->status !== 'published') {
            return response()->json(['message' => 'Campaign unavailable.'], 422);
        }

        $exists = DB::table('applications')
            ->where('campaign_id', $campaignId)
            ->where('creator_id', $request->user()->id)
            ->exists();
        if ($exists) {
            return response()->json(['message' => 'Already applied.'], 422);
        }

        $applicationId = (string) Str::uuid();
        DB::table('applications')->insert([
            'id' => $applicationId,
            'campaign_id' => $campaignId,
            'business_id' => $campaign->business_id,
            'creator_id' => $request->user()->id,
            'creator_handle_id' => $data['creatorHandleId'] ?? null,
            'status' => 'applied',
            'applied_at' => now(),
            'created_at' => now(),
            'updated_at' => now(),
        ]);

        DB::table('campaigns')->where('id', $campaignId)->update([
            'applicants_count' => DB::raw('applicants_count + 1'),
            'updated_at' => now(),
        ]);

        return response()->json(['ok' => true, 'id' => $applicationId], 201);
    }

    public function approve(Request $request, string $campaignId, string $applicationId): JsonResponse
    {
        try {
            $this->ledgerService->approveCreator($request->user()->id, $campaignId, $applicationId);
            return response()->json(['ok' => true]);
        } catch (RuntimeException $exception) {
            return response()->json(['message' => $exception->getMessage()], 422);
        }
    }

    public function approveProof(Request $request, string $campaignId, string $applicationId): JsonResponse
    {
        try {
            $this->ledgerService->approveProof($request->user()->id, $campaignId, $applicationId);
            return response()->json(['ok' => true]);
        } catch (RuntimeException $exception) {
            return response()->json(['message' => $exception->getMessage()], 422);
        }
    }

    public function refundHold(Request $request): JsonResponse
    {
        $data = $request->validate(['holdId' => ['required', 'uuid']]);

        try {
            $this->ledgerService->refundHold($request->user()->id, $data['holdId']);
            return response()->json(['ok' => true]);
        } catch (RuntimeException $exception) {
            return response()->json(['message' => $exception->getMessage()], 422);
        }
    }

    public function transition(Request $request, string $applicationId): JsonResponse
    {
        $data = $request->validate([
            'to' => ['required', 'string'],
            'reviewerMessage' => ['nullable', 'string'],
        ]);

        $application = DB::table('applications')->where('id', $applicationId)->first();
        if (!$application) {
            return response()->json(['message' => 'Application not found.'], 404);
        }

        if (!$this->stateMachine->canTransition($application->status, $data['to'])) {
            return response()->json(['message' => 'Invalid state transition.'], 422);
        }

        DB::table('applications')->where('id', $applicationId)->update([
            'status' => $data['to'],
            'reviewer_message' => $data['reviewerMessage'] ?? null,
            'updated_at' => now(),
        ]);

        return response()->json(['ok' => true]);
    }

    private function baseApplicationsQuery()
    {
        return DB::table('applications')
            ->leftJoin('creator_handles', 'creator_handles.id', '=', 'applications.creator_handle_id')
            ->leftJoin('users as creators', 'creators.id', '=', 'applications.creator_id')
            ->select([
                'applications.*',
                'creator_handles.platform as creator_handle_platform',
                'creator_handles.username as creator_handle_username',
                'creator_handles.profile_url as creator_handle_profile_url',
                'creators.display_name as creator_display_name',
            ]);
    }
}
