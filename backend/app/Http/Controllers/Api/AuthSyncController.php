<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

class AuthSyncController extends Controller
{
    public function syncProfile(Request $request): JsonResponse
    {
        $data = $request->validate([
            'displayName' => ['required', 'string', 'max:120'],
            'phone' => ['nullable', 'string', 'max:30'],
            'role' => ['required', 'in:creator,business,admin'],
            'email' => ['nullable', 'email', 'max:190'],
            'bio' => ['nullable', 'string'],
            'niches' => ['array'],
            'niches.*' => ['string', 'max:60'],
            'companyName' => ['nullable', 'string', 'max:190'],
        ]);

        $user = $request->user();

        DB::transaction(function () use ($data, $user): void {
            DB::table('users')->where('id', $user->id)->update([
                'display_name' => $data['displayName'],
                'phone' => $data['phone'] ?? null,
                'role' => $data['role'],
                'email' => $data['email'] ?? $user->email,
                'updated_at' => now(),
            ]);

            DB::table('wallets')->where('user_id', $user->id)->update([
                'role' => $data['role'],
                'updated_at' => now(),
            ]);

            if ($data['role'] === 'creator') {
                DB::table('creator_profiles')->updateOrInsert(
                    ['user_id' => $user->id],
                    [
                        'bio' => $data['bio'] ?? '',
                        'country' => '',
                        'city' => '',
                        'payout_type' => 'momo',
                        'payout_network' => 'MTN',
                        'payout_number' => null,
                        'updated_at' => now(),
                        'created_at' => now(),
                    ],
                );

                DB::table('creator_niches')->where('user_id', $user->id)->delete();
                foreach (($data['niches'] ?? []) as $niche) {
                    DB::table('creator_niches')->insert([
                        'user_id' => $user->id,
                        'niche' => $niche,
                        'created_at' => now(),
                        'updated_at' => now(),
                    ]);
                }
            }

            if ($data['role'] === 'business') {
                DB::table('business_profiles')->updateOrInsert(
                    ['user_id' => $user->id],
                    [
                        'company_name' => $data['companyName'] ?? $data['displayName'],
                        'website' => null,
                        'contact_phone' => $data['phone'] ?? null,
                        'verified' => false,
                        'updated_at' => now(),
                        'created_at' => now(),
                    ],
                );
            }
        });

        return response()->json(['ok' => true]);
    }
}
