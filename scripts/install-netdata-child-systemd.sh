#!/bin/bash
# ══════════════════════════════════════════════════════════════
# DC Manager Pro — Netdata Child Installer (systemd)
#
# Installs Netdata as a native systemd service and streams
# metrics to your DC Manager monitoring parent.
#
# Requirements:
#   - Linux with systemd (Ubuntu, Debian, RHEL, Rocky, etc.)
#   - sudo / root access
#   - The NETDATA_STREAM_API_KEY from your DC Manager .env file
#   - The DC Manager VM IP address
#
# Usage — with internet:
#   sudo ./install-netdata-child-systemd.sh \
#     --parent 192.168.86.130 \
#     --apikey a1b2c3d4-e5f6-7890-abcd-ef1234567890 \
#     --name   baremetal-01
#
# Usage — air-gapped (no internet on this machine):
#   sudo ./install-netdata-child-systemd.sh \
#     --parent  192.168.86.130 \
#     --apikey  a1b2c3d4-e5f6-7890-abcd-ef1234567890 \
#     --name    baremetal-01 \
#     --offline /opt/netdata-static-installer.gz.run
#
#   The offline installer is created on an internet machine by:
#     ./save-netdata-child-offline.sh
#
# Arguments:
#   --parent  IP     Your DC Manager VM IP (required)
#   --apikey  KEY    NETDATA_STREAM_API_KEY from your .env (required)
#   --name    NAME   Label shown in dashboard (default: hostname)
#   --offline FILE   Path to netdata-static-installer.gz.run
#   --help           Show this help
# ══════════════════════════════════════════════════════════════

set -e

PARENT_IP=""
API_KEY=""
NODE_NAME="$(hostname -s)"
OFFLINE_FILE=""

while [[ $# -gt 0 ]]; do
    case "$1" in
        --parent)  PARENT_IP="$2";    shift 2 ;;
        --apikey)  API_KEY="$2";      shift 2 ;;
        --name)    NODE_NAME="$2";    shift 2 ;;
        --offline) OFFLINE_FILE="$2"; shift 2 ;;
        --help|-h) grep "^#" "$0" | head -35 | sed 's/^# \?//'; exit 0 ;;
        *) echo "ERROR: Unknown argument: $1 — use --help"; exit 1 ;;
    esac
done

# ── Guards ────────────────────────────────────────────────────
[[ -z "$PARENT_IP" ]] && { echo "ERROR: --parent required"; exit 1; }
[[ -z "$API_KEY"   ]] && { echo "ERROR: --apikey required (use NETDATA_STREAM_API_KEY from .env)"; exit 1; }
[[ "$EUID" -ne 0   ]] && { echo "ERROR: run with sudo"; exit 1; }

echo "══════════════════════════════════════════════════"
echo "  Netdata Child — systemd installer"
echo "══════════════════════════════════════════════════"
echo "  Node     : $NODE_NAME  ($(hostname -I | awk '{print $1}'))"
echo "  Parent   : $PARENT_IP:19999"
echo "  Internet : $([ -n "$OFFLINE_FILE" ] && echo "No — offline mode" || echo "Yes — online mode")"
echo ""

# ── Step 1: Install ───────────────────────────────────────────
echo "[1/4] Installing Netdata..."

if command -v netdata &>/dev/null || [ -f /usr/sbin/netdata ] || [ -f /opt/netdata/usr/sbin/netdata ]; then
    echo "      Already installed — skipping, will update config only"
else
    if [ -n "$OFFLINE_FILE" ]; then
        [[ ! -f "$OFFLINE_FILE" ]] && { echo "ERROR: File not found: $OFFLINE_FILE"; exit 1; }
        BYTES=$(stat -c%s "$OFFLINE_FILE" 2>/dev/null || stat -f%z "$OFFLINE_FILE")
        [[ "$BYTES" -lt 1048576 ]] && { echo "ERROR: File too small (${BYTES}B) — looks corrupt"; exit 1; }
        echo "      Running offline static installer..."
        chmod +x "$OFFLINE_FILE"
        "$OFFLINE_FILE" --dont-start-it --disable-telemetry --dont-wait --no-updates \
            -- DONOTSTART=1 2>&1 | tail -5
    else
        command -v curl &>/dev/null || \
            { apt-get install -y curl 2>/dev/null || yum install -y curl 2>/dev/null || dnf install -y curl 2>/dev/null || true; }
        echo "      Downloading and running official Netdata installer..."
        curl -fsSL https://get.netdata.cloud/kickstart.sh | bash -s -- \
            --dont-start-it --disable-telemetry --dont-wait --no-updates 2>&1 | tail -5
    fi
    echo "      ✓ Installed"
fi

# ── Step 2: Stop service before writing config ────────────────
echo ""
echo "[2/4] Stopping Netdata for configuration..."
systemctl stop netdata 2>/dev/null || service netdata stop 2>/dev/null || true

# ── Step 3: Write config ──────────────────────────────────────
echo ""
echo "[3/4] Writing config files..."
mkdir -p /etc/netdata

cat > /etc/netdata/netdata.conf << CONF
# Managed by DC Manager Pro — Netdata child (systemd)
# Node: $NODE_NAME
#
# Child role: collect metrics locally and stream to parent.
# The parent stores all history and serves the dashboard.
# This config is intentionally minimal — plugins auto-detect.

[global]
    hostname             = $NODE_NAME
    update every         = 1
    cloud                = no
    anonymous statistics = no

    # RAM mode — child only needs a small buffer to stream.
    # The parent (dbengine) stores all long-term history.
    memory mode          = ram
    history              = 600    # 10 min buffer if parent temporarily unreachable

[web]
    # No local dashboard — all viewing is on parent at :19999
    mode = none

[plugins]
    # Core metrics — always collect on any node
    proc             = yes   # CPU, RAM, disk I/O, network
    diskspace        = yes   # disk usage per mount point
    cgroups          = yes   # Docker container metrics (if Docker is running)
    apps             = yes   # per-process: CPU/RAM by process name
    idlejitter       = yes   # CPU scheduling latency
    tc               = yes   # network traffic shaping
    go.d             = yes   # modern collectors (postgres, nginx, http checks)

    # Container name resolution — resolves hex IDs to container names
    # Only has effect if Docker is installed on this node
    cgroup network interfaces = yes

    # Disable — not needed on child nodes
    python.d         = no    # legacy, go.d covers the same collectors
    charts.d         = no
    node.d           = no
    netdata monitoring = no
CONF

cat > /etc/netdata/stream.conf << CONF
# Managed by DC Manager Pro — streams metrics to parent

[stream]
    enabled            = yes
    destination        = $PARENT_IP:19999
    api key            = $API_KEY
    reconnect delay    = 5
    buffer size        = 1048576
    enable compression = yes
    timeout            = 60
CONF

echo "      ✓ /etc/netdata/netdata.conf"
echo "      ✓ /etc/netdata/stream.conf"

# ── Step 4: Enable and start ──────────────────────────────────
echo ""
echo "[4/4] Starting Netdata service..."
systemctl enable netdata 2>/dev/null || true
systemctl start  netdata 2>/dev/null || service netdata start 2>/dev/null
sleep 5

if systemctl is-active --quiet netdata 2>/dev/null || pgrep -x netdata &>/dev/null; then
    echo "      ✓ netdata.service is running"
else
    echo "      ✗ Failed to start — check: journalctl -u netdata -n 30 --no-pager"
    exit 1
fi

# ── Verify stream ─────────────────────────────────────────────
echo ""
echo "  Waiting for stream connection (10s)..."
sleep 10
if journalctl -u netdata --no-pager -n 50 2>/dev/null | grep -qi "connected\|STREAM.*ok"; then
    echo "  ✓ Connected to parent — metrics are streaming"
else
    echo "  ⏳ Not yet confirmed — check in 30s:"
    echo "     journalctl -u netdata --no-pager | grep -i connected"
fi

NODE_IP=$(hostname -I | awk '{print $1}')
echo ""
echo "══════════════════════════════════════════════════"
echo "  ✓ Done! Node: $NODE_NAME ($NODE_IP)"
echo "  View: http://$PARENT_IP:19999"
echo "  Host dropdown (top-right) → $NODE_NAME"
echo ""
echo "  Commands:"
echo "  systemctl status  netdata"
echo "  systemctl restart netdata"
echo "  journalctl -u netdata -f"
echo "══════════════════════════════════════════════════"
