#!/bin/bash
# DC Manager Pro — Restore from Backup
# Usage: ./scripts/restore.sh <backup_file.sql.gz>

set -e
cd "$(dirname "$0")/.."
BACKUP_FILE="$1"

if [ -z "$BACKUP_FILE" ]; then
    echo "Usage: $0 <path-to-backup.sql.gz>"
    echo ""
    echo "Available backups:"
    ls -lht volumes/backups/daily/   2>/dev/null | head -6
    ls -lht volumes/backups/weekly/  2>/dev/null | head -4
    ls -lht volumes/backups/manual/  2>/dev/null | head -4
    exit 1
fi

[ ! -f "$BACKUP_FILE" ] && echo "ERROR: File not found: $BACKUP_FILE" && exit 1

source .env 2>/dev/null || true
DB_USER="${DB_USER:-dcuser}"
DB_PASS="${DB_PASS:-changeme123}"
DB_NAME="${DB_NAME:-dcmanager}"

echo "==================================================="
echo "  DC Manager Pro — Database Restore"
echo "==================================================="
echo "  File:     $BACKUP_FILE ($(du -sh "$BACKUP_FILE" | cut -f1))"
echo "  Database: $DB_NAME"
echo "==================================================="
echo ""
read -p "WARNING: This will OVERWRITE all current data. Continue? [y/N] " confirm
[ "$confirm" != "y" ] && [ "$confirm" != "Y" ] && echo "Aborted." && exit 0

echo "Restoring..."
export PGPASSWORD="$DB_PASS"
gunzip -c "$BACKUP_FILE" | docker exec -i dcm_postgres \
  psql -U "$DB_USER" -d "$DB_NAME"

echo ""
echo "✓ Restore complete! Restart backend to reconnect:"
echo "  docker compose restart backend"
