#!/bin/bash
# ─────────────────────────────────────────────────────────────────────
# DC Manager Pro — Self-Signed SSL Certificate Generator
# Generates a 10-year self-signed certificate for HTTPS access by IP
# Usage: ./scripts/generate-certs.sh [server-ip]
# ─────────────────────────────────────────────────────────────────────

set -e

SERVER_IP="${1:-192.168.86.130}"
CERT_DIR="$(dirname "$0")/../certs"

mkdir -p "$CERT_DIR"

echo "Generating self-signed certificate for IP: $SERVER_IP"
echo "Output: $CERT_DIR"

# Generate private key + certificate in one step
openssl req -x509 -nodes -newkey rsa:2048 \
  -keyout "$CERT_DIR/server.key" \
  -out    "$CERT_DIR/server.crt" \
  -days   3650 \
  -subj   "/C=IN/ST=Telangana/L=Hyderabad/O=DC Manager/CN=$SERVER_IP" \
  -addext "subjectAltName=IP:$SERVER_IP,IP:127.0.0.1"

chmod 600 "$CERT_DIR/server.key"
chmod 644 "$CERT_DIR/server.crt"

echo ""
echo "✓ Certificate generated:"
echo "  Private key : $CERT_DIR/server.key"
echo "  Certificate : $CERT_DIR/server.crt"
echo "  Valid for   : 10 years"
echo "  Server IP   : $SERVER_IP"
echo ""
echo "Next: docker compose up -d --build"
echo "Open: https://$SERVER_IP"
echo ""
echo "NOTE: Your browser will show a security warning because this is"
echo "      self-signed. Click 'Advanced' → 'Proceed' to continue."
echo "      To suppress the warning, install server.crt as a trusted"
echo "      certificate on your machine (see README for instructions)."
