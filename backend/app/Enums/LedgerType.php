<?php

namespace App\Enums;

enum LedgerType: string
{
    case DEPOSIT = 'deposit';
    case HOLD = 'hold';
    case RELEASE = 'release';
    case PAYOUT = 'payout';
    case REFUND = 'refund';
    case ADJUSTMENT = 'adjustment';
}
