<?php

namespace App\Http\Middleware;

use Closure;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Symfony\Component\HttpFoundation\Response;

class AuthenticateApiToken
{
    public function handle(Request $request, Closure $next): Response
    {
        $token = $request->bearerToken();
        if (!$token) {
            return response()->json(['message' => 'Missing bearer token'], 401);
        }

        $user = DB::table('users')->where('api_token', hash('sha256', $token))->first();
        if (!$user) {
            return response()->json(['message' => 'Invalid token'], 401);
        }

        if (!empty($user->api_token_expires_at) && now()->greaterThan($user->api_token_expires_at)) {
            DB::table('users')->where('id', $user->id)->update([
                'api_token' => null,
                'api_token_expires_at' => null,
                'updated_at' => now(),
            ]);

            return response()->json(['message' => 'Token expired'], 401);
        }

        $request->setUserResolver(static fn () => $user);
        return $next($request);
    }
}
