#!/usr/bin/env bash
set -euo pipefail

if [[ $# -lt 1 ]]; then
  echo "Usage: bash scripts/db-restore.sh <backup.sql.gz|backup.sql>"
  exit 1
fi

backup_file="$1"
if [[ ! -f "$backup_file" ]]; then
  echo "[db-restore] file not found: $backup_file"
  exit 1
fi

DB_HOST="${DB_HOST:-127.0.0.1}"
DB_PORT="${DB_PORT:-3306}"
DB_NAME="${DB_NAME:-promozone}"
DB_USER="${DB_USER:-root}"
DB_PASSWORD="${DB_PASSWORD:-}"

echo "[db-restore] restoring $backup_file into $DB_NAME"
if [[ "$backup_file" == *.gz ]]; then
  gzip -dc "$backup_file" | MYSQL_PWD="$DB_PASSWORD" mysql \
    --host="$DB_HOST" \
    --port="$DB_PORT" \
    --user="$DB_USER" \
    "$DB_NAME"
else
  MYSQL_PWD="$DB_PASSWORD" mysql \
    --host="$DB_HOST" \
    --port="$DB_PORT" \
    --user="$DB_USER" \
    "$DB_NAME" < "$backup_file"
fi

echo "[db-restore] restore completed"
