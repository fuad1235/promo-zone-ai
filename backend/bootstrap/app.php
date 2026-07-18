<?php

use App\Http\Middleware\AuthenticateApiToken;
use App\Http\Middleware\EnsureRole;
use App\Http\Middleware\IdempotencyKeyMiddleware;
use App\Http\Middleware\RequestContextMiddleware;
use App\Http\Middleware\SecurityHeadersMiddleware;
use Illuminate\Auth\Access\AuthorizationException;
use Illuminate\Auth\AuthenticationException;
use Illuminate\Foundation\Application;
use Illuminate\Foundation\Configuration\Exceptions;
use Illuminate\Foundation\Configuration\Middleware;
use Illuminate\Http\Request;
use Illuminate\Validation\ValidationException;
use Symfony\Component\HttpKernel\Exception\NotFoundHttpException;
use Symfony\Component\HttpKernel\Exception\TooManyRequestsHttpException;

return Application::configure(basePath: dirname(__DIR__))
    ->withRouting(
        web: __DIR__.'/../routes/web.php',
        api: __DIR__.'/../routes/api.php',
        commands: __DIR__.'/../routes/console.php',
        health: '/up',
    )
    ->withMiddleware(function (Middleware $middleware): void {
        $middleware->alias([
            'api.auth' => AuthenticateApiToken::class,
            'role' => EnsureRole::class,
            'idempotency' => IdempotencyKeyMiddleware::class,
        ]);

        $middleware->api(prepend: [
            RequestContextMiddleware::class,
            SecurityHeadersMiddleware::class,
        ]);
    })
    ->withExceptions(function (Exceptions $exceptions): void {
        $exceptions->render(function (Throwable $exception, Request $request) {
            if (!$request->is('api/*')) {
                return null;
            }

            $status = 500;
            $payload = [
                'message' => 'Server error',
                'request_id' => $request->attributes->get('request_id'),
            ];

            if ($exception instanceof ValidationException) {
                $status = 422;
                $payload['message'] = 'Validation failed';
                $payload['errors'] = $exception->errors();
            } elseif ($exception instanceof AuthenticationException) {
                $status = 401;
                $payload['message'] = 'Unauthenticated';
            } elseif ($exception instanceof AuthorizationException) {
                $status = 403;
                $payload['message'] = 'Forbidden';
            } elseif ($exception instanceof NotFoundHttpException) {
                $status = 404;
                $payload['message'] = 'Not found';
            } elseif ($exception instanceof TooManyRequestsHttpException) {
                $status = 429;
                $payload['message'] = 'Too many requests';
            }

            if (config('app.debug')) {
                $payload['debug'] = [
                    'exception' => $exception::class,
                    'message' => $exception->getMessage(),
                ];
            }

            return response()->json($payload, $status);
        });
    })
    ->create();
