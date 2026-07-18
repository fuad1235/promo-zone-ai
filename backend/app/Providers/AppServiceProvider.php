<?php

namespace App\Providers;

use Illuminate\Cache\RateLimiting\Limit;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\RateLimiter;
use Illuminate\Support\ServiceProvider;

class AppServiceProvider extends ServiceProvider
{
    /**
     * Register any application services.
     */
    public function register(): void
    {
        //
    }

    /**
     * Bootstrap any application services.
     */
    public function boot(): void
    {
        RateLimiter::for('api', function (Request $request) {
            $limit = (int) env('API_RATE_LIMIT_PER_MINUTE', 120);
            $identity = $request->user()?->id ?: $request->ip();

            return Limit::perMinute($limit)->by($identity);
        });

        RateLimiter::for('auth', function (Request $request) {
            $limit = (int) env('AUTH_RATE_LIMIT_PER_MINUTE', 20);

            return Limit::perMinute($limit)->by($request->ip());
        });

        RateLimiter::for('ai', function (Request $request) {
            $limit = (int) env('AI_RATE_LIMIT_PER_MINUTE', 10);
            $identity = $request->user()?->id ?: $request->ip();

            return Limit::perMinute($limit)->by($identity);
        });
    }
}
