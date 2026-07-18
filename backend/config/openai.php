<?php

return [
    'api_key' => env('OPENAI_API_KEY'),
    'base_url' => env('OPENAI_BASE_URL', 'https://api.openai.com/v1'),
    'model' => env('OPENAI_MODEL', 'gpt-5.6'),
    'reasoning_effort' => env('OPENAI_REASONING_EFFORT', 'low'),
    'timeout_seconds' => (int) env('OPENAI_TIMEOUT_SECONDS', 45),
    'max_output_tokens' => (int) env('OPENAI_MAX_OUTPUT_TOKENS', 2200),
];
