#!/bin/bash
# DC Manager Pro — Manual Backup Helper
# Run from project root: ./scripts/manual-backup.sh

set -e
DATE=$(date +%Y-%m-%d_%H%M%S)
OUTFILE="backups/manual/dcmanager_manual_${DATE}.sql.gz"

mkdir -p backups/manual

echo "Creating manual backup → $OUTFILE"
docker exec dcm_postgres pg_dump \
    -U "${DB_USER:-dcuser}" \
    "${DB_NAME:-dcmanager}" | gzip > "$OUTFILE"

echo "✓ Done: $(du -sh "$OUTFILE" | cut -f1)"
