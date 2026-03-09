#!/bin/sh
# DC Manager Pro — Automated PostgreSQL Backup Script
# Usage: ./backup.sh [DB_USER] [DB_NAME] [DB_HOST]
# Runs daily via cron; keeps 30 days of daily, 12 weeks of weekly backups.

DB_USER="${1:-dcuser}"
DB_NAME="${2:-dcmanager}"
DB_HOST="${3:-db}"
BACKUP_DIR="/backups"
DATE=$(date +%Y-%m-%d_%H%M%S)
DOW=$(date +%u)   # 1=Monday … 7=Sunday

mkdir -p "$BACKUP_DIR/daily" "$BACKUP_DIR/weekly"

# ── Daily backup ──────────────────────────────
DAILY_FILE="$BACKUP_DIR/daily/${DB_NAME}_${DATE}.sql.gz"
echo "[$(date)] Starting daily backup → $DAILY_FILE"

pg_dump -h "$DB_HOST" -U "$DB_USER" "$DB_NAME" | gzip > "$DAILY_FILE"

if [ $? -eq 0 ]; then
    echo "[$(date)] Backup completed: $(du -sh "$DAILY_FILE" | cut -f1)"
else
    echo "[$(date)] ERROR: Backup FAILED!"
    exit 1
fi

# ── Weekly backup (every Sunday) ─────────────
if [ "$DOW" = "7" ]; then
    WEEKLY_FILE="$BACKUP_DIR/weekly/${DB_NAME}_week$(date +%Y-%V).sql.gz"
    cp "$DAILY_FILE" "$WEEKLY_FILE"
    echo "[$(date)] Weekly backup saved → $WEEKLY_FILE"
fi

# ── Rotate: keep 30 daily, 12 weekly ─────────
find "$BACKUP_DIR/daily"  -name "*.sql.gz" -mtime +30 -delete
find "$BACKUP_DIR/weekly" -name "*.sql.gz" -mtime +84 -delete

echo "[$(date)] Rotation complete. Current backups:"
ls -lh "$BACKUP_DIR/daily/"  | tail -5
ls -lh "$BACKUP_DIR/weekly/" | tail -5
