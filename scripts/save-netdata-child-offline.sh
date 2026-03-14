#!/bin/bash
# ══════════════════════════════════════════════════════════════
# DC Manager Pro — Save Netdata Child Package (Offline/Air-Gapped)
#
# Run this on an internet-connected machine to create packages
# that can install Netdata child agents on machines with NO internet.
#
# Creates two types of package — use the one matching your child install method:
#
#   Default (systemd):
#     ./save-netdata-child-offline.sh
#     → netdata-child-offline-YYYYMMDD.tar.gz   (~80MB)
#     Used with: install-netdata-child-systemd.sh --offline ...
#
#   Docker image:
#     ./save-netdata-child-offline.sh --docker
#     → netdata-image-YYYYMMDD.tar              (~200MB)
#     Used with: install-netdata-child-docker.sh --offline ...
#
#   Both:
#     ./save-netdata-child-offline.sh --both
#
# Usage:
#   ./save-netdata-child-offline.sh [--systemd|--docker|--both] [output-dir]
# ══════════════════════════════════════════════════════════════

set -e

DO_SYSTEMD=1
DO_DOCKER=0
OUTPUT_DIR="$(pwd)"

for arg in "$@"; do
    case "$arg" in
        --systemd) DO_SYSTEMD=1; DO_DOCKER=0 ;;
        --docker)  DO_DOCKER=1;  DO_SYSTEMD=0 ;;
        --both)    DO_SYSTEMD=1; DO_DOCKER=1  ;;
        --*)       echo "ERROR: Unknown option: $arg"; exit 1 ;;
        *)         OUTPUT_DIR="$arg" ;;
    esac
done

# Resolve project root BEFORE any cd changes working directory
SCRIPT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
DATE=$(date +%Y%m%d)
ARCH=$(uname -m)
mkdir -p "$OUTPUT_DIR"

echo "══════════════════════════════════════════════════"
echo "  Netdata Offline Package Creator"
echo "══════════════════════════════════════════════════"
echo "  Arch   : $ARCH"
echo "  Output : $OUTPUT_DIR"
echo "  systemd: $([ "$DO_SYSTEMD" -eq 1 ] && echo yes || echo no)"
echo "  Docker : $([ "$DO_DOCKER"  -eq 1 ] && echo yes || echo no)"
echo ""

# ── systemd package ───────────────────────────────────────────
if [ "$DO_SYSTEMD" -eq 1 ]; then
    OUTFILE="$OUTPUT_DIR/netdata-child-offline-$DATE.tar.gz"
    TMPDIR=$(mktemp -d)
    trap "rm -rf $TMPDIR" EXIT

    echo "── systemd static installer ──────────────────────"
    echo "[1/3] Downloading static installer (~80MB)..."
    mkdir -p "$TMPDIR/pkg"

    curl -fsSL --retry 3 \
        "https://github.com/netdata/netdata/releases/latest/download/netdata-$ARCH.gz.run" \
        -o "$TMPDIR/pkg/netdata-static-installer.gz.run"
    chmod +x "$TMPDIR/pkg/netdata-static-installer.gz.run"

    BYTES=$(stat -c%s "$TMPDIR/pkg/netdata-static-installer.gz.run" 2>/dev/null || \
            stat -f%z "$TMPDIR/pkg/netdata-static-installer.gz.run")
    if [ "$BYTES" -lt 1048576 ]; then
        echo "ERROR: Download failed — file is only ${BYTES} bytes. Check internet connection."
        exit 1
    fi
    echo "      Downloaded: $(du -sh "$TMPDIR/pkg/netdata-static-installer.gz.run" | cut -f1)"

    echo "[2/3] Copying installer script..."
    cp "$SCRIPT_DIR/scripts/install-netdata-child-systemd.sh" "$TMPDIR/pkg/"

    echo "[3/3] Creating archive..."
    tar -czf "$OUTFILE" -C "$TMPDIR" "pkg/"
    sha256sum "$OUTFILE" > "$OUTFILE.sha256"
    trap - EXIT; rm -rf "$TMPDIR"

    echo "      ✓ $(du -sh "$OUTFILE" | cut -f1)  →  $OUTFILE"
    echo ""
    echo "  Transfer: scp $OUTFILE user@target:/opt/"
    echo "  Install:"
    echo "    tar -xzf $(basename "$OUTFILE") -C /opt/"
    echo "    sudo bash /opt/pkg/install-netdata-child-systemd.sh \\"
    echo "      --parent YOUR-DC-MANAGER-IP \\"
    echo "      --apikey YOUR-STREAM-API-KEY \\"
    echo "      --name   this-machine-name \\"
    echo "      --offline /opt/pkg/netdata-static-installer.gz.run"
    echo ""
fi

# ── Docker image tar ──────────────────────────────────────────
if [ "$DO_DOCKER" -eq 1 ]; then
    IMGFILE="$OUTPUT_DIR/netdata-image-$DATE.tar"

    echo "── Docker image ──────────────────────────────────"
    echo "[1/2] Pulling netdata/netdata:stable..."
    docker pull netdata/netdata:stable

    echo "[2/2] Saving to tar (~200MB)..."
    docker save netdata/netdata:stable -o "$IMGFILE"
    sha256sum "$IMGFILE" > "$IMGFILE.sha256"

    echo "      ✓ $(du -sh "$IMGFILE" | cut -f1)  →  $IMGFILE"
    echo ""
    echo "  Transfer: scp $IMGFILE user@target:/opt/"
    echo "  Also copy: scp scripts/install-netdata-child-docker.sh user@target:/opt/"
    echo "  Install:"
    echo "    sudo bash /opt/install-netdata-child-docker.sh \\"
    echo "      --parent YOUR-DC-MANAGER-IP \\"
    echo "      --apikey YOUR-STREAM-API-KEY \\"
    echo "      --name   this-machine-name \\"
    echo "      --offline /opt/$(basename "$IMGFILE")"
    echo ""
fi

echo "══════════════════════════════════════════════════"
echo "  ✓ Done!"
echo "══════════════════════════════════════════════════"
