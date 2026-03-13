#!/bin/bash
# DC Manager Pro — Manual Backup
# Run from project root: ./scripts/manual-backup.sh

set -e
cd "$(dirname "$0")/.."
DATE=$(date +%Y-%m-%d_%H%M%S)
OUTFILE="volumes/backups/manual/dcmanager_manual_${DATE}.sql.gz"

mkdir -p volumes/backups/manual

echo "Creating manual backup → $OUTFILE"
docker exec dcm_postgres pg_dump \
  -U "${DB_USER:-dcuser}" \
  "${DB_NAME:-dcmanager}" | gzip > "$OUTFILE"

echo "✓ Done: $(du -sh "$OUTFILE" | cut -f1)"
echo "  File: $(pwd)/$OUTFILE"
