<?php

namespace App\Logging;

use Illuminate\Log\Logger as IlluminateLogger;
use Monolog\LogRecord;
use Monolog\Logger;

class RedactSensitiveDataTap
{
    private const SENSITIVE_KEYS = [
        'password',
        'token',
        'api_token',
        'authorization',
        'number',
        'secret',
        'bearer',
    ];

    public function __invoke(IlluminateLogger|Logger $logger): void
    {
        $monolog = $logger instanceof IlluminateLogger
            ? $logger->getLogger()
            : $logger;

        $monolog->pushProcessor(function ($record) {
            if ($record instanceof LogRecord) {
                return $record->with(
                    context: $this->redact($record->context),
                    extra: $this->redact($record->extra),
                );
            }

            if (is_array($record)) {
                $record['context'] = $this->redact($record['context'] ?? []);
                $record['extra'] = $this->redact($record['extra'] ?? []);
            }

            return $record;
        });
    }

    private function redact(mixed $value, ?string $key = null): mixed
    {
        if ($this->isSensitive($key)) {
            return '***';
        }

        if (is_array($value)) {
            $result = [];
            foreach ($value as $k => $item) {
                $result[$k] = $this->redact(
                    $item,
                    is_string($k) ? strtolower($k) : null
                );
            }
            return $result;
        }

        return $value;
    }

    private function isSensitive(?string $key): bool
    {
        if ($key === null) {
            return false;
        }

        foreach (self::SENSITIVE_KEYS as $sensitive) {
            if (str_contains($key, $sensitive)) {
                return true;
            }
        }

        return false;
    }
}
