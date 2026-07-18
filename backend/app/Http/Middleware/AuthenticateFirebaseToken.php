<?php

namespace App\Http\Middleware;

use Closure;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Str;
use Kreait\Firebase\Factory;
use Kreait\Firebase\Exception\Auth\FailedToVerifyToken;
use Symfony\Component\HttpFoundation\Response;

class AuthenticateFirebaseToken
{
    public function handle(Request $request, Closure $next): Response
    {
        $token = $this->extractBearerToken($request);
        if (!$token) {
            return response()->json(['message' => 'Missing bearer token'], 401);
        }

        try {
            $auth = (new Factory())
                ->withServiceAccount($this->resolveServiceAccount())
                ->createAuth();

            $verifiedToken = $auth->verifyIdToken($token);
            $uid = $verifiedToken->claims()->get('sub');
            if (!is_string($uid) || $uid === '') {
                return response()->json(['message' => 'Invalid token subject'], 401);
            }

            $email = $verifiedToken->claims()->get('email');
            $name = $verifiedToken->claims()->get('name');
            $role = $verifiedToken->claims()->get('role');
            $normalizedRole = in_array($role, ['creator', 'business', 'admin'], true)
                ? $role
                : 'creator';

            $user = DB::table('users')->where('firebase_uid', $uid)->first();
            if (!$user) {
                DB::transaction(function () use ($uid, $email, $name, $normalizedRole): void {
                    $userId = (string) Str::uuid();
                    DB::table('users')->insert([
                        'id' => $userId,
                        'firebase_uid' => $uid,
                        'email' => is_string($email) && $email !== '' ? $email : "$uid@firebase.local",
                        'password' => Hash::make(Str::random(40)),
                        'display_name' => is_string($name) && $name !== '' ? $name : 'Promo Zone User',
                        'role' => $normalizedRole,
                        'created_at' => now(),
                        'updated_at' => now(),
                    ]);

                    DB::table('wallets')->insert([
                        'user_id' => $userId,
                        'role' => $normalizedRole,
                        'available_balance' => 0,
                        'held_balance' => 0,
                        'version' => 0,
                        'created_at' => now(),
                        'updated_at' => now(),
                    ]);
                });

                $user = DB::table('users')->where('firebase_uid', $uid)->first();
            }

            $request->setUserResolver(static fn () => $user);

            return $next($request);
        } catch (FailedToVerifyToken) {
            return response()->json(['message' => 'Invalid or expired token'], 401);
        } catch (\Throwable) {
            return response()->json(['message' => 'Authentication failed'], 401);
        }
    }

    private function extractBearerToken(Request $request): ?string
    {
        $token = $request->bearerToken();
        if (is_string($token) && $token !== '') {
            return $token;
        }

        return null;
    }

    private function resolveServiceAccount(): string|array
    {
        $raw = env('FIREBASE_CREDENTIALS');
        if (!$raw) {
            throw new \RuntimeException('Missing FIREBASE_CREDENTIALS env value');
        }

        if (str_starts_with(trim($raw), '{')) {
            /** @var array<string, mixed> $decoded */
            $decoded = json_decode($raw, true, 512, JSON_THROW_ON_ERROR);
            return $decoded;
        }

        return $raw;
    }
}
