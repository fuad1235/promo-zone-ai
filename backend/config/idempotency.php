<?php

return [
    'enabled' => env('IDEMPOTENCY_ENABLED', true),
    'ttl_seconds' => (int) env('IDEMPOTENCY_TTL_SECONDS', 86400),
    'processing_lock_seconds' => (int) env('IDEMPOTENCY_PROCESSING_LOCK_SECONDS', 30),
];
