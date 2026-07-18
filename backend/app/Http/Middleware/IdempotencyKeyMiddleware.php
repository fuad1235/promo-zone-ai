<?php

namespace App\Http\Middleware;

use Closure;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Symfony\Component\HttpFoundation\Response;
use Throwable;

class IdempotencyKeyMiddleware
{
    public function handle(Request $request, Closure $next): Response
    {
        if (!config('idempotency.enabled', true)) {
            return $next($request);
        }

        $method = strtoupper($request->method());
        if (!in_array($method, ['POST', 'PUT', 'PATCH', 'DELETE'], true)) {
            return $next($request);
        }

        $idempotencyKey = trim((string) $request->header('Idempotency-Key', ''));
        if ($idempotencyKey === '') {
            return $next($request);
        }

        if (strlen($idempotencyKey) > 120) {
            return response()->json(['message' => 'Invalid Idempotency-Key header.'], 422);
        }

        $userId = (string) ($request->user()?->id ?? 'guest');
        $path = $request->path();
        $keyHash = hash('sha256', implode('|', [$userId, $method, $path, $idempotencyKey]));
        $now = now();

        $ttlSeconds = max(30, (int) config('idempotency.ttl_seconds', 86400));
        $lockSeconds = max(5, (int) config('idempotency.processing_lock_seconds', 30));
        $lockUntil = $now->copy()->addSeconds($lockSeconds);
        $expiresAt = $now->copy()->addSeconds($ttlSeconds);

        $record = DB::table('api_idempotency_keys')->where('key_hash', $keyHash)->first();
        if ($record && $record->expires_at !== null && $now->greaterThan($record->expires_at)) {
            DB::table('api_idempotency_keys')->where('key_hash', $keyHash)->delete();
            $record = null;
        }

        if ($record) {
            if ($record->status === 'completed') {
                return $this->replayResponse($record, $idempotencyKey);
            }

            $isLocked = $record->locked_until !== null && $now->lessThan($record->locked_until);
            if ($record->status === 'processing' && $isLocked) {
                return response()->json([
                    'message' => 'A request with this idempotency key is already processing.',
                ], 409);
            }

            DB::table('api_idempotency_keys')
                ->where('key_hash', $keyHash)
                ->update([
                    'status' => 'processing',
                    'locked_until' => $lockUntil,
                    'expires_at' => $expiresAt,
                    'updated_at' => $now,
                ]);
        } else {
            DB::table('api_idempotency_keys')->insert([
                'key_hash' => $keyHash,
                'user_id' => $request->user()?->id,
                'method' => $method,
                'path' => $path,
                'status' => 'processing',
                'locked_until' => $lockUntil,
                'expires_at' => $expiresAt,
                'created_at' => $now,
                'updated_at' => $now,
            ]);
        }

        try {
            $response = $next($request);
        } catch (Throwable $exception) {
            DB::table('api_idempotency_keys')
                ->where('key_hash', $keyHash)
                ->delete();
            throw $exception;
        }

        $headers = [
            'Content-Type' => $response->headers->get('Content-Type', 'application/json'),
        ];

        DB::table('api_idempotency_keys')
            ->where('key_hash', $keyHash)
            ->update([
                'status' => 'completed',
                'response_status' => $response->getStatusCode(),
                'response_body' => $response->getContent(),
                'response_headers' => json_encode($headers),
                'locked_until' => null,
                'expires_at' => $expiresAt,
                'updated_at' => now(),
            ]);

        $response->headers->set('Idempotency-Key', $idempotencyKey);

        return $response;
    }

    private function replayResponse(object $record, string $idempotencyKey): Response
    {
        $headers = json_decode((string) ($record->response_headers ?? '{}'), true);
        if (!is_array($headers)) {
            $headers = [];
        }

        $response = response(
            $record->response_body ?? '',
            (int) ($record->response_status ?? 200)
        );

        foreach ($headers as $header => $value) {
            if (is_string($header) && is_string($value)) {
                $response->headers->set($header, $value);
            }
        }

        $response->headers->set('Idempotency-Key', $idempotencyKey);
        $response->headers->set('X-Idempotent-Replay', 'true');

        return $response;
    }
}
