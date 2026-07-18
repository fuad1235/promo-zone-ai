param(
  [string]$AppRoot = (Resolve-Path "$PSScriptRoot\..").Path,
  [string]$PhpBin = "php",
  [string]$SeedClass = "PromoMarketplaceSeeder"
)

$ErrorActionPreference = "Stop"

$backendDir = Join-Path $AppRoot "backend"
Write-Host "[dev-reset] backend dir: $backendDir"
Set-Location $backendDir

Write-Host "[dev-reset] clearing caches"
& $PhpBin artisan optimize:clear

Write-Host "[dev-reset] rebuilding schema and seeding sample data"
& $PhpBin artisan migrate:fresh --seed --seeder=$SeedClass

Write-Host "[dev-reset] done"
