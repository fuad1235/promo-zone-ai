<?php

use App\Http\Controllers\Api\AiCampaignController;
use App\Http\Controllers\Api\ApplicationController;
use App\Http\Controllers\Api\AuthController;
use App\Http\Controllers\Api\AuthSyncController;
use App\Http\Controllers\Api\CampaignController;
use App\Http\Controllers\Api\FileController;
use App\Http\Controllers\Api\SubmissionController;
use App\Http\Controllers\Api\UploadController;
use App\Http\Controllers\Api\WalletController;
use Illuminate\Support\Facades\Cache;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Route;

Route::get('/health', function () {
    $database = 'down';

    try {
        DB::connection()->getPdo();
        $database = 'up';
    } catch (\Throwable) {
        $database = 'down';
    }

    return response()->json([
        'status' => 'ok',
        'service' => 'promozone-api',
        'database' => $database,
        'timestamp' => now()->toIso8601String(),
    ]);
});

Route::get('/ready', function () {
    $database = 'down';
    $cache = 'down';

    try {
        DB::connection()->getPdo();
        $database = 'up';
    } catch (\Throwable) {
        $database = 'down';
    }

    try {
        $key = 'health:ready:'.str()->uuid();
        Cache::put($key, 'ok', now()->addSeconds(10));
        $cache = Cache::get($key) === 'ok' ? 'up' : 'down';
        Cache::forget($key);
    } catch (\Throwable) {
        $cache = 'down';
    }

    $isReady = $database === 'up' && $cache === 'up';

    return response()->json([
        'status' => $isReady ? 'ready' : 'degraded',
        'service' => 'promozone-api',
        'database' => $database,
        'cache' => $cache,
        'timestamp' => now()->toIso8601String(),
    ], $isReady ? 200 : 503);
});

Route::post('/auth/register', [AuthController::class, 'register'])->middleware('throttle:auth');
Route::post('/auth/login', [AuthController::class, 'login'])->middleware('throttle:auth');
Route::get('/campaigns', [CampaignController::class, 'index']);
Route::get('/campaigns/{campaignId}', [CampaignController::class, 'show']);
Route::get('/files/{path}', [FileController::class, 'show'])->where('path', '.*');

Route::middleware(['api.auth', 'throttle:api'])->group(function (): void {
    Route::get('/auth/me', [AuthController::class, 'me']);
    Route::post('/auth/logout', [AuthController::class, 'logout']);
    Route::post('/auth/sync-profile', [AuthSyncController::class, 'syncProfile']);
    Route::post('/uploads', [UploadController::class, 'store']);

    Route::get('/wallet', [WalletController::class, 'show']);
    Route::post('/wallet/withdraw-request', [WalletController::class, 'withdrawRequest'])
        ->middleware('role:creator');
    Route::post('/wallet/deposit', [WalletController::class, 'deposit'])
        ->middleware(['role:business', 'idempotency']);

    Route::get('/business/campaigns', [CampaignController::class, 'myCampaigns'])
        ->middleware('role:business');
    Route::post('/campaigns', [CampaignController::class, 'store'])
        ->middleware('role:business');
    Route::put('/campaigns/{campaignId}', [CampaignController::class, 'update'])
        ->middleware('role:business');

    Route::get('/creator/applications', [ApplicationController::class, 'creatorApplications'])
        ->middleware('role:creator');
    Route::get('/campaigns/{campaignId}/applications', [ApplicationController::class, 'campaignApplications'])
        ->middleware('role:business,admin');
    Route::post('/campaigns/{campaignId}/apply', [ApplicationController::class, 'apply'])
        ->middleware('role:creator');
    Route::post('/campaigns/{campaignId}/applications/{applicationId}/approve', [ApplicationController::class, 'approve'])
        ->middleware(['role:business', 'idempotency']);
    Route::post('/campaigns/{campaignId}/applications/{applicationId}/approve-proof', [ApplicationController::class, 'approveProof'])
        ->middleware(['role:business', 'idempotency']);

    Route::post('/applications/{applicationId}/transition', [ApplicationController::class, 'transition']);
    Route::get('/applications/{applicationId}/submissions', [SubmissionController::class, 'index']);
    Route::post('/applications/{applicationId}/submissions', [SubmissionController::class, 'store'])
        ->middleware('role:creator,business');
    Route::post('/submissions/{submissionId}/review', [SubmissionController::class, 'review'])
        ->middleware('role:business,admin');

    Route::post('/holds/refund', [ApplicationController::class, 'refundHold'])
        ->middleware(['role:business,admin', 'idempotency']);

    Route::prefix('ai')->middleware('throttle:ai')->group(function (): void {
        Route::post('/campaign-brief', [AiCampaignController::class, 'campaignBrief'])
            ->middleware('role:business');
        Route::post('/campaigns/{campaignId}/creator-coach', [AiCampaignController::class, 'creatorCoach'])
            ->middleware('role:creator');
    });
});
