#!/bin/bash
# ══════════════════════════════════════════════════════════════
# DC Manager Pro — Offline Export Script
# Saves all Docker images + project files into a single tar
# Transfer to air-gapped server and run: ./import-offline.sh
# ══════════════════════════════════════════════════════════════

set -e
SCRIPT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
OUT_DIR="${1:-$SCRIPT_DIR}"
BUNDLE="$OUT_DIR/dc-manager-offline-$(date +%Y%m%d).tar"

echo "=================================================="
echo "  DC Manager Pro — Offline Bundle Creator"
echo "=================================================="
echo "  Output: $BUNDLE"
echo ""

# ── Step 1: Save Docker images ─────────────────────
echo "[1/4] Saving Docker images..."
docker save \
  dc-prod_backend \
  dc-prod_frontend \
  postgres:16-alpine \
  -o /tmp/dcm-images.tar
echo "      Images saved: $(du -sh /tmp/dcm-images.tar | cut -f1)"

# ── Step 2: Export current database ───────────────
echo "[2/4] Exporting current database..."
mkdir -p "$SCRIPT_DIR/backups/manual"
DBFILE="$SCRIPT_DIR/backups/manual/dcmanager_pre-migration_$(date +%Y%m%d_%H%M%S).sql.gz"
docker exec dcm_postgres pg_dump \
  -U "${DB_USER:-dcuser}" "${DB_NAME:-dcmanager}" | gzip > "$DBFILE"
echo "      DB exported: $(du -sh "$DBFILE" | cut -f1)"

# ── Step 3: Bundle everything ──────────────────────
echo "[3/4] Creating bundle..."
tar -cf "$BUNDLE" \
  -C "$SCRIPT_DIR" \
    docker-compose.yml \
    .env.example \
    backend/init.sql \
    backend/Dockerfile \
    backend/main.py \
    backend/requirements.txt \
    frontend/index.html \
    frontend/Dockerfile \
    nginx/nginx.conf \
    scripts/import-offline.sh \
    scripts/entrypoint-backup.sh \
    scripts/manual-backup.sh \
    scripts/restore.sh \
    README.md \
  -C /tmp images=dcm-images.tar \
  -C "$(dirname "$DBFILE")" "db=$(basename "$DBFILE")"

rm -f /tmp/dcm-images.tar
echo "      Bundle: $(du -sh "$BUNDLE" | cut -f1)"

# ── Step 4: Checksum ───────────────────────────────
echo "[4/4] Generating checksum..."
sha256sum "$BUNDLE" > "$BUNDLE.sha256"
cat "$BUNDLE.sha256"

echo ""
echo "=================================================="
echo "  ✓ Bundle ready: $BUNDLE"
echo ""
echo "  Transfer to offline server:"
echo "  scp $BUNDLE user@offline-server:/opt/"
echo "  scp $BUNDLE.sha256 user@offline-server:/opt/"
echo ""
echo "  Then on offline server:"
echo "  cd /opt && tar -xf $(basename "$BUNDLE")"
echo "  chmod +x import-offline.sh && ./import-offline.sh"
echo "=================================================="
