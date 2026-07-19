param(
  [string]$AppRoot = (Resolve-Path "$PSScriptRoot\..").Path,
  [string]$DeviceId = "9ebc65d2",
  [string]$ApiBaseUrl = "http://127.0.0.1:8000",
  [string]$EnableVerboseApiLogs = "true",
  [int]$ApiTimeoutMs = 60000,
  [int]$ApiRetryCount = 2,
  [string]$ApiRetryNonIdempotent = "false",
  [string]$FlutterBin = "flutter",
  [string]$AdbBin = "adb"
)

$ErrorActionPreference = "Stop"

Write-Host "[dev-run-android] device: $DeviceId"
Write-Host "[dev-run-android] api: $ApiBaseUrl"

if ($ApiBaseUrl -eq "http://127.0.0.1:8000" -or $ApiBaseUrl -eq "http://localhost:8000") {
  Write-Host "[dev-run-android] configuring adb reverse tcp:8000 -> tcp:8000"
  & $AdbBin -s $DeviceId reverse --remove-all
  & $AdbBin -s $DeviceId reverse tcp:8000 tcp:8000
  & $AdbBin -s $DeviceId reverse --list
}

Set-Location $AppRoot
& $FlutterBin run -d $DeviceId `
  --dart-define="LARAVEL_API_BASE_URL=$ApiBaseUrl" `
  --dart-define="ENABLE_VERBOSE_API_LOGS=$EnableVerboseApiLogs" `
  --dart-define="API_TIMEOUT_MS=$ApiTimeoutMs" `
  --dart-define="API_RETRY_COUNT=$ApiRetryCount" `
  --dart-define="API_RETRY_NON_IDEMPOTENT=$ApiRetryNonIdempotent"
