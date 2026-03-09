#!/bin/bash
# DC Manager Pro — Restore from Backup
# Usage: ./restore.sh <backup_file.sql.gz>

set -e
BACKUP_FILE="$1"
DB_USER="${DB_USER:-dcuser}"
DB_PASS="${DB_PASS:-dcpassword123}"
DB_NAME="${DB_NAME:-dcmanager}"
DB_HOST="${DB_HOST:-localhost}"
DB_PORT="${DB_PORT:-5432}"

if [ -z "$BACKUP_FILE" ]; then
    echo "Usage: $0 <path-to-backup.sql.gz>"
    echo ""
    echo "Available backups:"
    ls -lh backups/daily/ backups/weekly/ 2>/dev/null
    exit 1
fi

if [ ! -f "$BACKUP_FILE" ]; then
    echo "ERROR: Backup file not found: $BACKUP_FILE"
    exit 1
fi

echo "==================================================="
echo "  DC Manager Pro — Database Restore"
echo "==================================================="
echo "  File:     $BACKUP_FILE"
echo "  Database: $DB_NAME @ $DB_HOST:$DB_PORT"
echo "==================================================="
echo ""
read -p "WARNING: This will OVERWRITE all current data. Continue? [y/N] " confirm
[ "$confirm" != "y" ] && [ "$confirm" != "Y" ] && echo "Aborted." && exit 0

export PGPASSWORD="$DB_PASS"

echo "[$(date)] Dropping and recreating database..."
psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d postgres -c "DROP DATABASE IF EXISTS $DB_NAME;"
psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d postgres -c "CREATE DATABASE $DB_NAME OWNER $DB_USER;"

echo "[$(date)] Restoring from $BACKUP_FILE ..."
gunzip -c "$BACKUP_FILE" | psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$DB_NAME"

echo "[$(date)] ✓ Restore complete!"
echo ""
echo "Restart the app to reconnect: docker compose restart backend"
