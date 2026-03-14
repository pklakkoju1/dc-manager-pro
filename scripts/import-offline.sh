#!/bin/bash
# ══════════════════════════════════════════════════════════════
# DC Manager Pro — Offline Import Script
# Run this on the air-gapped / no-internet server
# Usage: ./import-offline.sh [install-dir]
# ══════════════════════════════════════════════════════════════

set -e
INSTALL_DIR="${1:-/opt/dc-manager}"

echo "=================================================="
echo "  DC Manager Pro — Offline Installer"
echo "=================================================="
echo "  Install dir: $INSTALL_DIR"
echo ""

# ── Check Docker is installed ──────────────────────
if ! command -v docker &>/dev/null; then
    echo "ERROR: Docker is not installed."
    echo "Install Docker first (see bottom of this script for offline Docker install notes)"
    exit 1
fi
if ! command -v docker-compose &>/dev/null && ! docker compose version &>/dev/null 2>&1; then
    echo "ERROR: Docker Compose is not installed."
    exit 1
fi
echo "✓ Docker found: $(docker --version)"

# ── Step 1: Load Docker images ─────────────────────
echo ""
echo "[1/5] Loading Docker images (no internet needed)..."
if [ -f "images" ]; then
    docker load -i images
    echo "✓ Images loaded"
else
    echo "WARNING: 'images' file not found — skipping image load"
    echo "         (Images may already be present on this machine)"
fi

# ── Step 2: Create install directory ──────────────
echo ""
echo "[2/5] Setting up directory structure..."
mkdir -p "$INSTALL_DIR"/{backend,frontend,nginx,scripts,monitoring,backups/{daily,weekly,manual}}
mkdir -p "$INSTALL_DIR"/volumes/netdata/{config,lib,cache}

# ── Step 3: Copy project files ────────────────────
echo ""
echo "[3/5] Copying project files..."
# Files are in the same directory as this script after tar extraction
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

cp "$SCRIPT_DIR/docker-compose.yml"          "$INSTALL_DIR/"
cp "$SCRIPT_DIR/.env.example"                "$INSTALL_DIR/"
cp "$SCRIPT_DIR/backend/init.sql"            "$INSTALL_DIR/backend/"
cp "$SCRIPT_DIR/backend/Dockerfile"          "$INSTALL_DIR/backend/"
cp "$SCRIPT_DIR/backend/main.py"             "$INSTALL_DIR/backend/"
cp "$SCRIPT_DIR/backend/requirements.txt"    "$INSTALL_DIR/backend/"
cp "$SCRIPT_DIR/frontend/index.html"         "$INSTALL_DIR/frontend/"
cp "$SCRIPT_DIR/frontend/Dockerfile"         "$INSTALL_DIR/frontend/"
cp "$SCRIPT_DIR/nginx/nginx.conf"            "$INSTALL_DIR/nginx/"
cp "$SCRIPT_DIR/scripts/"*.sh               "$INSTALL_DIR/scripts/"
[ -d "$SCRIPT_DIR/monitoring" ] && cp "$SCRIPT_DIR/monitoring/"* "$INSTALL_DIR/monitoring/" 2>/dev/null || true
chmod +x "$INSTALL_DIR/scripts/"*.sh
[ -f "$SCRIPT_DIR/README.md" ] && cp "$SCRIPT_DIR/README.md" "$INSTALL_DIR/"
echo "✓ Files copied"

# ── Step 4: Configure .env ────────────────────────
echo ""
echo "[4/5] Configuring environment..."
if [ ! -f "$INSTALL_DIR/.env" ]; then
    cp "$INSTALL_DIR/.env.example" "$INSTALL_DIR/.env"
    # Generate a random JWT secret automatically
    JWT=$(cat /dev/urandom | tr -dc 'a-f0-9' | head -c 64)
    sed -i "s|changethis_generate_a_real_secret_here|$JWT|g" "$INSTALL_DIR/.env"
    echo ""
    echo "  ┌─────────────────────────────────────────────┐"
    echo "  │  ACTION REQUIRED: Set your DB password      │"
    echo "  │  nano $INSTALL_DIR/.env                     │"
    echo "  │  Change DB_PASS to something strong         │"
    echo "  └─────────────────────────────────────────────┘"
    echo ""
fi

# ── Step 5: Restore DB if migration backup found ──
echo "[5/5] Checking for migration database..."
DB_BACKUP=$(ls "$SCRIPT_DIR"/db 2>/dev/null | head -1)
if [ -n "$DB_BACKUP" ]; then
    echo "  Found migration DB: $DB_BACKUP"
    cp "$SCRIPT_DIR/db" "$INSTALL_DIR/backups/manual/"
    echo ""
    echo "  ┌──────────────────────────────────────────────────────┐"
    echo "  │  A database backup from your old server was found.  │"
    echo "  │  After starting the app, restore it with:           │"
    echo "  │  cd $INSTALL_DIR                                    │"
    echo "  │  ./scripts/restore.sh backups/manual/$DB_BACKUP     │"
    echo "  └──────────────────────────────────────────────────────┘"
    echo ""
else
    echo "  No migration DB found — will start with clean database"
fi

echo ""
echo "=================================================="
echo "  ✓ Installation complete!"
echo ""
echo "  Next steps:"
echo "  1. cd $INSTALL_DIR"
echo "  2. nano .env         ← set DB_PASS"
echo "  3. docker compose up -d --build"
echo "  4. Open: http://$(hostname -I | awk '{print $1}'):3000"
echo ""
echo "  Default login:  admin / Admin@123"
echo "  ⚠  Change password immediately after first login!"
echo "=================================================="
