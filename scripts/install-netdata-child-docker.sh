#!/bin/bash
# ══════════════════════════════════════════════════════════════
# DC Manager Pro — Netdata Child Installer (Docker)
#
# Runs Netdata as a Docker container that streams metrics to
# your DC Manager monitoring parent.
#
# Requirements:
#   - Docker installed on this machine
#   - sudo / root access
#   - The NETDATA_STREAM_API_KEY from your DC Manager .env file
#   - The DC Manager VM IP address
#
# Usage — with internet:
#   sudo ./install-netdata-child-docker.sh \
#     --parent 192.168.86.130 \
#     --apikey a1b2c3d4-e5f6-7890-abcd-ef1234567890 \
#     --name   baremetal-01
#
# Usage — air-gapped (no internet on this machine):
#   sudo ./install-netdata-child-docker.sh \
#     --parent  192.168.86.130 \
#     --apikey  a1b2c3d4-e5f6-7890-abcd-ef1234567890 \
#     --name    baremetal-01 \
#     --offline /opt/netdata-image.tar
#
#   The offline image is created on an internet machine by:
#     ./save-netdata-child-offline.sh --docker
#
# Arguments:
#   --parent  IP     Your DC Manager VM IP (required)
#   --apikey  KEY    NETDATA_STREAM_API_KEY from your .env (required)
#   --name    NAME   Label shown in dashboard (default: hostname)
#   --offline FILE   Path to saved Docker image tar
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

if ! command -v docker &>/dev/null; then
    echo "ERROR: Docker not installed."
    echo "       Install: curl -fsSL https://get.docker.com | sh"
    echo "       Then:    sudo usermod -aG docker \$USER && newgrp docker"
    exit 1
fi

echo "══════════════════════════════════════════════════"
echo "  Netdata Child — Docker installer"
echo "══════════════════════════════════════════════════"
echo "  Node     : $NODE_NAME  ($(hostname -I | awk '{print $1}'))"
echo "  Parent   : $PARENT_IP:19999"
echo "  Internet : $([ -n "$OFFLINE_FILE" ] && echo "No — offline mode" || echo "Yes — online mode")"
echo "  Docker   : $(docker --version)"
echo ""

# ── Step 1: Get image ─────────────────────────────────────────
echo "[1/4] Getting Netdata Docker image..."

if [ -n "$OFFLINE_FILE" ]; then
    [[ ! -f "$OFFLINE_FILE" ]] && { echo "ERROR: File not found: $OFFLINE_FILE"; exit 1; }
    BYTES=$(stat -c%s "$OFFLINE_FILE" 2>/dev/null || stat -f%z "$OFFLINE_FILE")
    [[ "$BYTES" -lt 10485760 ]] && { echo "ERROR: File too small (${BYTES}B) — looks corrupt"; exit 1; }
    echo "      Loading from: $OFFLINE_FILE"
    docker load -i "$OFFLINE_FILE"
    echo "      ✓ Image loaded"
else
    echo "      Pulling netdata/netdata:stable..."
    docker pull netdata/netdata:stable
    echo "      ✓ Image pulled"
fi

# ── Step 2: Write config BEFORE starting container ─────────────
# CRITICAL: /etc/netdata is mounted from the host.
# If configs don't exist when the container first starts,
# Netdata auto-generates defaults WITHOUT streaming enabled.
# The node would run but never appear in the parent dashboard.
echo ""
echo "[2/4] Writing config files (before container start)..."
mkdir -p /etc/netdata /var/lib/netdata /var/cache/netdata

cat > /etc/netdata/netdata.conf << CONF
# Managed by DC Manager Pro — Netdata child (Docker)
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
    # Works when /var/run/docker.sock is mounted (done by docker run command below)
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

# ── Step 3: Remove old container if exists ────────────────────
echo ""
echo "[3/4] Preparing container..."
if docker ps -a --format '{{.Names}}' | grep -q "^netdata-child$"; then
    echo "      Removing existing netdata-child container..."
    docker stop netdata-child 2>/dev/null || true
    docker rm   netdata-child 2>/dev/null || true
fi

# ── Step 4: Start container ───────────────────────────────────
echo ""
echo "[4/4] Starting Netdata container..."

docker run -d \
    --name    netdata-child \
    --restart unless-stopped \
    --hostname "$NODE_NAME" \
    --network host \
    --pid     host \
    --cap-add SYS_PTRACE \
    --cap-add SYS_ADMIN \
    --security-opt apparmor:unconfined \
    --no-healthcheck \
    -e DO_NOT_TRACK=1 \
    -e NETDATA_CLAIM_TOKEN="" \
    -v /etc/netdata:/etc/netdata \
    -v /var/lib/netdata:/var/lib/netdata \
    -v /var/cache/netdata:/var/cache/netdata \
    -v /etc/passwd:/host/etc/passwd:ro \
    -v /etc/group:/host/etc/group:ro \
    -v /proc:/host/proc:ro \
    -v /sys:/host/sys:ro \
    -v /etc/os-release:/host/etc/os-release:ro \
    -v /var/run/docker.sock:/var/run/docker.sock:ro \
    netdata/netdata:stable

sleep 5

if docker ps --format '{{.Names}}' | grep -q "^netdata-child$"; then
    echo "      ✓ Container running"
else
    echo "      ✗ Failed to start — check: docker logs netdata-child --tail 30"
    exit 1
fi

# ── Verify stream ─────────────────────────────────────────────
echo ""
echo "  Waiting for stream connection (10s)..."
sleep 10
if docker logs netdata-child 2>&1 | grep -qi "connected\|STREAM.*ok"; then
    echo "  ✓ Connected to parent — metrics are streaming"
else
    echo "  ⏳ Not yet confirmed — check in 30s:"
    echo "     docker logs netdata-child 2>&1 | grep -i connected"
fi

NODE_IP=$(hostname -I | awk '{print $1}')
echo ""
echo "══════════════════════════════════════════════════"
echo "  ✓ Done! Node: $NODE_NAME ($NODE_IP)"
echo "  View: http://$PARENT_IP:19999"
echo "  Host dropdown (top-right) → $NODE_NAME"
echo ""
echo "  Commands:"
echo "  docker ps | grep netdata-child"
echo "  docker logs netdata-child -f"
echo "  docker restart netdata-child"
echo "══════════════════════════════════════════════════"
