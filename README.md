# ⬡ DC Manager Pro — v3.1.2

**Production Datacenter Asset Management Platform**  
Developed by **pklakkoju**

[![version](https://img.shields.io/badge/version-3.1.2-38bdf8?style=flat-square&labelColor=0a0a0f)](.)
[![python](https://img.shields.io/badge/Python-3.12-3776ab?style=flat-square&logo=python&logoColor=white&labelColor=0a0a0f)](.)
[![fastapi](https://img.shields.io/badge/FastAPI-0.111-009688?style=flat-square&logo=fastapi&logoColor=white&labelColor=0a0a0f)](.)
[![postgres](https://img.shields.io/badge/PostgreSQL-16-336791?style=flat-square&logo=postgresql&logoColor=white&labelColor=0a0a0f)](.)
[![docker](https://img.shields.io/badge/Docker-Compose-2496ed?style=flat-square&logo=docker&logoColor=white&labelColor=0a0a0f)](.)
[![nginx](https://img.shields.io/badge/Nginx-1.25-009900?style=flat-square&logo=nginx&logoColor=white&labelColor=0a0a0f)](.)
[![license](https://img.shields.io/badge/license-MIT-22c55e?style=flat-square&labelColor=0a0a0f)](.)

---

## License

```
MIT License

Copyright (c) 2026 pklakkoju

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
THE SOFTWARE.
```

---

## Technology Stack

### Languages
| Language | Version | Used For |
|----------|---------|----------|
| Python | 3.12 | Backend API, business logic, import/export |
| JavaScript (ES2022) | Native browser | Frontend SPA, UI interactions |
| SQL | PostgreSQL dialect | Schema, queries, migrations |
| HTML5 / CSS3 | — | Frontend structure and styling |
| Bash | — | Deployment, backup, and migration scripts |

### Frameworks & Libraries — Backend
| Library | Version | Purpose |
|---------|---------|---------|
| FastAPI | 0.110+ | REST API framework, auto OpenAPI docs |
| asyncpg | 0.29+ | Async PostgreSQL driver |
| uvicorn | 0.27+ | ASGI server (runs FastAPI) |
| openpyxl | 3.1+ | Excel export with styling |
| pydantic | 2.x | Request validation and data models |
| python-jose | 3.3+ | JWT token generation and validation |
| passlib | 1.7+ | Password hashing (bcrypt) |
| python-multipart | — | File upload handling (import) |

### Frameworks & Libraries — Frontend
| Library | Source | Purpose |
|---------|--------|---------|
| SheetJS (xlsx) | cdnjs CDN | Excel import/export in browser |
| Inter | Google Fonts | Primary UI font |
| JetBrains Mono | Google Fonts | Monospace data display |
| Vanilla JS | Built-in | No framework — pure DOM manipulation |

### Infrastructure
| Component | Software | Version | Purpose |
|-----------|----------|---------|---------|
| Web server / Proxy | Nginx | 1.25 | Serves frontend, reverse-proxies API, HTTPS/TLS |
| Database | PostgreSQL | 16 | Primary data store |
| Container runtime | Docker + Compose | 24+ / v2.x | Production deployment |
| Backup | postgres:alpine | — | Scheduled pg_dump via cron |

### Open Source Licenses of Dependencies
| Software | License |
|----------|---------|
| FastAPI | MIT |
| PostgreSQL | PostgreSQL License (similar to MIT) |
| Nginx | 2-Clause BSD |
| Python | PSF License |
| asyncpg | Apache 2.0 |
| openpyxl | MIT |
| SheetJS Community Edition | Apache 2.0 |
| Docker Engine (CE) | Apache 2.0 |
| uvicorn | BSD |
| pydantic | MIT |

---

## System Requirements

### Docker Deployment (Recommended)
| Resource | Minimum | Recommended |
|----------|---------|-------------|
| OS | Any Linux with Docker | Ubuntu 22.04 / 24.04 LTS |
| CPU | 1 vCPU | 2 vCPU |
| RAM | 512 MB | 2 GB |
| Disk | 5 GB | 20 GB |
| Docker | 24.0+ | Latest |
| Docker Compose | v2.x | Latest |

### Bare Metal / VM Deployment
| Resource | Minimum | Recommended |
|----------|---------|-------------|
| OS | Ubuntu 20.04+ / Debian 11+ / RHEL 8+ | Ubuntu 22.04 LTS |
| CPU | 1 vCPU | 2 vCPU |
| RAM | 512 MB | 2 GB |
| Disk | 5 GB | 20 GB |
| Python | 3.10+ | 3.12 |
| PostgreSQL | 14+ | 16 |
| Nginx | 1.18+ | 1.25 |

---

## Deployment

### Option 1 — Docker (Recommended)

Simplest deployment. Everything runs in containers with no host dependencies.

#### Prerequisites
```bash
# Install Docker Engine
curl -fsSL https://get.docker.com | sh
sudo usermod -aG docker $USER && newgrp docker

# Verify
docker --version && docker compose version
```

#### Fresh Install

**Step 1 — Extract and enter directory**
```bash
unzip dc-manager-production.zip
cd dc-prod
```

**Step 2 — Configure environment**
```bash
cp .env.example .env
nano .env
```

Set these values before starting:

| Variable | What to set | How to generate |
|----------|------------|-----------------|
| `SERVER_IP` | Your server IP | — |
| `DB_PASS` | Strong password (no `@ # %`) | — |
| `JWT_SECRET` | 32+ char random string | `python3 -c "import secrets; print(secrets.token_hex(32))"` |
| `NETDATA_STREAM_API_KEY` | UUID — child nodes use this to authenticate | `uuidgen` |

> `NETDATA_STREAM_API_KEY` is only needed if you plan to add child nodes (other bare metal / VMs) to the monitoring dashboard. You can set it to any value or leave the default if using app-only deployment.

**Step 3 — Create persistent storage directories**
```bash
mkdir -p volumes/postgres
mkdir -p volumes/backups/{daily,weekly,manual}
mkdir -p volumes/netdata/{lib,cache}
```

**Step 4 — Generate SSL certificate**
```bash
# Replace with your actual server IP
./scripts/generate-certs.sh 192.168.86.130
# Creates: certs/server.crt  (certificate)
#          certs/server.key  (private key)
```

**Step 5 — Start the stack**

Choose based on your needs:

*Deploy App + Monitoring (Netdata included — recommended):*
```bash
docker compose up -d --build
```
Starts 5 containers: `dcm_postgres` · `dcm_backend` · `dcm_frontend` · `dcm_backup` · `dcm_netdata`

*Deploy App only (no Netdata monitoring):*
```bash
docker compose up -d --build db backend frontend backup
```
Starts 4 containers: `dcm_postgres` · `dcm_backend` · `dcm_frontend` · `dcm_backup`

**Step 6 — Verify everything started**
```bash
# All containers should show "Up"
docker ps

# App health check
curl -k https://localhost/api/health
# Expected: {"status":"ok"}
```

**Step 7 — Open in browser**

| URL | What |
|-----|------|
| `https://YOUR-SERVER-IP` | DC Manager Pro app |
| `http://YOUR-SERVER-IP` | Redirects to HTTPS |
| `http://YOUR-SERVER-IP:19999` | Netdata monitoring *(if deployed)* |

Default login: `admin` / `Admin@123` — **change immediately** via Admin → Users.

#### Update Existing Install (no data loss)
```bash
cd /appdata/dc-prod
# Replace frontend/index.html and/or backend/main.py then:
docker compose up -d --build frontend backend
# postgres and backup containers are left untouched
# Note: certs are unchanged — only regenerate if IP changes
```

#### Full Rebuild (wipes all data)
```bash
cd /appdata/dc-prod
docker compose down --volumes
rm -rf volumes/postgres/*
docker volume prune -f
docker compose up -d --build
```

#### Useful Docker Commands
```bash
# View logs
docker logs dcm_backend  --tail 50 -f
docker logs dcm_frontend --tail 20

# Shell into containers
docker exec -it dcm_backend  bash
docker exec -it dcm_postgres psql -U dcuser -d dcmanager

# Stop / Start without destroying data
docker compose stop
docker compose start

# Resource usage
docker stats
```

---

### Option 2 — Bare Metal / VM (Ubuntu 22.04 LTS)

Use this when Docker is not available or not permitted in your environment.

#### Step 1 — Install System Dependencies
```bash
sudo apt update && sudo apt upgrade -y

# Python 3.12
sudo apt install -y software-properties-common
sudo add-apt-repository ppa:deadsnakes/ppa -y
sudo apt install -y python3.12 python3.12-venv python3.12-dev build-essential

# PostgreSQL 16
sudo apt install -y curl ca-certificates
sudo install -d /usr/share/postgresql-common/pgdg
curl -o /usr/share/postgresql-common/pgdg/apt.postgresql.org.asc \
  --fail https://www.postgresql.org/media/keys/ACCC4CF8.asc
echo "deb [signed-by=/usr/share/postgresql-common/pgdg/apt.postgresql.org.asc] \
  https://apt.postgresql.org/pub/repos/apt $(lsb_release -cs)-pgdg main" \
  | sudo tee /etc/apt/sources.list.d/pgdg.list
sudo apt update && sudo apt install -y postgresql-16

# Nginx
sudo apt install -y nginx unzip
```

#### Step 2 — Configure PostgreSQL
```bash
sudo systemctl enable --now postgresql

sudo -u postgres psql << 'EOF'
CREATE USER dcuser WITH PASSWORD 'YourStrongPassword123';
CREATE DATABASE dcmanager OWNER dcuser;
GRANT ALL PRIVILEGES ON DATABASE dcmanager TO dcuser;
\q
EOF

# Apply schema
sudo mkdir -p /opt/dc-manager
unzip dc-manager-production.zip -d /opt/dc-manager
sudo -u postgres psql -d dcmanager -f /opt/dc-manager/dc-prod/backend/init.sql
```

#### Step 3 — Deploy Backend
```bash
cd /opt/dc-manager/dc-prod

# Python virtual environment
python3.12 -m venv /opt/dc-manager/venv
source /opt/dc-manager/venv/bin/activate
pip install --upgrade pip
pip install -r backend/requirements.txt

# Environment file
cat > /opt/dc-manager/dc-prod/.env << 'EOF'
DB_USER=dcuser
DB_PASS=YourStrongPassword123
DB_NAME=dcmanager
DB_HOST=localhost
DB_PORT=5432
JWT_SECRET=replace-this-with-a-32-plus-character-random-secret
TOKEN_TTL_HOURS=24
ALLOWED_ORIGINS=*
EOF

chmod 600 /opt/dc-manager/dc-prod/.env
```

#### Step 4 — Create systemd Service
```bash
sudo tee /etc/systemd/system/dc-manager.service << 'EOF'
[Unit]
Description=DC Manager Pro — Backend API
After=network.target postgresql.service
Requires=postgresql.service

[Service]
Type=simple
User=www-data
WorkingDirectory=/opt/dc-manager/dc-prod/backend
Environment=PATH=/opt/dc-manager/venv/bin
EnvironmentFile=/opt/dc-manager/dc-prod/.env
ExecStart=/opt/dc-manager/venv/bin/uvicorn main:app \
  --host 127.0.0.1 \
  --port 8000 \
  --workers 2 \
  --log-level info
Restart=always
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF

sudo systemctl daemon-reload
sudo systemctl enable --now dc-manager

# Verify
sudo systemctl status dc-manager
curl http://127.0.0.1:8000/api/health
```

#### Step 5 — Configure Nginx
```bash
# Deploy frontend
sudo mkdir -p /var/www/dc-manager
sudo cp /opt/dc-manager/dc-prod/frontend/index.html /var/www/dc-manager/

# Nginx site config
sudo tee /etc/nginx/sites-available/dc-manager << 'EOF'
server {
    listen 80;
    server_name _;

    root /var/www/dc-manager;
    index index.html;

    # API — reverse proxy to FastAPI
    location /api/ {
        proxy_pass         http://127.0.0.1:8000;
        proxy_set_header   Host              $host;
        proxy_set_header   X-Real-IP         $remote_addr;
        proxy_set_header   X-Forwarded-For   $proxy_add_x_forwarded_for;
        proxy_read_timeout 300s;
        client_max_body_size 50M;
    }

    # SPA — serve index.html for all routes
    location / {
        try_files $uri $uri/ /index.html;
    }

    # Compression
    gzip on;
    gzip_types text/html text/css application/javascript application/json;
}
EOF

sudo ln -sf /etc/nginx/sites-available/dc-manager /etc/nginx/sites-enabled/
sudo nginx -t && sudo systemctl reload nginx
sudo systemctl enable nginx

# Open firewall port
sudo ufw allow 80/tcp

# Open browser: http://YOUR-SERVER-IP
```

#### Step 5b — Configure Nginx with HTTPS (self-signed)
```bash
# Generate self-signed cert
sudo mkdir -p /etc/nginx/certs
sudo openssl req -x509 -nodes -days 3650 -newkey rsa:2048 \
  -keyout /etc/nginx/certs/server.key \
  -out    /etc/nginx/certs/server.crt \
  -subj "/CN=YOUR-SERVER-IP"

sudo tee /etc/nginx/sites-available/dc-manager << 'EOF'
server {
    listen 80;
    server_name _;
    return 301 https://$host$request_uri;
}
server {
    listen 443 ssl;
    server_name _;

    ssl_certificate     /etc/nginx/certs/server.crt;
    ssl_certificate_key /etc/nginx/certs/server.key;
    ssl_protocols       TLSv1.2 TLSv1.3;

    root /var/www/dc-manager;
    index index.html;

    location /api/ {
        proxy_pass http://127.0.0.1:8000;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_read_timeout 300s;
        client_max_body_size 50M;
    }

    location / {
        try_files $uri $uri/ /index.html;
    }

    gzip on;
    gzip_types text/html text/css application/javascript application/json;
}
EOF

sudo nginx -t && sudo systemctl reload nginx
sudo ufw allow 443/tcp
```

#### Step 6 — Verify
```bash
sudo systemctl status postgresql dc-manager nginx
curl http://localhost/api/health
# Expected: {"status":"ok"}
# Open: http://YOUR-SERVER-IP  (or https:// if HTTPS configured)
# Login: admin / Admin@123
```

#### Bare Metal — Updating Files
```bash
# Backend
sudo cp /path/to/new/main.py /opt/dc-manager/dc-prod/backend/main.py
sudo systemctl restart dc-manager

# Frontend (no restart needed)
sudo cp /path/to/new/index.html /var/www/dc-manager/index.html
```

#### Bare Metal — Automated Backups
```bash
sudo mkdir -p /opt/dc-manager/backups/{daily,weekly,manual}

sudo tee /opt/dc-manager/backup.sh << 'EOF'
#!/bin/bash
DATE=$(date +%Y%m%d_%H%M%S)
PGPASSWORD=YourStrongPassword123 pg_dump -U dcuser -h localhost dcmanager \
  | gzip > /opt/dc-manager/backups/daily/dcmanager_${DATE}.sql.gz
# Retain 30 days
find /opt/dc-manager/backups/daily -name "*.sql.gz" -mtime +30 -delete
EOF

sudo chmod +x /opt/dc-manager/backup.sh

# Schedule: daily at 2 AM
(crontab -l 2>/dev/null; echo "0 2 * * * /opt/dc-manager/backup.sh") | crontab -
```

---

### Option 3 — RHEL / Rocky Linux / AlmaLinux

Same flow as Ubuntu with these differences:

```bash
# Install dependencies
sudo dnf install -y python3.12 python3.12-devel gcc postgresql16-server postgresql16 nginx

# Initialise PostgreSQL (RHEL-specific step)
sudo postgresql-setup --initdb
sudo systemctl enable --now postgresql

# pg_hba.conf — allow password auth (edit if needed)
sudo nano /var/lib/pgsql/16/data/pg_hba.conf
# Change 'ident' to 'md5' for local connections, then:
sudo systemctl restart postgresql

# Continue from Step 2 (Configure PostgreSQL) above
# Firewall uses firewalld instead of ufw:
sudo firewall-cmd --permanent --add-port=80/tcp
sudo firewall-cmd --permanent --add-port=443/tcp
sudo firewall-cmd --reload

# SELinux — allow Nginx to connect to backend
sudo setsebool -P httpd_can_network_connect 1
```

---

## HTTPS / SSL Setup

DC Manager Pro runs on HTTPS by default (Docker). HTTP on port 80 automatically redirects to HTTPS on port 443.

### Docker — HTTPS Setup

```bash
# Generate self-signed certificate (valid 10 years)
cd /appdata/dc-prod
./scripts/generate-certs.sh 192.168.86.130   # ← your server IP

# Output:
# certs/server.crt  ← certificate (public)
# certs/server.key  ← private key  (keep secret)

# Deploy
docker compose up -d --build

# Access
https://YOUR-SERVER-IP      # main app
http://YOUR-SERVER-IP       # auto-redirects to HTTPS
```

Your browser will show a security warning because the certificate is self-signed. This is expected for internal tools.

**Chrome/Edge:** Click **Advanced** → **Proceed to YOUR-IP (unsafe)**  
**Firefox:** Click **Advanced** → **Accept the Risk and Continue**

### Suppress the Browser Warning (Optional)

**Windows:**
```
1. Open certs/server.crt
2. Click "Install Certificate"
3. Select "Local Machine" → "Place all certificates in the following store"
4. Browse → "Trusted Root Certification Authorities"
5. Finish → restart browser
```

**macOS:**
```bash
sudo security add-trusted-cert -d -r trustRoot \
  -k /Library/Keychains/System.keychain certs/server.crt
# Restart browser
```

**Linux (Chrome/Edge):**
```bash
sudo cp certs/server.crt /usr/local/share/ca-certificates/dc-manager.crt
sudo update-ca-certificates
# Restart browser
```

**Linux (Firefox):** Go to **Settings → Privacy & Security → Certificates → View Certificates → Authorities → Import** → select `server.crt` → trust for websites.

### Renewing the Certificate
```bash
cd /appdata/dc-prod
./scripts/generate-certs.sh 192.168.86.130
docker compose restart frontend
```

### Using Your Own Certificate (.crt + .key)
```bash
cp your-cert.crt /appdata/dc-prod/certs/server.crt
cp your-cert.key /appdata/dc-prod/certs/server.key
chmod 600 /appdata/dc-prod/certs/server.key
docker compose restart frontend
```

---

## Default Credentials

| Username | Password   | Role       | Access |
|----------|------------|------------|--------|
| admin    | Admin@123  | Superuser  | Full access |

> ⚠ **Change the default password immediately after first login via Admin → Users.**

---

## Directory Structure

```
dc-prod/
├── backend/
│   ├── Dockerfile
│   ├── main.py                       ← FastAPI app — all API routes and business logic
│   ├── init.sql                      ← PostgreSQL schema + default admin user
│   └── requirements.txt
├── frontend/
│   ├── Dockerfile
│   └── index.html                    ← Full SPA (HTML + CSS + JS — single file)
├── nginx/
│   └── nginx.conf                    ← HTTPS, TLS 1.2/1.3, HTTP→HTTPS redirect
├── certs/                            ← SSL certificates (generated by script)
│   ├── server.crt                    ← Certificate — public, install on browsers
│   └── server.key                    ← Private key — keep secret, never commit
├── monitoring/                       ← Netdata configuration
│   ├── netdata.conf                  ← Parent node config (history, streaming accept, web access)
│   ├── stream.conf                   ← Child node template (parent IP, API key)
│   ├── netdata-child.conf            ← Reference config for manual child installs
│   └── health_alarm_notify.conf      ← Alert notification settings (email/Slack)
├── scripts/
│   ├── generate-certs.sh                ← Generate self-signed SSL certificate
│   ├── entrypoint-backup.sh             ← Backup container cron entrypoint
│   ├── manual-backup.sh                 ← Trigger a manual database backup
│   ├── restore.sh                       ← Restore database from backup file
│   ├── export-offline.sh                ← Bundle app + images for air-gapped server
│   ├── import-offline.sh                ← Install bundle on air-gapped server
│   ├── netdata-entrypoint.sh            ← Writes stream.conf with real API key at startup
│   ├── migrate-volumes.sh               ← DB migration: named → local volumes
│   ├── migrate-server-types.sql         ← DB migration: add new server_type options
│   ├── migrate-add-zone.sql             ← DB migration: add zone column to racks
│   ├── migrate-audit-v2.sql             ← DB migration: stock + connectivity audit trail
│   ├── save-netdata-offline.sh          ← Save parent Netdata image for air-gapped VM
│   ├── load-netdata-offline.sh          ← Load parent Netdata image on air-gapped VM
│   ├── save-netdata-child-offline.sh    ← Package Netdata for air-gapped child nodes
│   ├── install-netdata-child-systemd.sh ← Install Netdata child as native systemd service
│   └── install-netdata-child-docker.sh  ← Install Netdata child as Docker container
├── volumes/                          ← ALL persistent data — back this up!
│   ├── postgres/                     ← PostgreSQL data files
│   ├── netdata/                      ← Netdata metric history and cache
│   │   ├── config/                   ← Netdata runtime config (auto-generated)
│   │   ├── lib/                      ← Metric history database
│   │   └── cache/                    ← Working cache (safe to clear)
│   └── backups/
│       ├── daily/                    ← Auto daily backups (30 day retention)
│       ├── weekly/                   ← Auto weekly backups (12 week retention)
│       └── manual/                   ← Manual backups
├── docker-compose.yml                ← 5 services: postgres, backend, frontend, backup, netdata
├── .env.example                      ← Environment variable template
└── README.md
```

---

## Roles & Permissions

| Action | Superuser | Admin | User |
|--------|-----------|-------|------|
| View Assets / Racks / Stock | ✓ | ✓ | ✓ |
| View Audit Log & History | ✓ | ✓ | ✗ |
| View Stock History | ✓ | ✓ | ✓ |
| Add / Edit / Delete Assets | ✓ | ✓ | ✗ |
| Add / Edit Racks | ✓ | ✓ | ✗ |
| Delete Racks | ✓ | ✗ | ✗ |
| Stock Transactions (Txn button) | ✓ | ✓ | ✗ |
| Allocate Parts to Assets | ✓ | ✓ | ✗ |
| Add / Edit Connectivity | ✓ | ✓ | ✗ |
| Export to Excel | ✓ | ✓ | ✓ |
| Import from Excel | ✓ | ✓ | ✗ |
| User Management | ✓ | ✗ | ✗ |
| Field Manager (add/edit fields) | ✓ | ✗ | ✗ |
| Logo Settings (upload/remove) | ✓ | ✗ | ✗ |

---

## Usage Guide

### 🔐 Login & Session

Open `https://YOUR-SERVER-IP` in your browser. Accept the self-signed certificate warning.

| Role | Can do |
|------|--------|
| **Superuser** | Everything — users, permissions, all data, audit log |
| **Admin** | Add/edit/delete assets, racks, stock, connectivity |
| **Viewer** | Read-only — view and export everything |

**Default login:** `admin` / `Admin@123` — change immediately after first login via **Admin → Users**.

Sessions auto-expire after **10 minutes of inactivity**. A warning banner counts down the last 60 seconds. Click **Stay Logged In** to reset.

---

### ◈ Dashboard

Home screen — datacenter health at a glance.

**KPI cards** (top row) are clickable — tap any to jump to that section:

| Card | Goes to |
|------|---------|
| Total Assets | All Assets |
| Servers | All Assets |
| Racks | Rack View |
| Connections | Connectivity |
| Stock SKUs | Stock / Parts |
| Low Stock | Stock / Parts (items ≤ 5 units) |

Below the cards: **Assets by Type** bar chart, **Stock Summary** with fill bars, **Recent Assets** (last 8 modified), and **Recent Activity** (last 8 changes across all assets — visible to Admin/Superuser).

---

### ◻ All Assets

Full inventory table for every physical and virtual asset.

**Toolbar:**
```
[ 🔍 Search hostname/IP/serial/rack ] [ All Types ▾ ] [ All Status ▾ ] [ 50/pg ▾ ] [ ⊞ Cols ] [ + Add ]
```

**Table capabilities:**
- Real-time search across hostname, IP, serial number, rack ID
- Sort any column — click header, click again to reverse
- Resize columns — drag the edge of any column header
- Toggle visible columns — click **⊞ Cols** button
- Configurable page size — 50 / 100 / All
- Row checkboxes + select-all → bulk delete with confirmation

**Asset form tabs:**

*General* — Hostname, Asset Type, Status, Datacenter, Rack ID, U Start, U Height, Asset Tag, Serial Number, PO Number, EOL Date, App/Asset Owner, Notes

*Hardware* — Make, Model, and any custom fields defined in Field Manager

*Network* — Prov IP, BMC IP, Data IP, Backup IP, MAC, VLAN, Additional IPs
All IP fields are **clickable links** — clicking opens `https://ip` in a new tab (useful for BMC/iDRAC/iLO direct access)

*Connectivity* — Add cable connections inline while editing an asset

**Asset detail panel** — click any hostname to open:
- **Info tab** — all fields in a clean read view, IP links clickable
- **History tab** — unified timeline showing ALL changes to this asset in one place:
  - Asset changes (rack moves, status changes, field updates) in **blue/yellow/purple**
  - Parts allocated or returned (e.g. "2x Seagate HDD allocated") in **purple** tagged `PARTS`
  - Connectivity changes (cable added, switch port changed) in **orange** tagged `CABLING`
- **Topology tab** — draggable SVG network diagram showing the full cable path from this asset to its switch

---

### ▤ Rack View

Visual diagrams of every rack in your datacenters.

**Reading a rack card:**
```
R-PROD-01                              ✎  ✕
[HYN-POD-2]  [Zone-8]  [Row-15]
████████████░░░░░░░░░░░░░░  43%
───────────────────────────────────────
42 │  HYNRBBMPRUPIWAF02 / BRR8R24  │ 42
36 │  HYNRBBMPRUPIK8S01 / SN123456 │ 36
32 │  —                            │ 32  (empty)
```

- **Header line 1** — Rack ID + edit (✎) and delete (✕) buttons
- **Header line 2** — Datacenter · Zone · Row as colour chips
- **Utilisation bar** — green < 60%, amber 60–85%, red > 85%
- **Slots** — each row shows `HOSTNAME / SERIAL`, U number on both left and right
- **Colour coding** — servers with the same hostname prefix share a colour (12-colour palette)

**Toolbar:**
```
[ 🔍 Search racks ] [ Datacenter ▾ ] [ Zone ▾ ] [ Row ▾ ] [ + New Rack ] [ ↓ Export Rack ]
```

**Export Rack to Excel** produces:
- *Rack Assets* sheet — hostname, serial, BMC IP, make, model, PO number per asset
- *Full U Layout* sheet — every U including empty slots, for physical audit

Click any asset slot to open its detail panel.

---

### ◫ Stock / Parts

Spare parts inventory with full transaction tracking and asset allocation tracing.

**Per item fields:** Category, Brand, Model, Spec, Form factor, Interface, Total / Available / Allocated quantity, Location, Unit cost

**Transactions** — click **Txn** on any row to open the transaction dialog:

| Type | What happens | Asset link |
|------|-------------|------------|
| **IN** | Increase total + available | — |
| **OUT** | Decrease total + available (consume/discard) | — |
| **ALLOCATE** | Reserve quantity for a specific asset | **Required** — type asset hostname |
| **RETURN** | Return allocated quantity back to available | Optional — asset hostname |
| **ADJUST** | Set absolute quantity (stock count correction) | — |

When you select **ALLOCATE** or **RETURN**, an **Asset Hostname** field appears with autocomplete from all known assets. This links the transaction to the asset — the parts movement appears in that asset's History tab automatically.

**History button** — every stock row has a **History** button (visible to all roles). Opens a popup showing:
- All transactions (IN/OUT/ALLOCATE/RETURN/ADJUST) with quantities and timestamps
- Which assets parts were allocated to
- Create/edit/delete events from the audit log
- Summary: total transactions and all assets that received parts from this item

Items with ≤ 5 available units are flagged as **Low Stock** in the sidebar and dashboard.

---

### ⇄ Connectivity

Full physical cable path tracking from server to switch.

**Path model:**
```
Server (hostname / port)
  → LIU-A (rack / hostname / port)
    → LIU-B (rack / hostname / port)   [optional pass-through]
      → Switch (hostname / port)
```

**Per record:** Cable type (Fiber SM, Fiber MM, DAC, Copper), Speed (1G/10G/25G/40G/100G), VLAN, Purpose

**Table capabilities:**
- Sort by Server, Port, Switch, Cable, Speed, VLAN, Purpose (click header)
- Resize columns
- Filter by cable type and speed using dropdowns
- Select-all checkboxes + bulk delete
- Column chooser — toggle LIU-B column

**Topology diagram** — open any asset → Topology tab to see a draggable visual map of its full cable path.

**Connectivity audit trail** — every connectivity change is automatically logged:
- **Link Added** — full path recorded (server → LIU → switch, cable type, speed)
- **Link Changed** — specific changes detected (switch hostname, port number, speed, VLAN, LIU)
- **Link Removed** — full path of the removed connection recorded

These events appear in the **global Audit Log** (filter by Entity: Connectivity) and in the **asset History tab** of the server involved.

---

### ↓ Export / Import

**Export** (top-right button on Assets/Stock/Connectivity pages):
Downloads a full `.xlsx` workbook with sheets: Assets, Racks, Stock, Connectivity — all fields included, including `rack_zone`, `rack_row`, and `alloc_qty`.

**Export Rack View** (toolbar button on Rack View page):
Downloads `.xlsx` with Rack Assets + Full U Layout sheets. Respects active DC/Zone/Row filters.

**Import** (top-right button → choose file):
Upload a filled `.xlsx` and select sheet type.

Import result shows three counters:
```
✓ 47 imported    ⊘ 3 skipped (already exist)    ✕ 1 error (slot conflict / bad data)
```

Rules per sheet:

| Sheet | Skip condition | Duplicate check |
|-------|---------------|-----------------|
| **Assets** | Hostname already exists → skipped (not overwritten) | `hostname` |
| **Stock** | Same brand + model already exists → skipped | `brand + model` |
| **Connectivity** | Same server + port label already exists → skipped | `src_hostname + src_port_label` |
| **Racks** | Always upsert — safe to re-import | `rack_id` (ON CONFLICT UPDATE) |

Additional rules:
- Row 1 must be the header row — do not modify column names
- IDs are auto-generated — leave any `id` column blank
- Asset slot conflicts → row counted as error (hard fail, no overwrite)
- `rack_zone` / `rack_row` values auto-create rack records if they don't exist
- All imported records are written to the audit log with the importing user's name
- A server can have **multiple connectivity rows** — each is identified by its unique `src_port_label` (e.g. `slot1port1`, `slot2port1`)

**Templates** — download blank template workbooks from the Import dialog.

---

### ⚙ Field Manager *(Superuser only)*

Add custom hardware fields to asset forms without touching any code.

Navigate to **Admin → Field Manager**:
- **Add Field** — choose type: Text, Number, Date, or Select (with options list)
- **Edit** any field — change label, placeholder, options, or required flag
- Dropdown fields with "Other" option automatically show a free-text box when selected
- System fields (Make, Model, Serial, etc.) can have their labels edited but not deleted
- Changes apply immediately to all asset forms

---

### 🔒 Permissions *(Superuser only)*

Navigate to **Admin → Permissions** to see the full permission matrix for each role.
Roles are fixed (Superuser / Admin / Viewer) — permissions are not individually customisable.

---

### 👤 Users *(Superuser only)*

Navigate to **Admin → Users**:
- Create new users with username, password, and role
- Edit existing users — change name, password, role
- Delete users (cannot delete your own account)
- Password is stored as bcrypt hash — not recoverable, only resettable

---

### 📋 Audit Log *(Admin + Superuser)*

Navigate via **Audit Log** in the sidebar (Admin section).

The filter bar has five controls — all clearly readable:
- **Search** — free-text search across detail and entity ID
- **Action** — grouped dropdown: Asset / Stock-Parts / Connectivity / Rack
- **Entity Type** — filter by what changed (Asset, Stock, Connectivity, Rack)
- **User** — filter by who made the change
- **Since Date** — show only changes from a specific date onwards
- **Clear Filters** button resets all filters at once

Active filters are shown as readable chips below the bar (e.g. `action: Asset Created`).

Click **↓ Export CSV** to download all matching records as a spreadsheet.

---

### ⚡ Recent Activity *(Admin + Superuser)*

Two ways to reach recent activity quickly:

1. **Dashboard** — the **Recent Activity** card (bottom-right) shows the last 8 changes. Click **📋 View All →** in the card header to open the full Audit Log.
2. **Sidebar** — click **⚡ Recent Activity** in the Admin section to jump to the Dashboard and scroll to the activity card instantly.

---

### 🖼 Logo Settings *(Superuser only)*

Navigate to **Admin → Logo Settings** in the sidebar.

Upload a custom logo to replace the default server rack icon across the entire application:

| Location | What changes |
|----------|-------------|
| Browser tab | Favicon updates immediately |
| Sidebar top-left | Custom image replaces default rack SVG |
| Login page | Custom image replaces the large rack logo |

**Upload:** Click the dashed upload zone → pick a file (PNG, JPG, SVG, WebP, max 1 MB). The logo updates instantly everywhere.

**Remove:** Click **✕ Remove Custom Logo** to restore the default rack SVG across all locations.

The logo is stored in the browser's `localStorage` — it persists across sessions without any database or backend change. Each machine/browser needs the logo set once by a Superuser.

> **Note:** Admin and Viewer roles cannot see or access Logo Settings. The sidebar item is hidden for non-Superuser roles.

---

### ◑ Light / Dark Mode

Click the **◑** button in the sidebar footer to toggle between:
- **Dark mode** (default) — glassmorphism zinc/slate palette with ambient gradients
- **Light mode** — cool slate-blue tinted theme

Preference is saved in the browser and persists across sessions.

---

## Features Reference

### Assets
- Full CRUD with tabbed form: General / Hardware / Network / Connectivity
- **General fields:** Hostname, Type, Status, Datacenter, Rack ID, U Position, Asset Tag, Serial Number, PO Number, EOL Date, App/Asset Owner, Notes
- **Network fields:** Prov IP, BMC IP (clickable → opens https://ip), Data IP, Backup IP, MAC, VLAN, Additional IPs
- **Hardware fields:** Fully configurable via Field Manager
- **Unified History tab:** Single timeline showing asset changes + parts movements + connectivity changes — all in one view
- **Slot conflict protection:** Warns on save if U position occupied; hard-fails on import
- **Topology tab:** Draggable SVG diagram showing full cable path to switch
- Export/Import via Excel

### Asset Table
- Resizable columns, sort any column, column chooser
- Items per page: 50 / 100 / All with pagination
- Filter by Type and Status, real-time search
- Multi-select + bulk delete with confirmation

### Asset Types
Server, VM, Switch, Router, Firewall, LIU, Patch Panel, PDU, KVM, Other

### Server Types (Hardware field)
Rack Server, Tower, Blade, Dense Server, High-Density, Virtual, VM,
Type-A through Type-F, Type-S, Type-T, Type-X through Type-Z, Other (free-text)

### Field Manager (Superuser)
- Add custom hardware fields: text, number, dropdown, textarea
- Edit labels, options, placeholder on all fields including system fields
- "Other" in dropdowns shows free-text input automatically
- Live preview of hardware form

### Rack View
- Visual rack diagrams, 3-level hierarchy: Datacenter → Zone → Row
- hostname / serial on every slot, U numbers both sides
- Hostname-prefix colour grouping (12 colours), utilisation bar (green/amber/red)
- Filter by DC/Zone/Row, search by rack ID
- Edit (✎) and delete (✕) racks, export to Excel (Rack Assets + Full U Layout)

### Stock Management
- SKU tracking with full hardware spec fields
- Transactions: IN / OUT / ALLOCATE / RETURN / ADJUST
- **ALLOCATE links parts to an asset hostname** — the allocation appears in that asset's History tab
- **History button** on every stock row — shows all transactions + which assets received parts
- All transactions logged to audit trail with user, timestamp, before/after quantities
- Low stock alert (≤ 5 units)

### Connectivity
- Full path: Server → LIU-A → LIU-B → Switch with cable/speed/VLAN/purpose
- Resizable columns, sort, filter by cable type and speed, bulk delete
- Every change logged to audit trail — switch moves, port changes, speed changes all detected

### Unified History & Audit Trail

**Per-Asset History tab** shows a single colour-coded timeline:

| Event type | Colour | Tag | Examples |
|-----------|--------|-----|---------|
| Asset created/updated/relocated | Green/Blue/Yellow | — | Rack move, status change, field edit |
| Part allocated to this asset | Purple | `PARTS` | "Allocated 2x Seagate 4TB → prod-server-01" |
| Part returned from this asset | Amber | `PARTS` | "Returned 1x Kingston 32GB RAM" |
| Connectivity link added | Orange | `CABLING` | "Connected eth0 → SW-CORE-01 Gi1/0/1" |
| Connectivity link changed | Orange | `CABLING` | "Switch: SW-01 → SW-04 \| Port: Gi1/0/1 → Gi1/0/5" |
| Connectivity link removed | Red | `CABLING` | "Removed: prod-server-01 → SW-CORE-01" |

**Global Audit Log** (Admin + Superuser) — navigate via **Audit Log** in the sidebar, or the **📋 View All →** button on the Dashboard Recent Activity card:
- Filter bar with properly sized controls — all filters clearly visible and readable
- **Action** filter — grouped by category: Asset / Stock-Parts / Connectivity / Rack
- **Entity Type** filter — Asset, Stock/Parts, Connectivity, Rack
- **User** filter — filter by who made the change
- **Since Date** filter — show changes from a specific date
- **Search** — searches detail text and entity IDs
- Active filters shown as readable chips (e.g. `action: Asset Created`, not raw `ASSET_CREATED`)
- Export to CSV (respects all active filters)
- Paginated: 25 / 50 / 100 / 200 per page

**Stock History modal** (all roles) — click **History** on any stock row:
- All transactions in reverse chronological order
- Which assets parts were allocated to
- Summary of all assets that received parts from this item

### API — New Endpoints

| Endpoint | Method | Description |
|----------|--------|-------------|
| `/api/assets/{id}/full-history` | GET | Unified timeline: asset + parts + connectivity events |
| `/api/stock/{id}/history` | GET | Stock audit log + transaction records merged |
| `/api/connectivity/{id}/history` | GET | Change log for one connectivity record |

### Session Security
- Auto-logout after 10 minutes of inactivity
- 60-second warning banner with "Stay Logged In" button
- Activity tracked: mouse, keyboard, scroll, touch

### UI
- Glassmorphism dark mode (default) — frosted glass panels, zinc/slate palette
- Light mode — cool slate-blue tinted theme
- Clickable KPI dashboard cards
- **Recent Activity widget** on Dashboard (Admin/Superuser) — last 8 changes, **📋 View All →** button in card header
- **Sidebar quick links** for Admin/Superuser: 📋 Audit Log · ⚡ Recent Activity (scrolls to dashboard widget)
- Toast notifications, modal forms, column chooser
- All filter controls use consistent 36px height with 12px font — fully readable in dark theme

### Logo & Branding
- Server rack SVG logo embedded as browser tab favicon — works air-gapped, no external files
- Logo in sidebar top-left — click to go to Dashboard
- **Logo Settings** (Superuser only) — available in Admin sidebar section
  - Upload custom logo (PNG, JPG, SVG, WebP — max 1 MB)
  - Preview current logo before applying
  - Remove custom logo and restore default with one click
  - Custom logo appears in: browser tab favicon, sidebar, login page
  - Stored in browser localStorage — persists across sessions without any backend change
  - Three-layer guard: only Superuser can open settings, upload, or remove

---


## Netdata Usage Guide

### What Netdata Monitors

When Netdata runs alongside DC Manager, it monitors:

| Source | What you see |
|--------|-------------|
| **Host machine** | CPU per-core, RAM, swap, disk I/O, disk space, network per interface |
| **dcm_postgres** | Container CPU/RAM, plus: queries/sec, connections, cache hit ratio, locks |
| **dcm_backend** | Container CPU/RAM/network/disk I/O |
| **dcm_frontend** | Container CPU/RAM/network |
| **dcm_backup** | Container CPU/RAM |
| **Child nodes** | All of the above for every enrolled bare metal / VM |
| **Alerts** | Auto-fires when: CPU > 85%, RAM > 90%, disk > 85%, container restarts, postgres connection spike |

---

### Opening the Dashboard

```
http://YOUR-SERVER-IP:19999
```

No login required — access is restricted to internal network IPs by default (`monitoring/netdata.conf`).

**Switching between machines:**
Use the **host dropdown** in the top-right corner to switch between the DC Manager VM and any enrolled child nodes.

---

### Dashboard Sections

| Sidebar section | What it shows |
|----------------|---------------|
| **System Overview** | High-level CPU / RAM / disk / network summary |
| **CPU** | Per-core utilisation, frequency, softirq, steal time |
| **Memory** | RAM used/cached/free, swap, page faults |
| **Disks** | Per-disk read/write throughput and latency |
| **Mount Points** | Disk space usage per filesystem |
| **Network Interfaces** | Bandwidth in/out, packets, errors per NIC |
| **Processes** | Running count, forks, memory per process group |
| **Docker** (cgroups) | Per-container CPU/RAM/network/IO |
| **Postgres** | Queries/sec, connections, cache hit, locks, rows |

---

### Built-in Alerts

Netdata fires alerts automatically — no setup required. The **bell icon** (top toolbar) shows active alerts.

| Alert | Condition | Action |
|-------|-----------|--------|
| High CPU | > 85% for 5 min | Check `docker stats` for runaway container |
| Low RAM | < 10% free | Check container memory limits or add RAM |
| Disk full | > 85% used | Clean `volumes/backups/` old backup files |
| PostgreSQL connections | > 80% of max_connections | Check for connection leaks |
| Container restart | Any container restarts | Check `docker logs CONTAINER_NAME` |

---

### Enabling Alert Notifications

Edit `monitoring/health_alarm_notify.conf`, then restart Netdata:

```bash
# Email (needs postfix on host):
SEND_EMAIL="YES"
DEFAULT_RECIPIENT_EMAIL="ops@yourcompany.com"

# Slack:
SEND_SLACK="YES"
SLACK_WEBHOOK_URL="https://hooks.slack.com/services/YOUR/WEBHOOK/URL"
DEFAULT_RECIPIENT_SLACK="#dc-manager-alerts"

# Apply:
docker restart dcm_netdata
```

---

### Increasing Data Retention

Default: 24 hours of per-second data. Edit `monitoring/netdata.conf`:

```ini
[global]
    dbengine disk space = 4096   # 4GB ≈ several days for a small cluster
```

Then: `docker restart dcm_netdata`

---

### Useful Commands

```bash
# Check Netdata is running
docker ps | grep dcm_netdata

# Live logs (look for errors or connection messages)
docker logs dcm_netdata -f

# Restart after config change
docker restart dcm_netdata

# Check if a child node connected
docker logs dcm_netdata 2>&1 | grep -i "connected\|streaming\|child-name"
```


## Database Migrations (Existing Installs)

Run these when upgrading an existing install — all scripts are safe to run on live data, no data is lost.

### Latest — v3.1.0 (audit trail for stock & connectivity)

**Run this if upgrading from any version before v3.1.0:**

```bash
# Docker:
docker cp scripts/migrate-audit-v2.sql dcm_postgres:/tmp/
docker exec dcm_postgres psql -U dcuser -d dcmanager -f /tmp/migrate-audit-v2.sql

# Bare metal:
PGPASSWORD=YourPassword psql -U dcuser -d dcmanager -f scripts/migrate-audit-v2.sql
```

Adds:
- `audit_log.related_entity` and `related_entity_id` — links stock/connectivity events to assets
- `stock_transactions.allocated_to` — records which asset a part was allocated to
- `stock_transactions.username` — records who made the transaction

### Previous migrations

```bash
# Docker:
docker cp scripts/migrate-add-zone.sql     dcm_postgres:/tmp/
docker cp scripts/migrate-server-types.sql dcm_postgres:/tmp/
docker exec dcm_postgres psql -U dcuser -d dcmanager -f /tmp/migrate-add-zone.sql
docker exec dcm_postgres psql -U dcuser -d dcmanager -f /tmp/migrate-server-types.sql

# Bare metal:
PGPASSWORD=YourPassword psql -U dcuser -d dcmanager -f scripts/migrate-add-zone.sql
PGPASSWORD=YourPassword psql -U dcuser -d dcmanager -f scripts/migrate-server-types.sql
```

---

## Backup & Restore

### Docker
```bash
# Manual backup
./scripts/manual-backup.sh
# Output: volumes/backups/manual/dcmanager_manual_YYYYMMDD_HHMMSS.sql.gz

# Restore
./scripts/restore.sh volumes/backups/daily/dcmanager_2026-03-09_020001.sql.gz

# Auto backups run automatically inside the backup container:
# Daily  02:00 AM → volumes/backups/daily/   (30 day retention)
# Weekly Sunday 03:00 → volumes/backups/weekly/ (12 week retention)
```

**Backup integration:** Point your backup solution to `./volumes/` to capture all data.

### Bare Metal
```bash
# Manual backup
PGPASSWORD=YourPassword pg_dump -U dcuser -h localhost dcmanager \
  | gzip > /opt/dc-manager/backups/manual/dcmanager_$(date +%Y%m%d_%H%M%S).sql.gz

# Restore
gunzip -c /opt/dc-manager/backups/daily/dcmanager_20260312_020001.sql.gz \
  | PGPASSWORD=YourPassword psql -U dcuser -h localhost dcmanager
```

---

## Offline / Air-Gapped Deployment

```bash
# On internet-connected server — create self-contained bundle
./scripts/export-offline.sh

# Transfer to offline server
scp dc-manager-offline-*.tar user@offline-server:/opt/

# On offline server — install from bundle
cd /opt && tar -xf dc-manager-offline-*.tar
./import-offline.sh
```

---

## API

Interactive docs: `https://your-server/api/docs`

| Endpoint | Method | Auth | Description |
|----------|--------|------|-------------|
| `/api/auth/login` | POST | None | Login → JWT |
| `/api/auth/me` | GET | Any | Current user |
| `/api/stats` | GET | Any | Dashboard stats |
| `/api/assets` | GET/POST | Any/Write | List/create assets |
| `/api/assets/{id}` | GET/PUT/DELETE | Any/Write | Asset CRUD |
| `/api/assets/{id}/history` | GET | Any | Asset audit trail (asset events only) |
| `/api/assets/{id}/full-history` | GET | Any | Unified timeline: asset + parts + connectivity |
| `/api/stock/{id}/history` | GET | Any | Stock audit log + all transaction records |
| `/api/connectivity/{id}/history` | GET | Any | Change log for one connectivity record |
| `/api/assets/check-slot` | GET | Any | Check rack+U occupancy |
| `/api/racks` | GET/POST | Any/Write | List/create racks |
| `/api/racks/{id}` | PUT | Write | Edit rack |
| `/api/racks/{id}` | DELETE | Superuser | Delete rack (must be empty) |
| `/api/stock` | GET/POST/PUT/DELETE | Any/Write | Stock CRUD |
| `/api/stock/transaction` | POST | Write | Stock transaction |
| `/api/connectivity` | GET/POST/PUT/DELETE | Any/Write | Connectivity CRUD |
| `/api/users` | GET/POST/PUT/DELETE | Superuser | User management |
| `/api/hw-fields` | GET/POST/PUT/DELETE | Super/Any | Field management |
| `/api/export/excel` | GET | Any | Export all data |
| `/api/import/excel?sheet=X` | POST | Write | Bulk import |
| `/api/audit` | GET | Superuser | Full audit log |
| `/api/health` | GET | None | Health check |

---

## Environment Variables (.env)

```env
SERVER_IP=192.168.86.130  # Your server IP (used by generate-certs.sh)
DB_USER=dcuser            # PostgreSQL username
DB_PASS=changeme123       # Password — no @ # % special chars
DB_NAME=dcmanager         # Database name
DB_HOST=postgres          # Use 'localhost' for bare metal
DB_EXTERNAL_PORT=5432     # PostgreSQL external port (Docker only)
JWT_SECRET=<32+ chars>    # Long random string for JWT signing
TOKEN_TTL_HOURS=24        # Session lifetime in hours
ALLOWED_ORIGINS=*         # CORS — use * for internal tools
```

---



## Monitoring — Adding Child Nodes

The Netdata container running with DC Manager is the **parent (master) node**. You can add any number of bare metal servers, VMs, or other machines as **child nodes** — they stream their metrics to the parent and appear in the same dashboard.

### How Streaming Works

```
Child node (bare metal / VM)          Parent (DC Manager VM)
┌────────────────────────────┐        ┌──────────────────────────────┐
│  Netdata agent             │        │  dcm_netdata container       │
│  (systemd or Docker)       │──────▶ │  dashboard: :19999           │
│                            │ push   │  stores all metrics          │
│  collects host metrics     │ on     │  serves unified dashboard    │
│  every second              │ :19999 │  fires alerts for all nodes  │
└────────────────────────────┘        └──────────────────────────────┘
```

The child uses the `NETDATA_STREAM_API_KEY` from your `.env` file to authenticate. Set this key once and use it on every child.

---

### How the API Key Works

The streaming API key is a UUID that child nodes send to the parent to authenticate. The parent checks this key and either accepts or rejects the stream. This is why you get `code=403` — the key the child sends does not match what the parent is configured to accept.

**Important:** Netdata does NOT substitute shell variables (`${VAR}`) in its config files. The key must be written as a literal UUID. The `netdata-entrypoint.sh` script handles this automatically — it reads `NETDATA_STREAM_API_KEY` from the environment and writes the actual UUID into `stream.conf` before Netdata starts.

---

### Step-by-step: Set Up the API Key

**Step 1 — Generate a UUID (on your DC Manager VM):**
```bash
uuidgen
# Example output: a1b2c3d4-e5f6-7890-abcd-ef1234567890
# Note it down — you'll need it in every child install command
```

**Step 2 — Set it in `.env`:**
```bash
nano /appdata/dc-prod/.env
# Set this line:
# NETDATA_STREAM_API_KEY=a1b2c3d4-e5f6-7890-abcd-ef1234567890
```

**Step 3 — Restart Netdata to apply:**
```bash
cd /appdata/dc-prod
docker compose restart netdata

# Verify it started and loaded the key:
docker logs dcm_netdata 2>&1 | grep -i "stream\|api key\|accept" | head -10
```

**Step 4 — Verify the parent is ready to accept streams:**
```bash
# Check the generated stream.conf inside the container
docker exec dcm_netdata cat /etc/netdata/stream.conf
# You should see your actual UUID in a [UUID] section, NOT ${NETDATA_STREAM_API_KEY}
```

---

### Fixing a Running Child That Gets 403

If your child node is showing `code=403` or `remote server denied access`:

```bash
# On the child machine — check what key it's sending
cat /etc/netdata/stream.conf
# Look for: api key = <UUID>

# Compare with what the parent accepts:
docker exec dcm_netdata cat /etc/netdata/stream.conf
# The UUID in [UUID_SECTION_HEADER] must match the child's api key = line

# If they don't match — fix the child:
# Edit /etc/netdata/stream.conf on the child, update api key = to match
# Then restart the child agent:
systemctl restart netdata           # systemd child
# or:
docker restart netdata-child        # Docker child
```

---

### Option A — Enroll a Child as a systemd Service

Use when: the target machine is bare metal, has no Docker, or you want the agent to start independently of Docker.

**A1 — Machine has internet:**

```bash
# Copy installer to target
scp /appdata/dc-prod/scripts/install-netdata-child-systemd.sh user@SERVER:/tmp/

# Run on the target machine:
sudo bash /tmp/install-netdata-child-systemd.sh   --parent 192.168.86.130   --apikey a1b2c3d4-e5f6-7890-abcd-ef1234567890   --name   baremetal-01
```

**A2 — Machine has NO internet (air-gapped):**

Step 1 — On any internet machine, create the offline package:
```bash
cd /appdata/dc-prod
./scripts/save-netdata-child-offline.sh
# Output: netdata-child-offline-YYYYMMDD.tar.gz  (~80MB)
```

Step 2 — Transfer to the target:
```bash
scp netdata-child-offline-YYYYMMDD.tar.gz user@SERVER:/opt/
scp /appdata/dc-prod/scripts/install-netdata-child-systemd.sh user@SERVER:/opt/
```

Step 3 — Install on the target (no internet needed):
```bash
cd /opt
tar -xzf netdata-child-offline-YYYYMMDD.tar.gz

sudo bash /opt/install-netdata-child-systemd.sh   --parent  192.168.86.130   --apikey  a1b2c3d4-e5f6-7890-abcd-ef1234567890   --name    baremetal-01   --offline /opt/pkg/netdata-static-installer.gz.run
```

**Managing a systemd child:**
```bash
systemctl status  netdata          # status
systemctl restart netdata          # restart after config change
journalctl -u netdata -f           # live logs
journalctl -u netdata --no-pager | grep -i connected   # verify streaming
systemctl stop    netdata          # stop
```

**Removing a systemd child:**
```bash
# Step 1 — Stop and remove Netdata on the child machine
sudo systemctl stop netdata && sudo systemctl disable netdata

# If installed via kickstart (online method):
sudo /usr/libexec/netdata/netdata-uninstaller.sh --yes --env /etc/netdata/.environment

# If installed via apt:
sudo apt-get remove --purge netdata -y && sudo apt-get autoremove -y

# If installed via dnf:
sudo dnf remove netdata -y

# Step 2 — Clean up data and config on the child machine
sudo rm -rf /etc/netdata /var/lib/netdata /var/cache/netdata /var/log/netdata
sudo systemctl daemon-reload

# Step 3 — Remove the stale node from the parent dashboard
# (see: Cleaning Up Stale Nodes section below)
```

---

### Option B — Enroll a Child as a Docker Container

Use when: the target machine already runs Docker, or you prefer container-based management.

**B1 — Machine has internet:**

```bash
scp /appdata/dc-prod/scripts/install-netdata-child-docker.sh user@SERVER:/tmp/

sudo bash /tmp/install-netdata-child-docker.sh   --parent 192.168.86.130   --apikey a1b2c3d4-e5f6-7890-abcd-ef1234567890   --name   baremetal-01
```

**B2 — Machine has NO internet (air-gapped):**

Step 1 — On any internet machine, save the Docker image:
```bash
cd /appdata/dc-prod
./scripts/save-netdata-child-offline.sh --docker
# Output: netdata-image-YYYYMMDD.tar  (~200MB)
```

Step 2 — Transfer to the target:
```bash
scp netdata-image-YYYYMMDD.tar user@SERVER:/opt/
scp /appdata/dc-prod/scripts/install-netdata-child-docker.sh user@SERVER:/opt/
```

Step 3 — Install on the target (no internet needed):
```bash
sudo bash /opt/install-netdata-child-docker.sh   --parent  192.168.86.130   --apikey  a1b2c3d4-e5f6-7890-abcd-ef1234567890   --name    baremetal-01   --offline /opt/netdata-image-YYYYMMDD.tar
```

**Managing a Docker child:**
```bash
docker ps | grep netdata-child              # status
docker logs netdata-child -f               # live logs
docker logs netdata-child 2>&1 | grep -i connected   # verify streaming
docker restart netdata-child               # restart after config change
docker stop    netdata-child               # stop
docker start   netdata-child               # start
```

**Removing a Docker child:**
```bash
# Step 1 — Stop and remove the container on the child machine
docker stop netdata-child && docker rm netdata-child
docker rmi netdata/netdata:stable          # optional — frees ~200MB

# Step 2 — Remove config and data on the child machine
sudo rm -rf /etc/netdata /var/lib/netdata /var/cache/netdata

# Step 3 — Remove the stale node from the parent dashboard
# (see: Cleaning Up Stale Nodes section below)
```

---

### Cleaning Up Stale Nodes

When you remove a child node (stop the agent + delete its files), the parent keeps its
historical data and shows it as **offline/stale** in the dashboard. It does not disappear
automatically. Run these steps on the **parent (DC Manager VM)** to fully remove it.

**Step 1 — Find the node's machine GUID**

The GUID appears in the child's logs when it starts:
```
msg="MACHINE_GUID: GUID read from file..."
```
Or find it from the dashboard URL when you click on the stale node — it appears as `nodeName=` or in the node details panel.

Or list all nodes the parent knows about:
```bash
docker exec dcm_netdata netdatacli list-all-nodes 2>/dev/null | head -30
```

**Step 2 — Delete the node via Netdata API**

```bash
# Replace with the actual GUID of the node to remove
NODE_GUID="98fd31c6-183b-4a44-b978-d8ce5997b46a"

# Delete via REST API (Netdata v2.x):
curl -s -X DELETE   "http://localhost:19999/api/v2/nodes/${NODE_GUID}"

# Alternative — via netdatacli:
docker exec dcm_netdata netdatacli remove-stale-node "$NODE_GUID" 2>/dev/null
```

**Step 3 — Verify it's gone**

Refresh the dashboard (`http://YOUR-SERVER-IP:19999`) and check the host dropdown — the node should no longer appear.

If it still shows, restart Netdata:
```bash
docker restart dcm_netdata
```

**Step 4 — If node still persists (full database reset)**

Only do this if the node won't go away after the above steps. This clears ALL historical
data for ALL nodes and lets Netdata rebuild from scratch:

```bash
# Stop Netdata
docker stop dcm_netdata

# Remove the metric databases (data is lost — history will restart from zero)
rm -f /appdata/dc-prod/volumes/netdata/lib/*.db
rm -f /appdata/dc-prod/volumes/netdata/cache/*.db 2>/dev/null || true

# Start again — Netdata rebuilds empty databases
docker start dcm_netdata

# Connected child nodes will automatically re-appear within 30 seconds
# as they reconnect and stream fresh data
```


### Verify a Child is Streaming

After installing any child, within 30 seconds:

```bash
# On the parent — check it received the connection
docker logs dcm_netdata 2>&1 | grep -i "baremetal-01\|connected\|streaming" | tail -5

# On the child (systemd)
journalctl -u netdata --no-pager | grep -i connected | tail -3

# On the child (Docker)
docker logs netdata-child 2>&1 | grep -i connected | tail -3
```

Then open `http://192.168.86.130:19999` — the new node appears in the **host dropdown** (top-right corner).

---

### Adding More Nodes

Repeat the same steps for every machine. Change only `--name` per node. The parent requires no restart.

```bash
# Third machine — systemd, online:
sudo bash /tmp/install-netdata-child-systemd.sh   --parent 192.168.86.130 --apikey YOUR-KEY --name storage-01

# Third machine — Docker, air-gapped:
sudo bash /opt/install-netdata-child-docker.sh   --parent 192.168.86.130 --apikey YOUR-KEY --name storage-01   --offline /opt/netdata-image-YYYYMMDD.tar
```

---

### Monitoring Scripts Reference

| Script | Run on | Creates |
|--------|--------|---------|
| `scripts/save-netdata-offline.sh` | Internet machine | Parent Docker image tar (for air-gapped DC Manager VM) |
| `scripts/load-netdata-offline.sh` | DC Manager VM | Loads parent image and starts |
| `scripts/save-netdata-child-offline.sh` | Internet machine | systemd static installer package |
| `scripts/save-netdata-child-offline.sh --docker` | Internet machine | Docker image tar for child nodes |
| `scripts/save-netdata-child-offline.sh --both` | Internet machine | Both packages in one run |
| `scripts/install-netdata-child-systemd.sh` | Child node | Installs + configures systemd child |
| `scripts/install-netdata-child-docker.sh` | Child node | Installs + configures Docker child |


## Changelog

### v3.1.2 (2026-03-19)
- New: **Logo Settings** (Superuser only) — Admin sidebar item to upload/preview/remove custom logo
- New: Custom logo applies to browser tab favicon, sidebar, and login page simultaneously
- New: Logo stored in `localStorage` — persists across sessions without backend changes
- New: **Remove** button in Logo Settings modal to restore default rack SVG in one click
- Changed: Sidebar logo click now navigates to Dashboard (was: triggered upload)
- Changed: Logo upload/remove restricted to Superuser role — three-layer guard on all functions
- Fixed: Audit log filter controls — `height:28px` replaced with `height:36px`, selects now use `fi_s` class for consistent dark theme styling
- Fixed: Action/Entity filter chips showed raw values (`ASSET_CREATED`) — now show readable labels (`Asset Created`)
- Fixed: Entity column in audit table — now colour-coded readable labels (Asset/Stock/Cable/Rack) instead of raw strings
- Fixed: Connectivity import skipped second connection for same server — duplicate check now uses `src_port_label` not `src_port`

### v3.1.1 (2026-03-19)
- Fixed: Audit log filter controls clipped text — `height:28px` replaced with `height:36px`, `font-size:10px` → `12px`, `color:var(--hi)` ensures bright readable text in all fields
- Fixed: Action and Entity dropdowns now use `fi_s` class — consistent dark background, proper border, focus ring
- Fixed: Filter chip showed raw action value (`ASSET_CREATED`) — now shows human-readable label (`Asset Created`)
- Fixed: Entity column in audit table showed raw string (`asset`) — now colour-coded: Asset (blue), Stock (violet), Connectivity (orange), Rack (amber)
- Fixed: Connectivity import skipped second row for same server — duplicate check now uses `src_port_label` (unique per physical link) instead of `src_port` (can repeat across slots)
- Fixed: Import had no audit trail — all imported records now written to audit log with importing user's name
- Fixed: Stock import created duplicates on re-import — now skips if same `brand + model` already exists
- Fixed: Asset import counted existing records as silent drops — now counted and displayed as `⊘ N skipped (already exist)`
- Fixed: Import result only showed imported/errors — now shows all three: imported, skipped, errors
- Fixed: Stock template missing `alloc_qty` column — added so export/re-import round-trips correctly
- New: **📋 View All →** button in Recent Activity card header — always visible, navigates to Audit Log
- New: **⚡ Recent Activity** sidebar quick link — goes to Dashboard and scrolls to activity widget
- New: Audit Log and Recent Activity sidebar items now visible to Admin role (were Superuser-only)

### v3.1.0 (2026-03-19)
- New: **Unified Asset History tab** — one timeline showing asset changes, parts movements, and connectivity changes together
- New: **Stock → Asset allocation tracking** — ALLOCATE/RETURN transactions now link to an asset hostname; the movement appears automatically in that asset's History tab
- New: **Stock History modal** — History button on every stock row shows all transactions, who did them, and which assets received parts
- New: **Connectivity audit trail** — every link add/change/delete now logged with specific field-level changes (switch, port, speed, VLAN)
- New: `GET /api/assets/{id}/full-history` — backend endpoint returning merged timeline of all entity types
- New: `GET /api/stock/{id}/history` — stock audit + transaction records merged and sorted
- New: `GET /api/connectivity/{id}/history` — change log for a connectivity record
- New: `scripts/migrate-audit-v2.sql` — DB migration adding `related_entity` to audit_log and `allocated_to` + `username` to stock_transactions
- New: Global Audit Log now covers stock and connectivity — action filter has grouped optgroups, entity filter includes Stock and Connectivity
- New: Dashboard **Recent Activity** widget — shows last 8 changes across all entities (Admin/Superuser)
- New: Transaction modal defaults to ALLOCATE; Asset Hostname field with autocomplete appears for ALLOCATE/RETURN types only
- Fixed: Export 500 error — `cv()` function now correctly handles PostgreSQL `Decimal`, timezone-aware `datetime`, and all asyncpg types
- Fixed: Audit log page was broken — `renderAuditLog`, `exportAuditLog`, `clearAuditFilters`, `debounceAudit` were called but never defined; all now implemented
- Fixed: cdnjs xlsx library removed from `<head>` — no longer blocks page load on restricted networks; template download lazy-loads it only when needed
- Fixed: Netdata `stream.conf` env var substitution — `netdata-entrypoint.sh` writes the real UUID before Netdata starts (Netdata does not expand `${VAR}` in config files)
- Fixed: Netdata 403 on child nodes — parent `stream.conf` structure corrected (`[UUID]` section header, not `api key =` inside `[stream]`)
- Fixed: Netdata container cgroup visibility — added `/sys/fs/cgroup:/sys/fs/cgroup:ro` mount for Ubuntu 22.04+ cgroups v2
- Fixed: Docker child agent `(unhealthy)` status — added `--no-healthcheck` to `install-netdata-child-docker.sh` (web mode=none so health check always failed)
- Fixed: `save-netdata-child-offline.sh` — SCRIPT_DIR resolved before any `cd`, `curl -fsSL`, size validation on downloaded file

### v3.0.1 (2026-03-14)
- New: Netdata monitoring — parent-child streaming, all nodes in one dashboard at :19999
- New: Multi-node support — enroll bare metal hosts, VMs, any Linux server as child nodes
- New: Air-gapped workflow — `save-netdata-offline.sh` (parent) + `save-netdata-child-offline.sh` (children)
- New: `install-netdata-child-systemd.sh` — dedicated systemd agent installer (online + offline)
- New: `install-netdata-child-docker.sh` — dedicated Docker agent installer with --mode run|compose
- New: Docker child configs written before container start (fixes silent no-stream bug)
- New: `save-netdata-child-offline.sh --docker` — saves Docker image tar for air-gapped Docker children
- New: `save-netdata-child-offline.sh --both` — creates both packages in one run
- Fixed: `save-netdata-child-offline.sh` — SCRIPT_DIR resolved before cd, curl -fsSL, size sanity check
- Removed: combined `install-netdata-child.sh` replaced by two focused scripts
- New: `monitoring/` directory with parent config, child config, stream.conf, alarm notify config
- New: `export-offline.sh` includes Netdata image in full offline bundle
- New: Full glassmorphism UI — frosted glass sidebar, topbar, KPI cards, rack cards, modals, toasts
- New: Ultra-modern zinc/slate dark palette (`#0a0a0f` base, `rgba` whisper-thin borders)
- New: Ambient background gradient canvas (sky/violet/emerald radial gradients behind glass)
- New: Glass inputs — `backdrop-filter` on all form fields, glowing focus rings
- New: Pill-shaped badges and tags across all tables and history view
- New: Gradient primary button with glow shadow on hover
- New: Rack hostname/serial on one line (`HOSTNAME / SERIAL`) — compact, readable
- New: BMC IP, Prov IP, Data IP, Backup IP are clickable links (open `https://ip` in new tab)
- Fixed: Toolbar no longer scrolls — `flex-wrap` fits within available width gracefully
- Fixed: Rack slot hostname colours adapt correctly in light mode (dark text on tinted bg)
- Changed: Rack header — DC name on line 1, Zone + Row chips side by side on line 2
- Changed: Light mode — cool slate-blue palette replaces blinding white
- Changed: Scrollbar — 4px ultra-thin, near-invisible until hover

### v3.0.0 (2026-03-13)
- New: Connectivity table — resizable columns, sort by any column, select-all, bulk delete, cable/speed filters
- New: Asset detail — Topology tab with draggable SVG network diagram
- New: Rack View — hostname-prefix colour grouping (same prefix = same colour, 12-colour palette)
- New: Rack View — U numbers on both left and right sides of every slot
- New: Rack View — utilisation bar (green/amber/red based on fill %)
- New: Rack View — DC/Zone/Row as colour-coded chips on rack card header
- New: Rack View — Export to Excel (Rack Assets + Full U Layout sheets)
- New: Rack View — search box + all toolbar controls in single horizontal row
- New: Dashboard KPI cards are clickable — navigate directly to section
- New: Rack slot shows hostname / serial on single line (compact, 280px wide rack cards)
- Changed: Full design-token CSS system (`--radius`, `--shadow`, `--glass`, `--blur`)
- Changed: Font updated to Inter for improved readability
- Changed: All toolbars horizontal with graceful wrapping (Assets, Connectivity, Stock, Rack View)

### v2.8.0 (2026-03-13)
- Added: HTTPS/SSL support — app now served on port 443, HTTP redirects to HTTPS automatically
- Added: `scripts/generate-certs.sh` — generates self-signed certificate valid for 10 years
- Added: TLS 1.2/1.3 only with strong cipher suite (ECDHE/DHE-AES-GCM)
- Added: HSTS header (Strict-Transport-Security) for enhanced security
- Updated: Nginx config with SSL hardening, HTTP→HTTPS redirect on port 80
- Updated: docker-compose.yml exposes ports 443 and 80 (replaces APP_PORT 3000)
- Updated: `certs/` directory mounted into Nginx container at runtime
- Removed: APP_PORT variable — access is now always https://YOUR-IP with no port number

### v2.7.0 (2026-03-12)
- Added: Slot conflict check on manual asset add/edit — warns with confirmation dialog showing conflicting hostname and U position before saving
- Added: Slot conflict check on import — rows that conflict with an existing asset are skipped and counted as errors (hard fail, no overwrite)
- Added: `/api/assets/check-slot` endpoint — checks rack+U range occupancy, supports multi-U devices and excludes self on edit
- Fixed: Rack view filter — Zone dropdown now correctly populated from `zone` field; Rows from `row_label`
- Fixed: Rack view filter — rk-zone2 (Zones) dropdown now declared in HTML directly, no longer dynamically injected (was causing empty Zones dropdown on load)
- Fixed: Rack data normalisation — if `zone` is null but `row_label` contains "zone", value is automatically treated as zone in the UI
- Fixed: Import now accepts both `rack_zone`/`rack_row` and legacy `zone`/`row_label` column names in Assets sheet

### v2.6.0 (2026-03-12)
- Added: Asset multi-select with checkbox column in assets table
- Added: Select-all checkbox in assets table header
- Added: Bulk delete button in toolbar — appears when assets are selected, shows count, requires confirmation
- Added: Bulk delete clears selection and refreshes table and dashboard on completion

### v2.5.0 (2026-03-12)
- Fixed: Export rack_zone/rack_row column mapping — zone value was appearing in rack_row column instead of rack_zone
- Fixed: Export now uses explicit named variables for rack_zone and rack_row to prevent column shift
- Fixed: Import accepts both `rack_zone`/`zone` and `rack_row`/`row_label` column names for backwards compatibility

### v2.4.0 (2026-03-11)
- Fixed: Rack View crash "filterZ is not defined" on load
- Changed: rack_zone and rack_row columns merged into Assets import/export template (no separate Racks template)
- Added: Assets import auto-creates/updates rack records when rack_zone or rack_row is provided
- Added: Export includes rack_zone and rack_row columns in Assets sheet (joined from racks table)

### v2.3.0 (2026-03-11)
- Added: Separate Datacenter, Zone, and Row fields on racks (DB: new `zone` column in racks table)
- Added: Rack edit mode — ✎ button on each rack card opens pre-filled edit form (admin/superuser)
- Added: Rack delete — ✕ button (superuser only), blocked if rack has assets assigned
- Added: 3-level rack grouping in Rack View: Datacenter → Zone → Row
- Added: Three independent filter dropdowns in Rack View (Datacenter, Zone, Row)
- Added: Each rack card shows DC · Zone · Row subtitle line
- Added: Rack create/edit logged to audit trail
- Added: Racks sheet in Excel export (rack_id, datacenter, zone, row_label, total_u)
- Added: Racks import sheet support
- Updated: Rack list API ordered by datacenter, zone, row_label, rack_id
- DB migration: `scripts/migrate-add-zone.sql`

### v2.2.0 (2026-03-11)
- Added: Auto-logout after 10 minutes of inactivity
- Added: 60-second warning banner before logout with "Stay Logged In" button
- Added: Asset History tab in asset detail panel — full per-asset audit trail
- Added: Audit log written on every asset create, update, delete, relocate, status change
- Added: Hardware field changes (disk, RAM, storage etc.) detected and logged
- Added: `/api/assets/{id}/history` endpoint
- Added: `/api/audit` endpoint (superuser — full audit log)
- Added: Resizable columns in Assets table (drag column edge)
- Added: Column chooser in Assets table (⊞ Columns button)
- Added: Items per page selector (50 / 100 / All) in Assets table
- Added: Pagination bar with page navigation in Assets table
- Fixed: Assets table header/data column mismatch (Prov IP was showing server_type data)
- Fixed: Dashboard Racks count now includes racks referenced by assets, not just explicitly created racks

### v2.1.0 (2026-03-10)
- Fixed: Field Manager "Add Field" and "Edit Opts" buttons not opening modal (null element crash)
- Fixed: Export returning "Not authenticated" (was using window.location without auth header)
- Added: Light mode with clean white/blue professional theme
- Added: Dark/Light mode toggle button in sidebar (preference saved in browser)
- Added: PO Number, EOL Date, App/Asset Owner fields in asset General tab
- Added: Data IP and Backup IP fields in asset Network tab
- Added: VM option to asset Type dropdown
- Renamed: Management IP → Provisioning IP (Prov IP)
- Renamed: OOB/IPMI IP → BMC IP (iDRAC / iLO / IPMI)
- Added: Server Type options Type-A to Type-F, Type-S, Type-T, Type-X through Type-Z
- Added: "Other" option in dropdown fields shows free-text input box
- Added: Superuser can now edit options on all fields including system fields
- Added: Version display and developer credit in sidebar footer
- Removed: Demo credentials block from login page
- Updated: Export and import templates updated with all new fields

### v2.0.0 (2026-03-09)
- Production Docker deployment (FastAPI + PostgreSQL + Nginx)
- JWT authentication with role-based access (superuser / admin / user)
- Asset management with hardware fields, connectivity tracking
- Stock management with transaction history
- Excel export and import
- Automated daily/weekly backups
- Offline/air-gapped deployment support
- All data in ./volumes/ for easy backup integration

### v1.0.0 (2026-03-08)
- Initial single-file localStorage prototype
