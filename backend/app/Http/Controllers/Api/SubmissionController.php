<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Str;

class SubmissionController extends Controller
{
    public function index(string $applicationId): JsonResponse
    {
        $submissions = DB::table('submissions')
            ->where('application_id', $applicationId)
            ->orderByDesc('created_at')
            ->get()
            ->map(function ($submission): array {
                $media = DB::table('submission_media')
                    ->where('submission_id', $submission->id)
                    ->where('media_kind', 'media')
                    ->pluck('url')
                    ->values()
                    ->all();

                $screenshots = DB::table('submission_media')
                    ->where('submission_id', $submission->id)
                    ->where('media_kind', 'screenshot')
                    ->pluck('url')
                    ->values()
                    ->all();

                return [
                    'id' => $submission->id,
                    'application_id' => $submission->application_id,
                    'type' => $submission->type,
                    'message' => $submission->message,
                    'post_url' => $submission->post_url,
                    'declared_views' => $submission->declared_views,
                    'status' => $submission->status,
                    'reviewer_message' => $submission->reviewer_message,
                    'media' => $media,
                    'screenshots' => $screenshots,
                    'created_at' => $submission->created_at,
                    'updated_at' => $submission->updated_at,
                ];
            })
            ->values()
            ->all();

        return response()->json(['data' => $submissions]);
    }

    public function store(Request $request, string $applicationId): JsonResponse
    {
        $data = $request->validate(
            [
                'type' => ['required', 'in:sample,proof'],
                'message' => ['nullable', 'string'],
                'mediaUrls' => ['array'],
                'mediaUrls.*' => ['string'],
                'postUrl' => ['nullable', 'url'],
                'screenshots' => ['array'],
                'screenshots.*' => ['string'],
                'declaredViews' => ['nullable', 'integer', 'min:0'],
            ],
            [
                'type.required' => 'Submission type is required.',
                'type.in' => 'Submission type must be sample or proof.',
                'postUrl.url' => 'Post URL must be a valid full URL (for example https://tiktok.com/...).',
                'declaredViews.integer' => 'Declared views must be a whole number.',
                'declaredViews.min' => 'Declared views cannot be negative.',
                'screenshots.array' => 'Screenshots payload must be a list.',
                'mediaUrls.array' => 'Media payload must be a list.',
            ]
        );

        $submissionId = (string) Str::uuid();

        DB::transaction(function () use ($applicationId, $data, $submissionId): void {
            DB::table('submissions')->insert([
                'id' => $submissionId,
                'application_id' => $applicationId,
                'type' => $data['type'],
                'message' => $data['message'] ?? null,
                'post_url' => $data['postUrl'] ?? null,
                'declared_views' => $data['declaredViews'] ?? null,
                'status' => 'pending',
                'created_at' => now(),
                'updated_at' => now(),
            ]);

            foreach (($data['mediaUrls'] ?? []) as $url) {
                DB::table('submission_media')->insert([
                    'submission_id' => $submissionId,
                    'media_kind' => 'media',
                    'url' => $url,
                    'created_at' => now(),
                    'updated_at' => now(),
                ]);
            }

            foreach (($data['screenshots'] ?? []) as $url) {
                DB::table('submission_media')->insert([
                    'submission_id' => $submissionId,
                    'media_kind' => 'screenshot',
                    'url' => $url,
                    'created_at' => now(),
                    'updated_at' => now(),
                ]);
            }
        });

        return response()->json(['id' => $submissionId], 201);
    }

    public function review(Request $request, string $submissionId): JsonResponse
    {
        $data = $request->validate([
            'status' => ['required', 'in:approved,rejected'],
            'reviewerMessage' => ['nullable', 'string'],
        ]);

        $updated = DB::table('submissions')->where('id', $submissionId)->update([
            'status' => $data['status'],
            'reviewer_message' => $data['reviewerMessage'] ?? null,
            'updated_at' => now(),
        ]);

        if ($updated === 0) {
            return response()->json(['message' => 'Submission not found'], 404);
        }

        return response()->json(['ok' => true]);
    }
}
