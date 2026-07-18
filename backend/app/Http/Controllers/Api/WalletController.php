<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Services\LedgerService;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use RuntimeException;

class WalletController extends Controller
{
    public function __construct(private readonly LedgerService $ledgerService)
    {
    }

    public function show(Request $request): JsonResponse
    {
        $wallet = DB::table('wallets')->where('user_id', $request->user()->id)->first();
        $ledger = DB::table('wallet_ledger')
            ->where('wallet_user_id', $request->user()->id)
            ->orderByDesc('created_at')
            ->limit(50)
            ->get();

        return response()->json(['wallet' => $wallet, 'ledger' => $ledger]);
    }

    public function deposit(Request $request): JsonResponse
    {
        $data = $request->validate([
            'amount' => ['required', 'integer', 'min:1'],
        ]);

        try {
            $this->ledgerService->depositCredits($request->user()->id, (int) $data['amount']);
            return response()->json(['ok' => true]);
        } catch (RuntimeException $exception) {
            return response()->json(['message' => $exception->getMessage()], 422);
        }
    }

    public function withdrawRequest(Request $request): JsonResponse
    {
        $data = $request->validate([
            'amount' => ['required', 'integer', 'min:1'],
            'network' => ['required', 'string', 'max:40'],
            'number' => ['required', 'string', 'max:30'],
        ]);

        DB::table('withdraw_requests')->insert([
            'id' => (string) \Illuminate\Support\Str::uuid(),
            'creator_id' => $request->user()->id,
            'amount' => $data['amount'],
            'payout_type' => 'momo',
            'network' => $data['network'],
            'number' => $data['number'],
            'status' => 'pending',
            'created_at' => now(),
            'updated_at' => now(),
        ]);

        return response()->json(['ok' => true], 201);
    }
}
