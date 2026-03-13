#!/bin/bash
# ══════════════════════════════════════════════════════════
# DC Manager Pro — Migrate from Docker named volumes
# to local ./volumes/ directory
# Run this ONCE on your existing server to migrate data
# ══════════════════════════════════════════════════════════

set -e
cd "$(dirname "$0")/.."
PROJECT_DIR="$(pwd)"

echo "=================================================="
echo "  DC Manager Pro — Volume Migration"
echo "  From: Docker named volumes (dc-prod_pgdata)"
echo "  To:   $PROJECT_DIR/volumes/"
echo "=================================================="
echo ""

# ── Step 1: Check old volume exists ───────────────
OLD_VOL=$(docker volume ls -q | grep -E "dc.prod_pgdata|dc_prod_pgdata" | head -1)
if [ -z "$OLD_VOL" ]; then
    echo "No old named volume found — nothing to migrate."
    echo "Creating fresh ./volumes/ directory structure..."
    mkdir -p "$PROJECT_DIR/volumes/postgres"
    mkdir -p "$PROJECT_DIR/volumes/backups/daily"
    mkdir -p "$PROJECT_DIR/volumes/backups/weekly"
    mkdir -p "$PROJECT_DIR/volumes/backups/manual"
    echo "✓ Done. Fresh install will use ./volumes/"
    exit 0
fi

echo "Found old volume: $OLD_VOL"
echo ""

# ── Step 2: Stop containers ───────────────────────
echo "[1/4] Stopping containers..."
docker compose down
echo "✓ Stopped"

# ── Step 3: Create new volume dirs ────────────────
echo "[2/4] Creating ./volumes/ directory structure..."
mkdir -p "$PROJECT_DIR/volumes/postgres"
mkdir -p "$PROJECT_DIR/volumes/backups/daily"
mkdir -p "$PROJECT_DIR/volumes/backups/weekly"
mkdir -p "$PROJECT_DIR/volumes/backups/manual"
echo "✓ Directories created"

# ── Step 4: Copy data from old volume ────────────
echo "[3/4] Copying PostgreSQL data from named volume..."
docker run --rm \
  -v "${OLD_VOL}:/source:ro" \
  -v "$PROJECT_DIR/volumes/postgres:/dest" \
  alpine sh -c "cp -av /source/. /dest/"
echo "✓ Data copied"

# ── Step 5: Copy existing backups if any ─────────
if [ -d "$PROJECT_DIR/backups" ]; then
    echo "[4/4] Moving existing backups..."
    cp -r "$PROJECT_DIR/backups/." "$PROJECT_DIR/volumes/backups/" 2>/dev/null || true
    echo "✓ Backups moved to volumes/backups/"
else
    echo "[4/4] No existing backups to move."
fi

echo ""
echo "=================================================="
echo "  ✓ Migration complete!"
echo ""
echo "  Your data is now in:"
echo "  $PROJECT_DIR/volumes/"
echo "  ├── postgres/       ← PostgreSQL data files"
echo "  └── backups/        ← All backup files"
echo ""
echo "  Point your backup solution to:"
echo "  $PROJECT_DIR/volumes/"
echo ""
echo "  Now start the app:"
echo "  docker compose up -d"
echo "=================================================="
