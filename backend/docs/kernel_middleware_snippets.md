# Middleware Registration Snippets

Use one of the following depending on your Laravel version.

## Laravel 10 (`app/Http/Kernel.php`)

Add aliases in `$middlewareAliases` (or `$routeMiddleware` for older Laravel 9):

```php
protected $middlewareAliases = [
    // ...existing aliases
    'api.auth' => \App\Http\Middleware\AuthenticateApiToken::class,
    'role' => \App\Http\Middleware\EnsureRole::class,
];
```

## Laravel 11 (`bootstrap/app.php`)

Register route middleware aliases:

```php
->withMiddleware(function (\Illuminate\Foundation\Configuration\Middleware $middleware) {
    $middleware->alias([
        'api.auth' => \App\Http\Middleware\AuthenticateApiToken::class,
        'role' => \App\Http\Middleware\EnsureRole::class,
    ]);
})
```

## Route Group Check

Ensure protected routes use `api.auth`:

```php
Route::middleware('api.auth')->group(function (): void {
    // protected API routes
});
```
