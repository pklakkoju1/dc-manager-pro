#!/bin/bash
# ══════════════════════════════════════════════════════════════
# DC Manager Pro — Netdata Child Node Installer
#
# Installs and configures a Netdata child agent on any Linux
# machine (bare metal or VM) and connects it to the DC Manager
# parent node for centralised monitoring.
#
# Install methods:
#   --method systemd    Native systemd service (default)
#                       Recommended for bare metal — starts before
#                       Docker, survives reboots automatically.
#   --method docker     Docker container
#                       Use when the machine already runs Docker
#                       and you prefer container-based agents.
#   --method compose    Docker Compose file
#                       Creates /opt/netdata-child/docker-compose.yml
#                       and starts the agent with docker compose up.
#
# Online and offline (air-gapped) installs are both supported.
#
# Usage examples:
#
#   systemd — online:
#     sudo ./install-netdata-child.sh \
#       --parent 192.168.86.130 \
#       --apikey a1b2c3d4-e5f6-7890-abcd-ef1234567890 \
#       --name   baremetal-01
#
#   systemd — offline (needs netdata-child-offline-*.tar.gz):
#     sudo ./install-netdata-child.sh \
#       --parent  192.168.86.130 \
#       --apikey  a1b2c3d4-e5f6-7890-abcd-ef1234567890 \
#       --name    baremetal-01 \
#       --offline ./netdata-static-installer.gz.run
#
#   docker — online:
#     sudo ./install-netdata-child.sh \
#       --parent 192.168.86.130 \
#       --apikey a1b2c3d4-e5f6-7890-abcd-ef1234567890 \
#       --name   baremetal-01 \
#       --method docker
#
#   docker — offline (needs netdata-image-*.tar from docker save):
#     sudo ./install-netdata-child.sh \
#       --parent  192.168.86.130 \
#       --apikey  a1b2c3d4-e5f6-7890-abcd-ef1234567890 \
#       --name    baremetal-01 \
#       --method  docker \
#       --offline /opt/netdata-image.tar
#
#   compose — online:
#     sudo ./install-netdata-child.sh \
#       --parent 192.168.86.130 \
#       --apikey a1b2c3d4-e5f6-7890-abcd-ef1234567890 \
#       --name   baremetal-01 \
#       --method compose
#
#   compose — offline:
#     sudo ./install-netdata-child.sh \
#       --parent  192.168.86.130 \
#       --apikey  a1b2c3d4-e5f6-7890-abcd-ef1234567890 \
#       --name    baremetal-01 \
#       --method  compose \
#       --offline /opt/netdata-image.tar
#
# Arguments:
#   --parent  IP     DC Manager VM IP (required)
#   --apikey  KEY    Stream API key — must match parent netdata.conf [stream] api key
#   --name    NAME   Hostname label in dashboard (default: system hostname)
#   --method  MODE   systemd | docker | compose  (default: systemd)
#   --offline FILE   systemd: path to netdata-static-installer.gz.run
#                    docker/compose: path to netdata image tar
#   --help           Show this help
#
# ══════════════════════════════════════════════════════════════

set -e

# ── Defaults ──────────────────────────────────────────────────
PARENT_IP=""
API_KEY="DCMANAGER-STREAM-KEY-CHANGE-THIS-NOW"
NODE_NAME="$(hostname)"
INSTALL_METHOD="systemd"
OFFLINE_FILE=""

# ── Argument parser ───────────────────────────────────────────
while [[ $# -gt 0 ]]; do
    case "$1" in
        --parent)  PARENT_IP="$2";       shift 2 ;;
        --apikey)  API_KEY="$2";         shift 2 ;;
        --name)    NODE_NAME="$2";       shift 2 ;;
        --method)  INSTALL_METHOD="$2";  shift 2 ;;
        --offline) OFFLINE_FILE="$2";    shift 2 ;;
        --help)
            grep "^#" "$0" | head -60 | sed 's/^# \?//'
            exit 0
            ;;
        *) echo "ERROR: Unknown argument: $1"; echo "Use --help for usage."; exit 1 ;;
    esac
done

# ── Guards ────────────────────────────────────────────────────
if [ -z "$PARENT_IP" ]; then
    echo "ERROR: --parent is required."
    echo "Usage: sudo $0 --parent 192.168.86.130 --apikey YOUR-KEY --name this-node"
    exit 1
fi

if [[ "$INSTALL_METHOD" != "systemd" && \
      "$INSTALL_METHOD" != "docker"  && \
      "$INSTALL_METHOD" != "compose" ]]; then
    echo "ERROR: --method must be systemd, docker, or compose (got: $INSTALL_METHOD)"
    exit 1
fi

if [ "$EUID" -ne 0 ]; then
    echo "ERROR: Must run as root.  Use:  sudo $0 $*"
    exit 1
fi

# ── Header ────────────────────────────────────────────────────
echo "══════════════════════════════════════════════════"
echo "  DC Manager Pro — Netdata Child Installer"
echo "══════════════════════════════════════════════════"
echo "  Node    : $NODE_NAME  ($(hostname -I | awk '{print $1}'))"
echo "  Parent  : $PARENT_IP:19999"
echo "  Method  : $INSTALL_METHOD"
echo "  Mode    : $([ -n "$OFFLINE_FILE" ] && echo "offline → $OFFLINE_FILE" || echo "online")"
echo "  API key : ${API_KEY:0:8}..."
echo ""

# ════════════════════════════════════════════════════════════
#  SHARED: write_configs CONF_DIR
#  Writes netdata.conf + stream.conf into the given directory.
#  Called by all three install methods before the agent starts.
# ════════════════════════════════════════════════════════════
write_configs() {
    local CONF_DIR="$1"
    mkdir -p "$CONF_DIR"

    # Main config — minimal child: no local web UI, RAM-only storage
    cat > "$CONF_DIR/netdata.conf" << NETDATA_CONF
# DC Manager Pro — Netdata child node
# Machine : $NODE_NAME
# Parent  : $PARENT_IP

[global]
    hostname             = $NODE_NAME
    run as user          = netdata
    history              = 300
    cloud                = no
    anonymous statistics = no
    update every         = 1
    memory mode          = ram

[web]
    # No local dashboard — view everything on parent at:
    # http://$PARENT_IP:19999
    mode = none

[plugins]
    proc       = yes
    diskspace  = yes
    cgroups    = yes
    tc         = yes
    idlejitter = yes
    apps       = yes
    charts.d   = yes
    python.d   = yes
    node.d     = no
    netdata monitoring = no
NETDATA_CONF

    # Stream config — send all metrics to parent
    cat > "$CONF_DIR/stream.conf" << STREAM_CONF
# DC Manager Pro — child streaming config
# Pushes metrics → parent at $PARENT_IP:19999

[stream]
    enabled            = yes
    destination        = $PARENT_IP:19999
    api key            = $API_KEY
    reconnect delay    = 5
    buffer size        = 1048576
    enable compression = yes
    timeout            = 60
STREAM_CONF

    echo "      Config written → $CONF_DIR/"
}

# ════════════════════════════════════════════════════════════
#  SHARED: check_offline_file MIN_BYTES DESC
#  Validates that an offline file exists and is big enough.
# ════════════════════════════════════════════════════════════
check_offline_file() {
    local MIN="$1"
    local DESC="$2"
    if [ ! -f "$OFFLINE_FILE" ]; then
        echo "ERROR: Offline file not found: $OFFLINE_FILE"
        echo "       $DESC"
        exit 1
    fi
    local BYTES
    BYTES=$(stat -c%s "$OFFLINE_FILE" 2>/dev/null || stat -f%z "$OFFLINE_FILE")
    if [ "$BYTES" -lt "$MIN" ]; then
        echo "ERROR: File is only ${BYTES} bytes — looks corrupt or incomplete."
        echo "       $DESC"
        exit 1
    fi
}

# ════════════════════════════════════════════════════════════
#  SHARED: load_or_pull_docker_image
#  Loads from offline tar or pulls from Docker Hub.
# ════════════════════════════════════════════════════════════
load_or_pull_docker_image() {
    if ! command -v docker &>/dev/null; then
        echo "ERROR: Docker is not installed on this machine."
        echo "       Install Docker first:  curl -fsSL https://get.docker.com | sh"
        echo "       Or use --method systemd for a native install instead."
        exit 1
    fi
    echo "[info] Docker: $(docker --version)"

    if [ -n "$OFFLINE_FILE" ]; then
        check_offline_file 10485760 \
            "Create with: docker save netdata/netdata:stable -o netdata-image.tar"
        echo "      Loading image from: $OFFLINE_FILE ..."
        docker load -i "$OFFLINE_FILE"
        echo "      ✓ Image loaded"
    else
        echo "      Pulling netdata/netdata:stable ..."
        docker pull netdata/netdata:stable
        echo "      ✓ Image pulled"
    fi
}

# ════════════════════════════════════════════════════════════
#  METHOD: systemd
# ════════════════════════════════════════════════════════════
install_systemd() {

    # ── 1. Install package ────────────────────────────────────
    if command -v netdata &>/dev/null || \
       [ -f /usr/sbin/netdata ] || \
       [ -f /opt/netdata/usr/sbin/netdata ]; then
        echo "[1/4] Netdata already installed — skipping to config update"
    else
        echo "[1/4] Installing Netdata (systemd)..."

        if [ -n "$OFFLINE_FILE" ]; then
            check_offline_file 1048576 \
                "Create with: ./scripts/save-netdata-child-offline.sh"
            echo "      Running static installer (no internet)..."
            chmod +x "$OFFLINE_FILE"
            "$OFFLINE_FILE" \
                --dont-start-it \
                --disable-telemetry \
                --dont-wait \
                --no-updates \
                -- DONOTSTART=1 2>&1 | tail -8
        else
            if ! command -v curl &>/dev/null; then
                apt-get update -qq && apt-get install -y curl 2>/dev/null || \
                yum install -y curl 2>/dev/null || \
                dnf install -y curl 2>/dev/null || true
            fi
            echo "      Running Netdata kickstart (online)..."
            curl -fsSL https://get.netdata.cloud/kickstart.sh | bash -s -- \
                --dont-start-it \
                --disable-telemetry \
                --dont-wait \
                --no-updates \
                2>&1 | tail -8
        fi
        echo "      ✓ Installed"
    fi

    # ── 2. Stop for config ────────────────────────────────────
    echo ""
    echo "[2/4] Stopping Netdata..."
    systemctl stop netdata 2>/dev/null || service netdata stop 2>/dev/null || true

    # ── 3. Write configs ──────────────────────────────────────
    echo ""
    echo "[3/4] Writing configuration..."
    write_configs "/etc/netdata"

    # ── 4. Enable and start ───────────────────────────────────
    echo ""
    echo "[4/4] Starting Netdata service..."
    systemctl enable netdata 2>/dev/null || true
    systemctl start  netdata 2>/dev/null || service netdata start 2>/dev/null
    sleep 5

    if systemctl is-active --quiet netdata 2>/dev/null || pgrep -x netdata &>/dev/null; then
        echo "      ✓ Service running"
    else
        echo "      ✗ Service failed to start"
        echo "        Logs: journalctl -u netdata -n 50 --no-pager"
        exit 1
    fi

    echo ""
    echo "  Day-to-day commands:"
    echo "  systemctl status  netdata   # status"
    echo "  journalctl -u netdata -f    # live logs"
    echo "  systemctl restart netdata   # restart after config change"
    echo "  systemctl stop    netdata   # stop"
}

# ════════════════════════════════════════════════════════════
#  METHOD: docker
# ════════════════════════════════════════════════════════════
install_docker() {

    echo "[1/4] Checking Docker and image..."
    load_or_pull_docker_image

    # ── Remove stale container if present ────────────────────
    if docker ps -a --format '{{.Names}}' | grep -q "^netdata-child$"; then
        echo "      Removing existing netdata-child container..."
        docker stop netdata-child 2>/dev/null || true
        docker rm   netdata-child 2>/dev/null || true
    fi

    # ── Write configs to host BEFORE container starts ─────────
    # The container mounts /etc/netdata from the host.
    # If configs are missing when it first starts, Netdata
    # generates defaults that DON'T include streaming — so the
    # child would run silently without ever connecting to parent.
    echo ""
    echo "[2/4] Writing configuration (before container start)..."
    write_configs "/etc/netdata"

    # ── Create data directories ───────────────────────────────
    mkdir -p /var/lib/netdata /var/cache/netdata

    # ── Start container ───────────────────────────────────────
    echo ""
    echo "[3/4] Starting Netdata container..."

    docker run -d \
        --name    netdata-child \
        --restart unless-stopped \
        --hostname "$NODE_NAME" \
        --pid     host \
        --network host \
        --cap-add SYS_PTRACE \
        --cap-add SYS_ADMIN \
        --security-opt apparmor:unconfined \
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
        netdata/netdata:stable

    sleep 5

    echo ""
    echo "[4/4] Checking container..."
    if docker ps --format '{{.Names}}' | grep -q "^netdata-child$"; then
        echo "      ✓ Container running"
    else
        echo "      ✗ Container failed to start"
        echo "        Logs: docker logs netdata-child --tail 50"
        exit 1
    fi

    echo ""
    echo "  Day-to-day commands:"
    echo "  docker ps | grep netdata-child    # status"
    echo "  docker logs netdata-child -f      # live logs"
    echo "  docker restart netdata-child      # restart after config change"
    echo "  docker stop    netdata-child      # stop"
    echo "  docker start   netdata-child      # start"
}

# ════════════════════════════════════════════════════════════
#  METHOD: compose
# ════════════════════════════════════════════════════════════
install_compose() {

    COMPOSE_DIR="/opt/netdata-child"

    echo "[1/4] Checking Docker and image..."
    load_or_pull_docker_image

    # ── Remove stale container if present ────────────────────
    if docker ps -a --format '{{.Names}}' | grep -q "^netdata-child$"; then
        echo "      Removing existing netdata-child container..."
        cd "$COMPOSE_DIR" 2>/dev/null && docker compose down 2>/dev/null || \
        docker stop netdata-child 2>/dev/null && docker rm netdata-child 2>/dev/null || true
    fi

    # ── Write configs to host BEFORE container starts ─────────
    echo ""
    echo "[2/4] Writing Netdata configuration (before container start)..."
    write_configs "/etc/netdata"
    mkdir -p /var/lib/netdata /var/cache/netdata

    # ── Write docker-compose.yml ──────────────────────────────
    echo ""
    echo "[3/4] Writing docker-compose.yml → $COMPOSE_DIR/..."
    mkdir -p "$COMPOSE_DIR"

    cat > "$COMPOSE_DIR/docker-compose.yml" << COMPOSEYML
version: "3.9"
# DC Manager Pro — Netdata Child Node
# Node   : $NODE_NAME
# Parent : $PARENT_IP:19999
#
# Start  : cd $COMPOSE_DIR && docker compose up -d
# Stop   : docker compose stop
# Logs   : docker compose logs -f
# Remove : docker compose down

services:
  netdata:
    image: netdata/netdata:stable
    container_name: netdata-child
    restart: unless-stopped
    hostname: $NODE_NAME
    pid: host
    network_mode: host
    cap_add:
      - SYS_PTRACE
      - SYS_ADMIN
    security_opt:
      - apparmor:unconfined
    environment:
      - DO_NOT_TRACK=1
      - NETDATA_CLAIM_TOKEN=
    volumes:
      - /etc/netdata:/etc/netdata
      - /var/lib/netdata:/var/lib/netdata
      - /var/cache/netdata:/var/cache/netdata
      - /etc/passwd:/host/etc/passwd:ro
      - /etc/group:/host/etc/group:ro
      - /proc:/host/proc:ro
      - /sys:/host/sys:ro
      - /etc/os-release:/host/etc/os-release:ro
COMPOSEYML

    echo "      ✓ docker-compose.yml written"

    # ── Start with compose ────────────────────────────────────
    echo ""
    echo "[4/4] Starting with docker compose..."
    cd "$COMPOSE_DIR"
    docker compose up -d
    sleep 5

    if docker ps --format '{{.Names}}' | grep -q "^netdata-child$"; then
        echo "      ✓ Container running"
    else
        echo "      ✗ Failed to start"
        echo "        Logs: docker compose logs --tail 50"
        exit 1
    fi

    echo ""
    echo "  Day-to-day commands (from $COMPOSE_DIR):"
    echo "  docker compose ps           # status"
    echo "  docker compose logs -f      # live logs"
    echo "  docker compose restart      # restart"
    echo "  docker compose stop         # stop"
    echo "  docker compose start        # start"
    echo "  docker compose down         # stop and remove container"
}

# ════════════════════════════════════════════════════════════
#  DISPATCH
# ════════════════════════════════════════════════════════════
case "$INSTALL_METHOD" in
    systemd) install_systemd ;;
    docker)  install_docker  ;;
    compose) install_compose ;;
esac

# ════════════════════════════════════════════════════════════
#  VERIFY STREAM CONNECTION
# ════════════════════════════════════════════════════════════
echo ""
echo "  Checking stream connection to parent..."
sleep 8

CONNECTED=0
case "$INSTALL_METHOD" in
    systemd)
        journalctl -u netdata --no-pager -n 100 2>/dev/null | \
            grep -qi "connected\|STREAM.*ok\|stream.*success" && CONNECTED=1 || true
        ;;
    docker|compose)
        docker logs netdata-child 2>&1 | \
            grep -qi "connected\|STREAM.*ok\|stream.*success" && CONNECTED=1 || true
        ;;
esac

if [ "$CONNECTED" -eq 1 ]; then
    echo "  ✓ Stream confirmed — metrics flowing to parent"
else
    echo "  ⏳ Not yet confirmed (normal — may take up to 30s)"
    echo ""
    echo "  Check manually:"
    case "$INSTALL_METHOD" in
        systemd)
            echo "  journalctl -u netdata --no-pager | grep -i connected"
            ;;
        docker|compose)
            echo "  docker logs netdata-child 2>&1 | grep -i connected"
            ;;
    esac
fi

# ════════════════════════════════════════════════════════════
#  FINAL SUMMARY
# ════════════════════════════════════════════════════════════
NODE_IP=$(hostname -I | awk '{print $1}')
echo ""
echo "══════════════════════════════════════════════════"
echo "  ✓ Child node enrolled successfully!"
echo ""
echo "  Node    : $NODE_NAME  ($NODE_IP)"
echo "  Method  : $INSTALL_METHOD"
echo "  Streams : → $PARENT_IP:19999"
echo ""
echo "  Open parent dashboard:"
echo "  http://$PARENT_IP:19999"
echo "  Use the host dropdown (top-right) → $NODE_NAME"
echo "══════════════════════════════════════════════════"
