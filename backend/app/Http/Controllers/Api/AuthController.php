<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Str;

class AuthController extends Controller
{
    private function tokenTtlMinutes(): int
    {
        return max(5, (int) config('auth.api_token_ttl_minutes', 43200));
    }

    public function register(Request $request): JsonResponse
    {
        $data = $request->validate([
            'email' => ['required', 'email', 'max:190', 'unique:users,email'],
            'password' => ['required', 'string', 'min:6'],
        ]);

        $rawToken = Str::random(80);
        $userId = (string) Str::uuid();
        $tokenExpiresAt = now()->addMinutes($this->tokenTtlMinutes());

        DB::transaction(function () use ($data, $userId, $rawToken, $tokenExpiresAt): void {
            DB::table('users')->insert([
                'id' => $userId,
                'email' => $data['email'],
                'password' => Hash::make($data['password']),
                'display_name' => 'Promo Zone User',
                'role' => 'creator',
                'api_token' => hash('sha256', $rawToken),
                'api_token_expires_at' => $tokenExpiresAt,
                'created_at' => now(),
                'updated_at' => now(),
            ]);

            DB::table('wallets')->insert([
                'user_id' => $userId,
                'role' => 'creator',
                'available_balance' => 0,
                'held_balance' => 0,
                'version' => 0,
                'created_at' => now(),
                'updated_at' => now(),
            ]);
        });

        return response()->json([
            'token' => $rawToken,
            'token_expires_at' => $tokenExpiresAt->toIso8601String(),
            'user' => DB::table('users')->where('id', $userId)->first(),
        ], 201);
    }

    public function login(Request $request): JsonResponse
    {
        $data = $request->validate([
            'email' => ['required', 'email'],
            'password' => ['required', 'string'],
        ]);

        $user = DB::table('users')->where('email', $data['email'])->first();
        if (!$user || !Hash::check($data['password'], $user->password)) {
            return response()->json(['message' => 'Invalid credentials'], 401);
        }

        $rawToken = Str::random(80);
        $tokenExpiresAt = now()->addMinutes($this->tokenTtlMinutes());
        DB::table('users')->where('id', $user->id)->update([
            'api_token' => hash('sha256', $rawToken),
            'api_token_expires_at' => $tokenExpiresAt,
            'updated_at' => now(),
        ]);

        $updated = DB::table('users')->where('id', $user->id)->first();

        return response()->json([
            'token' => $rawToken,
            'token_expires_at' => $tokenExpiresAt->toIso8601String(),
            'user' => $updated,
        ]);
    }

    public function me(Request $request): JsonResponse
    {
        return response()->json(['user' => $request->user()]);
    }

    public function logout(Request $request): JsonResponse
    {
        DB::table('users')->where('id', $request->user()->id)->update([
            'api_token' => null,
            'api_token_expires_at' => null,
            'updated_at' => now(),
        ]);

        return response()->json(['ok' => true]);
    }
}
