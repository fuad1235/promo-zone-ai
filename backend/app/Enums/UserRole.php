<?php

namespace App\Enums;

enum UserRole: string
{
    case CREATOR = 'creator';
    case BUSINESS = 'business';
    case ADMIN = 'admin';
}
