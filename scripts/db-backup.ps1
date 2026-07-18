$ErrorActionPreference = "Stop"

$DbHost = if ($env:DB_HOST) { $env:DB_HOST } else { "127.0.0.1" }
$DbPort = if ($env:DB_PORT) { $env:DB_PORT } else { "3306" }
$DbName = if ($env:DB_NAME) { $env:DB_NAME } else { "promozone" }
$DbUser = if ($env:DB_USER) { $env:DB_USER } else { "root" }
$DbPassword = if ($env:DB_PASSWORD) { $env:DB_PASSWORD } else { "" }
$BackupDir = if ($env:BACKUP_DIR) { $env:BACKUP_DIR } else { ".\backups" }

New-Item -ItemType Directory -Force -Path $BackupDir | Out-Null
$timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
$file = Join-Path $BackupDir ("promozone_{0}.sql" -f $timestamp)

Write-Host "[db-backup] writing $file"
$env:MYSQL_PWD = $DbPassword
cmd /c "mysqldump --host=$DbHost --port=$DbPort --user=$DbUser --single-transaction --quick $DbName > `"$file`""
Remove-Item Env:MYSQL_PWD -ErrorAction SilentlyContinue

Write-Host "[db-backup] done: $file"
