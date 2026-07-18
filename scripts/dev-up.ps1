param(
  [string]$AppRoot = (Resolve-Path "$PSScriptRoot\..").Path,
  [string]$PhpBin = "php",
  [string]$Host = "127.0.0.1",
  [int]$Port = 8000,
  [switch]$WithReset
)

$ErrorActionPreference = "Stop"

$backendDir = Join-Path $AppRoot "backend"

if ($WithReset) {
  & powershell -ExecutionPolicy Bypass -File (Join-Path $PSScriptRoot "dev-reset.ps1") -AppRoot $AppRoot -PhpBin $PhpBin
}

Write-Host "[dev-up] backend dir: $backendDir"
Write-Host "[dev-up] serving on http://$Host`:$Port"
Write-Host "[dev-up] health endpoint: http://$Host`:$Port/api/health"

Set-Location $backendDir
& $PhpBin artisan serve --host=$Host --port=$Port
