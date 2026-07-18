$ErrorActionPreference = "Stop"

$ApiBaseUrl = if ($env:API_BASE_URL) { $env:API_BASE_URL } else { "http://127.0.0.1:8000" }
$RunMigrateRollback = if ($env:RUN_MIGRATE_ROLLBACK) { $env:RUN_MIGRATE_ROLLBACK } else { "false" }
$RollbackSteps = if ($env:ROLLBACK_STEPS) { $env:ROLLBACK_STEPS } else { "1" }

Push-Location backend

Write-Host "[rollback] clearing runtime caches"
php artisan optimize:clear

if ($RunMigrateRollback -eq "true") {
  Write-Host "[rollback] running migrate:rollback --step=$RollbackSteps"
  php artisan migrate:rollback --step=$RollbackSteps --force
}

Write-Host "[rollback] rebuilding safe runtime caches"
php artisan config:cache
php artisan route:cache
php artisan event:cache

Pop-Location

Write-Host "[rollback] verify endpoints"
Invoke-WebRequest -Uri "$ApiBaseUrl/up" -Method GET -UseBasicParsing | Out-Null
Invoke-WebRequest -Uri "$ApiBaseUrl/api/health" -Method GET -UseBasicParsing | Out-Null
Invoke-WebRequest -Uri "$ApiBaseUrl/api/ready" -Method GET -UseBasicParsing | Out-Null

Write-Host "[rollback] completed"
