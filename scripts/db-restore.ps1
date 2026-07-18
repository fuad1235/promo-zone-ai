$ErrorActionPreference = "Stop"

if ($args.Count -lt 1) {
  Write-Host "Usage: powershell -ExecutionPolicy Bypass -File .\scripts\db-restore.ps1 <backup.sql>"
  exit 1
}

$backupFile = $args[0]
if (-not (Test-Path $backupFile)) {
  Write-Host "[db-restore] file not found: $backupFile"
  exit 1
}

$DbHost = if ($env:DB_HOST) { $env:DB_HOST } else { "127.0.0.1" }
$DbPort = if ($env:DB_PORT) { $env:DB_PORT } else { "3306" }
$DbName = if ($env:DB_NAME) { $env:DB_NAME } else { "promozone" }
$DbUser = if ($env:DB_USER) { $env:DB_USER } else { "root" }
$DbPassword = if ($env:DB_PASSWORD) { $env:DB_PASSWORD } else { "" }

Write-Host "[db-restore] restoring $backupFile into $DbName"
$env:MYSQL_PWD = $DbPassword
cmd /c "mysql --host=$DbHost --port=$DbPort --user=$DbUser $DbName < `"$backupFile`""
Remove-Item Env:MYSQL_PWD -ErrorAction SilentlyContinue

Write-Host "[db-restore] restore completed"
