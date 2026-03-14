#!/bin/bash
# ══════════════════════════════════════════════════════════════
# DC Manager Pro — Save Netdata Image for Offline Deployment
#
# Run this on an internet-connected machine ONCE.
# It pulls the Netdata image and saves it to a tar file.
# Transfer the tar to your air-gapped server and load it.
#
# Usage:
#   ./scripts/save-netdata-offline.sh [output-dir]
#
# Output: netdata-image-YYYYMMDD.tar  (~200MB compressed)
# ══════════════════════════════════════════════════════════════

set -e

OUTPUT_DIR="${1:-$(pwd)}"
DATE=$(date +%Y%m%d)
OUTFILE="$OUTPUT_DIR/netdata-image-$DATE.tar"
IMAGE="netdata/netdata:stable"

echo "══════════════════════════════════════════"
echo "  Netdata Offline Image Packager"
echo "══════════════════════════════════════════"
echo "  Image  : $IMAGE"
echo "  Output : $OUTFILE"
echo ""

# Pull latest stable
echo "[1/3] Pulling $IMAGE ..."
docker pull "$IMAGE"

# Save to tar
echo "[2/3] Saving image to tar ..."
docker save "$IMAGE" -o "$OUTFILE"
echo "      Saved: $(du -sh "$OUTFILE" | cut -f1)"

# Checksum
echo "[3/3] Generating checksum ..."
sha256sum "$OUTFILE" > "$OUTFILE.sha256"
cat "$OUTFILE.sha256"

echo ""
echo "══════════════════════════════════════════"
echo "  ✓ Done!"
echo ""
echo "  Transfer to air-gapped server:"
echo "  scp $OUTFILE user@prod-server:/appdata/dc-prod/"
echo "  scp $OUTFILE.sha256 user@prod-server:/appdata/dc-prod/"
echo ""
echo "  Then on the air-gapped server:"
echo "  cd /appdata/dc-prod"
echo "  ./scripts/load-netdata-offline.sh netdata-image-$DATE.tar"
echo "══════════════════════════════════════════"
