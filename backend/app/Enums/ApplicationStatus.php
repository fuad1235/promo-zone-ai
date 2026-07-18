<?php

namespace App\Enums;

enum ApplicationStatus: string
{
    case APPLIED = 'applied';
    case APPROVED_BY_BUSINESS = 'approved_by_business';
    case REJECTED = 'rejected';
    case SAMPLE_SUBMITTED = 'sample_submitted';
    case SAMPLE_APPROVED = 'sample_approved';
    case SAMPLE_REJECTED = 'sample_rejected';
    case POSTED = 'posted';
    case PROOF_SUBMITTED = 'proof_submitted';
    case PROOF_APPROVED = 'proof_approved';
    case PROOF_REJECTED = 'proof_rejected';
    case PAID = 'paid';
}
