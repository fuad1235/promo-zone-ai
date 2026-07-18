<?php

namespace App\Services;

class ApplicationStateMachine
{
    private const ALLOWED = [
        'applied' => ['approved_by_business', 'rejected'],
        'approved_by_business' => ['sample_submitted'],
        'sample_submitted' => ['sample_approved', 'sample_rejected'],
        'sample_rejected' => ['sample_submitted'],
        'sample_approved' => ['posted'],
        'posted' => ['proof_submitted'],
        'proof_submitted' => ['proof_approved', 'proof_rejected'],
        'proof_rejected' => ['proof_submitted'],
        'proof_approved' => ['paid'],
        'rejected' => [],
        'paid' => [],
    ];

    public function canTransition(string $from, string $to): bool
    {
        return in_array($to, self::ALLOWED[$from] ?? [], true);
    }
}
