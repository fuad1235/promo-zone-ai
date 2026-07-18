param(
  [string]$ApiBaseUrl = "http://127.0.0.1:8000",
  [string]$AdbDeviceId = "9ebc65d2",
  [string]$AdbBin = "adb"
)

$ErrorActionPreference = "Stop"

Write-Host "[dev-check] API base: $ApiBaseUrl"
Write-Host "[dev-check] backend health:"
Invoke-RestMethod -Uri "$ApiBaseUrl/api/health" | ConvertTo-Json -Depth 8

Write-Host "[dev-check] adb devices:"
& $AdbBin devices

Write-Host "[dev-check] adb reverse list for $AdbDeviceId:"
& $AdbBin -s $AdbDeviceId reverse --list

Write-Host "[dev-check] done"
