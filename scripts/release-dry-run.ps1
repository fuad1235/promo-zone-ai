$ErrorActionPreference = "Stop"

$ApiBaseUrl = if ($env:API_BASE_URL) { $env:API_BASE_URL } else { "http://127.0.0.1:8000" }

Write-Host "[dry-run] flutter quality gate"
flutter analyze
flutter test

Write-Host "[dry-run] backend quality gate"
Push-Location backend
php artisan test
Pop-Location

Write-Host "[dry-run] endpoint checks"
Invoke-WebRequest -Uri "$ApiBaseUrl/up" -Method GET -UseBasicParsing | Out-Null
Invoke-WebRequest -Uri "$ApiBaseUrl/api/health" -Method GET -UseBasicParsing | Out-Null
Invoke-WebRequest -Uri "$ApiBaseUrl/api/ready" -Method GET -UseBasicParsing | Out-Null

Write-Host "[dry-run] deployment command preview"
Write-Host "DRY_RUN=true bash scripts/deploy.sh"
Write-Host "[dry-run] completed successfully"
