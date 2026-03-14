#!/bin/bash
# ══════════════════════════════════════════════════════════════
# DC Manager Pro — Load Netdata on Air-Gapped Server
#
# Run this on your offline production server after transferring
# the netdata-image-*.tar file from an internet-connected machine.
#
# Usage:
#   ./scripts/load-netdata-offline.sh netdata-image-YYYYMMDD.tar
#
# ══════════════════════════════════════════════════════════════

set -e

TARFILE="${1}"

echo "══════════════════════════════════════════"
echo "  Netdata Offline Installer"
echo "══════════════════════════════════════════"

# ── Validate input ────────────────────────────────────────────
if [ -z "$TARFILE" ]; then
    echo "Usage: $0 <netdata-image-YYYYMMDD.tar>"
    echo ""
    echo "Example:"
    echo "  ./scripts/load-netdata-offline.sh netdata-image-20260314.tar"
    exit 1
fi

if [ ! -f "$TARFILE" ]; then
    echo "ERROR: File not found: $TARFILE"
    echo ""
    echo "Transfer the file from an internet-connected machine:"
    echo "  scp user@internet-machine:/path/to/netdata-image-*.tar ."
    exit 1
fi

# ── Verify checksum if available ─────────────────────────────
if [ -f "$TARFILE.sha256" ]; then
    echo "[1/4] Verifying checksum ..."
    sha256sum -c "$TARFILE.sha256"
    echo "      ✓ Checksum OK"
else
    echo "[1/4] No checksum file found — skipping verification"
fi

# ── Load Docker image ─────────────────────────────────────────
echo "[2/4] Loading Netdata Docker image ..."
docker load -i "$TARFILE"
echo "      ✓ Image loaded"

# ── Create volume directories ────────────────────────────────
echo "[3/4] Creating Netdata volume directories ..."
cd "$(dirname "$0")/.."
mkdir -p volumes/netdata/config volumes/netdata/lib volumes/netdata/cache
echo "      ✓ Directories created"

# ── Start Netdata ─────────────────────────────────────────────
echo "[4/4] Starting Netdata container ..."
docker compose up -d netdata
sleep 3
if docker ps | grep -q dcm_netdata; then
    echo "      ✓ Netdata running"
else
    echo "      ✗ Netdata failed to start — check: docker logs dcm_netdata"
    exit 1
fi

# ── Get server IP ─────────────────────────────────────────────
SERVER_IP=$(hostname -I | awk '{print $1}')

echo ""
echo "══════════════════════════════════════════"
echo "  ✓ Netdata is running!"
echo ""
echo "  Dashboard : http://$SERVER_IP:19999"
echo ""
echo "  What you can monitor:"
echo "  • CPU, RAM, disk I/O, network per second"
echo "  • All running Docker containers"
echo "  • PostgreSQL queries and connections"
echo "  • System alerts (high CPU/RAM/disk)"
echo ""
echo "  Useful commands:"
echo "  docker logs dcm_netdata -f      # live logs"
echo "  docker restart dcm_netdata      # restart"
echo "  docker exec -it dcm_netdata bash # shell"
echo "══════════════════════════════════════════"
