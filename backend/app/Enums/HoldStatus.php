<?php

namespace App\Enums;

enum HoldStatus: string
{
    case ACTIVE = 'active';
    case RELEASED = 'released';
    case REFUNDED = 'refunded';
}
