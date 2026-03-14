#  ⬡ DC Manager Pro — v3.0.2

**Production Datacenter Asset Management Platform**  
Developed by **pklakkoju**

[![version](https://img.shields.io/badge/version-3.0.1-38bdf8?style=flat-square&labelColor=0a0a0f)](.)
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
```bash
# 1. Extract release zip
unzip dc-manager-production.zip
cd dc-prod

# 2. Configure environment
cp .env.example .env
nano .env
# Set: DB_PASS (no @ # % chars), JWT_SECRET (32+ random chars)

# 3. Create volume directories
mkdir -p volumes/postgres volumes/backups/daily volumes/backups/weekly volumes/backups/manual

# 4. Generate SSL certificate  ← required before first start
./scripts/generate-certs.sh 192.168.86.130   # ← replace with your server IP
# Output: certs/server.crt + certs/server.key

# 5. Start all services
docker compose up -d --build

# 6. Wait for postgres to initialise, then verify
sleep 30 && docker ps
curl -k https://localhost/api/health

# Open: https://YOUR-SERVER-IP
# Login: admin / Admin@123  <- change immediately!
```

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
│   ├── main.py               ← FastAPI app, all API routes
│   ├── init.sql              ← PostgreSQL schema (no demo data)
│   └── requirements.txt
├── frontend/
│   ├── Dockerfile
└──   index.html            ← Full SPA (single-file: HTML + CSS + JS)
├── nginx/
│   └── nginx.conf            ← HTTPS, TLS 1.2/1.3, HTTP→HTTPS redirect
├── certs/                    ← SSL certificate (generated by script)
│   ├── server.crt
│   └── server.key
├── scripts/
│   ├── generate-certs.sh         ← Generate self-signed SSL certificate
│   ├── entrypoint-backup.sh      ← Backup container entrypoint
│   ├── manual-backup.sh          ← Run a manual backup
│   ├── restore.sh                ← Restore from backup
│   ├── export-offline.sh         ← Bundle for air-gapped servers
│   ├── import-offline.sh         ← Install on air-gapped servers
│   ├── migrate-volumes.sh        ← Migrate from named to local volumes
│   ├── migrate-server-types.sql  ← Update server_type options on existing installs
│   └── migrate-add-zone.sql      ← Add zone column to racks (existing installs)
├── volumes/                      ← ALL persistent data — back this up!
│   ├── postgres/                 ← PostgreSQL data files
│   └── backups/
│       ├── daily/                ← Auto daily backups (retained 30 days)
│       ├── weekly/               ← Auto weekly backups (retained 12 weeks)
│       └── manual/               ← Manual backups
├── docker-compose.yml
├── .env.example
└── README.md
```

---

## Roles & Permissions

| Action | Superuser | Admin | User |
|--------|-----------|-------|------|
| View Assets / Racks / Stock | ✓ | ✓ | ✓ |
| Add / Edit / Delete Assets | ✓ | ✓ | ✗ |
| Add / Edit Racks | ✓ | ✓ | ✗ |
| Delete Racks | ✓ | ✗ | ✗ |
| Add / Edit Stock & Transactions | ✓ | ✓ | ✗ |
| Add / Edit Connectivity | ✓ | ✓ | ✗ |
| Export to Excel | ✓ | ✓ | ✓ |
| Import from Excel | ✓ | ✓ | ✗ |
| User Management | ✓ | ✗ | ✗ |
| Field Manager (add/edit fields) | ✓ | ✗ | ✗ |

---

## Features

### Assets
- Full CRUD with tabbed form: General / Hardware / Network / Connectivity
- **General fields:** Hostname, Type, Status, Datacenter, Rack ID, U Position, Asset Tag, Serial Number, PO Number, EOL Date, App/Asset Owner, Notes
- **Network fields:** Provisioning IP (Prov IP), BMC IP — clickable link (opens https://ip), Data IP, Backup IP, MAC, VLAN, Additional IPs
- **Hardware fields:** Fully configurable via Field Manager (Superuser only)
- **Asset History:** Full audit trail per asset — tracks creation, status changes, rack moves, hardware changes
- **Slot conflict protection:** Warns before saving if rack+U position is already occupied; hard-fails on import to prevent duplicate placement
- **Topology tab:** Draggable SVG network diagram showing cable path to switches/LIUs
- Inline connectivity entry from asset form
- Export/Import via Excel

### Asset Table
- Resizable columns (drag column edge)
- Column chooser (toggle which columns are visible)
- Sort by any column (click header, toggle asc/desc)
- Items per page: 50 / 100 / All with pagination
- Filter by Type and Status
- Real-time search: hostname, IP, serial, rack
- Multi-select checkboxes per row + select-all in header
- Bulk delete selected assets (admin/superuser only) with confirmation

### Asset Types
Server, VM, Switch, Router, Firewall, LIU, Patch Panel, PDU, KVM, Other

### Server Types (Hardware field)
Rack Server, Tower, Blade, Dense Server, High-Density, Virtual, VM,
Type-A through Type-F, Type-S, Type-T, Type-X through Type-Z, Other (with free-text input)

### Field Manager (Superuser)
- Add custom hardware fields: text, number, dropdown, textarea
- Edit existing field labels, options, placeholder on all fields including system fields
- Dropdown fields with "Other" option automatically show a free-text input box
- Live preview of hardware form

### Rack View
- Visual rack diagrams showing U positions and assets
- **3-level hierarchy:** Datacenter → Zone → Row
- DC chip on line 1, Zone + Row chips side-by-side on line 2 of each rack card
- Each slot shows: **hostname / serial number** on one line
- U-position numbers on both left and right side of every slot
- Colour-coded by hostname prefix — same prefix = same colour (12-colour palette)
- Utilisation bar: green <60%, amber 60–85%, red >85%
- Filter by Datacenter, Zone, and Row independently
- Search box filters by rack ID or datacenter name
- Edit rack details (✎ — admin/superuser), Delete empty racks (✕ — superuser)
- Click any asset in rack diagram to open asset detail
- **Export Rack to Excel:** Rack Assets sheet + Full U Layout sheet

### Rack Fields
| Field | Description |
|-------|-------------|
| Rack ID | Unique identifier (e.g. R-01, INHYDNARF1NR218) |
| Datacenter | Physical datacenter or pod (e.g. HYN-POD-2) |
| Zone | Zone within the datacenter (e.g. Zone-1) |
| Row | Row within the zone (e.g. Row-15) |
| Total U | Rack height in U (default 42) |
| Notes | Optional notes |

### Stock Management
- SKU tracking with category, brand, model, spec, form factor
- Transactions: IN / OUT / ALLOCATE / RETURN / ADJUST
- Per-SKU transaction history
- Low stock warning (≤5 units)

### Connectivity
- Full path tracking: Server Port → LIU-A → LIU-B → Switch Port
- Cable type (Fiber SM/MM, DAC, Copper), speed, VLAN, purpose
- Resizable columns, sort by any column (click header)
- Filter by cable type and speed
- Select-all + bulk delete with confirmation
- Topology diagram per asset (Asset Detail → Topology tab)

### Asset History / Audit Log
Every asset change is logged automatically:
- `ASSET_CREATED` — new asset added (green)
- `ASSET_RELOCATED` — rack, DC, or U position changed (yellow)
- `ASSET_STATUS_CHANGE` — Online/Offline/Maintenance etc. (purple)
- `ASSET_UPDATED` — any other field change (blue)
- `ASSET_DELETED` — asset removed (red)

Each log entry records: what changed, who made the change, and timestamp.  
Access via the **History** tab in any asset detail panel.

### Session Security
- Auto-logout after **10 minutes of inactivity**
- Warning banner with 60-second countdown before logout
- "Stay Logged In" button resets the timer
- Activity tracked: mouse move, keyboard, scroll, touch

### UI
- **Glassmorphism dark mode** (default) — frosted glass panels, zinc/slate palette, ambient colour gradients
- **Light mode** — cool slate-blue tinted theme, glass inputs, clean readable layout
- Toggle with ◑ button in sidebar — preference saved in browser
- Clickable KPI cards on dashboard navigate directly to sections
- Sidebar navigation with role-aware menu items
- Toast notifications, modal forms, column chooser
- Version and developer credit in sidebar footer

---

## Export / Import

### Export (Download)
Downloads a full Excel workbook with all data across sheets:
- **Assets** — all assets with all fields including rack_zone and rack_row
- **Racks** — all racks with datacenter, zone, row
- **Stock** — all stock items
- **Connectivity** — all cabling records

### Export Rack View
Downloads rack layout as Excel with two sheets:
- **Rack Assets** — one row per asset: hostname, serial, BMC IP, Mgmt IP, make, model, PO number
- **Full U Layout** — every U position including empty slots for physical audit

Respects current DC/Zone/Row filter. Filename includes DC name and date.

### Import Templates (Download)
Single Excel workbook with template sheets:
- **Assets_Template** — includes `datacenter`, `rack_zone`, `rack_row`, `rack_id` columns.
  When importing, if `rack_zone` / `rack_row` are provided, the rack record is **automatically
  created or updated** in the racks table — no separate rack import needed.
- **Stock_Template**
- **Connectivity_Template**

### Assets Import Column Reference

| Column | Required | Notes |
|--------|----------|-------|
| hostname | ✓ | Must be unique |
| asset_type | | Default: Server |
| status | | Default: Online |
| datacenter | | e.g. HYN-POD-2 |
| rack_zone | | e.g. Zone-1 — auto-creates rack |
| rack_row | | e.g. Row-1 — auto-creates rack |
| rack_id | | e.g. R-01 |
| u_start | | U position (number) |
| u_height | | Default: 1 |
| prov_ip | | Provisioning IP (also accepts mgmt_ip) |
| bmc_ip | | BMC/iDRAC/iLO IP (also accepts oob_ip) |
| data_ip | | Data network IP |
| bkup_ip | | Backup network IP |
| mac_addr | | MAC address |
| vlan | | VLAN ID |
| asset_tag | | Physical asset tag |
| serial_number | | Serial number |
| po_number | | Purchase order number |
| eol_date | | End of life date (YYYY-MM-DD) |
| app_owner | | Application/asset owner |
| notes | | Free text notes |
| *(custom hw fields)* | | Any field_key from Field Manager |

---

## Database Migrations (Existing Installs)

Run these when upgrading an existing install — all scripts are safe to run multiple times:

```bash
# Docker installs
docker cp scripts/migrate-add-zone.sql    dcm_postgres:/tmp/
docker cp scripts/migrate-server-types.sql dcm_postgres:/tmp/
docker exec dcm_postgres psql -U dcuser -d dcmanager -f /tmp/migrate-add-zone.sql
docker exec dcm_postgres psql -U dcuser -d dcmanager -f /tmp/migrate-server-types.sql

# Bare metal installs
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
| `/api/assets/{id}/history` | GET | Any | Asset audit trail |
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


## Monitoring (Netdata)

DC Manager Pro uses **Netdata** for real-time monitoring — fully self-hosted, no cloud, no internet required after initial setup. A **parent-child streaming** architecture lets you see your DC Manager VM, its bare metal host, and any number of additional servers all in one dashboard.

### Architecture

```
┌──────────────────────────────────────────────────────────────┐
│  DC Manager VM  (192.168.86.130)                             │
│  ┌────────────────────────────────────────────────────────┐  │
│  │  dcm_netdata container  :19999  (PARENT)              │  │
│  │  • Monitors the VM itself (CPU/RAM/disk/net)          │  │
│  │  • Monitors all DC Manager Docker containers          │  │
│  │  • Receives + stores streams from all child nodes     │  │
│  │  • Single dashboard for every machine                 │  │
│  └──────────────────────┬─────────────────────────────────┘  │
└─────────────────────────┼────────────────────────────────────┘
                          │  child nodes push metrics to :19999
          ┌───────────────┼───────────────────┐
          │               │                   │
  ┌───────▼──────┐  ┌─────▼────────┐  ┌──────▼───────┐
  │ Bare Metal 1 │  │ Bare Metal 2 │  │  Any Linux   │
  │ (hypervisor) │  │ (storage)    │  │  server / VM │
  │              │  │              │  │              │
  │  choose one: │  │  choose one: │  │  choose one: │
  │  systemd     │  │  systemd     │  │  systemd     │
  │  ── OR ──    │  │  ── OR ──    │  │  ── OR ──    │
  │  Docker      │  │  Docker      │  │  Docker      │
  └──────────────┘  └──────────────┘  └──────────────┘
```

**Dashboard:** `http://192.168.86.130:19999`
Switch between machines with the **host dropdown** (top-right corner).

---

### What Netdata monitors on every node

| Category | Metrics |
|----------|---------|
| CPU | Per-core usage, frequency, steal time |
| Memory | RAM used/free/cached, swap, page faults/sec |
| Disk I/O | Reads/writes per disk, latency, utilisation % |
| Disk space | Usage % per mount point, inode usage |
| Network | Bandwidth, packets, errors per interface |
| System | Load avg (1/5/15 min), processes, context switches |
| Docker | CPU/RAM/network/I/O per container *(Docker hosts only)* |
| PostgreSQL | Queries/sec, connections, cache hit ratio *(DC Manager VM)* |
| Alerts | Auto-alerts for high CPU/RAM, disk full, OOM, errors |

---

### Two separate installer scripts — pick one per machine

| Script | Use when |
|--------|----------|
| `install-netdata-child-systemd.sh` | Machine is bare metal, has no Docker, or you want the agent to start before Docker on boot |
| `install-netdata-child-docker.sh` | Machine already runs Docker, or you prefer container-based management |

Both scripts support **online** (internet available) and **offline / air-gapped** installs.
Both produce the same result — metrics stream to the parent dashboard.

---

### Step 0 — Generate your API key (one time only)

All child nodes use a shared secret to authenticate with the parent.
Generate one key and use it everywhere:

```bash
uuidgen
# Example: a1b2c3d4-e5f6-7890-abcd-ef1234567890
```

Set it in both config files on your DC Manager VM, then restart:

```bash
sed -i 's/api key = .*/api key = a1b2c3d4-e5f6-7890-abcd-ef1234567890/' \
  /appdata/dc-prod/monitoring/netdata.conf

sed -i 's/api key = .*/api key = a1b2c3d4-e5f6-7890-abcd-ef1234567890/' \
  /appdata/dc-prod/monitoring/stream.conf

docker restart dcm_netdata
```

---

### Step 1 — Start the Parent Node

```bash
cd /appdata/dc-prod
mkdir -p volumes/netdata/{config,lib,cache}
docker compose up -d --build

# Verify
docker ps | grep dcm_netdata
docker logs dcm_netdata --tail 20

# Open dashboard
http://192.168.86.130:19999
```

---

### Step 2a — systemd Child Install

Use `install-netdata-child-systemd.sh` on machines where you want a **native Linux service**.

#### Online (machine has internet)

```bash
# Copy script from DC Manager VM to the target machine
scp /appdata/dc-prod/scripts/install-netdata-child-systemd.sh user@baremetal-01:/tmp/

# Run on the target machine
sudo bash /tmp/install-netdata-child-systemd.sh \
  --parent 192.168.86.130 \
  --apikey a1b2c3d4-e5f6-7890-abcd-ef1234567890 \
  --name   baremetal-01
```

#### Offline / air-gapped (no internet on target machine)

**Step A — On any internet machine, create the offline package (once):**
```bash
cd /appdata/dc-prod
./scripts/save-netdata-child-offline.sh
# Output: netdata-child-offline-YYYYMMDD.tar.gz  (~80 MB)
```

**Step B — Transfer to the target machine:**
```bash
scp netdata-child-offline-YYYYMMDD.tar.gz user@baremetal-01:/opt/
scp /appdata/dc-prod/scripts/install-netdata-child-systemd.sh user@baremetal-01:/tmp/
```

**Step C — Install on the target machine (no internet needed):**
```bash
cd /opt
tar -xzf netdata-child-offline-YYYYMMDD.tar.gz

sudo bash /tmp/install-netdata-child-systemd.sh \
  --parent  192.168.86.130 \
  --apikey  a1b2c3d4-e5f6-7890-abcd-ef1234567890 \
  --name    baremetal-01 \
  --offline /opt/netdata-child-offline-YYYYMMDD/netdata-static-installer.gz.run
```

#### Day-to-day (systemd)
```bash
systemctl status  netdata          # check status
systemctl restart netdata          # restart after config change
journalctl -u netdata -f           # live logs
journalctl -u netdata --no-pager | grep -i "connected\|error"   # check stream
systemctl stop    netdata          # stop
```

#### Remove systemd agent
```bash
sudo systemctl stop netdata && sudo systemctl disable netdata

# If installed via kickstart:
sudo /usr/libexec/netdata/netdata-uninstaller.sh --yes --env /etc/netdata/.environment

# If installed via apt:
sudo apt-get remove --purge netdata -y && sudo apt-get autoremove -y

# If installed via dnf/yum:
sudo dnf remove netdata -y

# Clean up all data and config
sudo rm -rf /etc/netdata /var/lib/netdata /var/cache/netdata /var/log/netdata
sudo rm -rf /usr/share/netdata /usr/lib/netdata
sudo systemctl daemon-reload
sudo userdel  netdata 2>/dev/null || true
sudo groupdel netdata 2>/dev/null || true
```

---

### Step 2b — Docker Child Install

Use `install-netdata-child-docker.sh` on machines that already run Docker.

The script has two modes set with `--mode`:
- `run` (default) — `docker run` single container
- `compose` — creates `/opt/netdata-child/docker-compose.yml` and uses `docker compose`

> ⚠️ **Important:** Config files are always written to the host at `/etc/netdata/` **before** the container starts. This is critical — if the container starts with an empty config directory, Netdata generates defaults that omit streaming and the node will never appear in the dashboard.

#### Online — docker run (default)

```bash
scp /appdata/dc-prod/scripts/install-netdata-child-docker.sh user@baremetal-01:/tmp/

sudo bash /tmp/install-netdata-child-docker.sh \
  --parent 192.168.86.130 \
  --apikey a1b2c3d4-e5f6-7890-abcd-ef1234567890 \
  --name   baremetal-01
```

#### Online — docker compose

```bash
sudo bash /tmp/install-netdata-child-docker.sh \
  --parent 192.168.86.130 \
  --apikey a1b2c3d4-e5f6-7890-abcd-ef1234567890 \
  --name   baremetal-01 \
  --mode   compose
```

#### Offline / air-gapped — docker run

**Step A — On any internet machine, save the Docker image (once):**
```bash
cd /appdata/dc-prod
./scripts/save-netdata-child-offline.sh --docker
# Output: netdata-image-YYYYMMDD.tar  (~200 MB)
```

**Step B — Transfer to the target machine:**
```bash
scp netdata-image-YYYYMMDD.tar user@baremetal-01:/opt/
scp /appdata/dc-prod/scripts/install-netdata-child-docker.sh user@baremetal-01:/tmp/
```

**Step C — Install (no internet needed):**
```bash
sudo bash /tmp/install-netdata-child-docker.sh \
  --parent  192.168.86.130 \
  --apikey  a1b2c3d4-e5f6-7890-abcd-ef1234567890 \
  --name    baremetal-01 \
  --offline /opt/netdata-image-YYYYMMDD.tar
```

#### Offline / air-gapped — docker compose

```bash
sudo bash /tmp/install-netdata-child-docker.sh \
  --parent  192.168.86.130 \
  --apikey  a1b2c3d4-e5f6-7890-abcd-ef1234567890 \
  --name    baremetal-01 \
  --mode    compose \
  --offline /opt/netdata-image-YYYYMMDD.tar
```

#### Day-to-day — docker run
```bash
docker ps | grep netdata-child               # status
docker logs netdata-child -f                 # live logs
docker logs netdata-child 2>&1 | grep -i "connected\|error"   # check stream
docker restart netdata-child                 # restart after config change
docker stop    netdata-child                 # stop
docker start   netdata-child                 # start
```

#### Day-to-day — docker compose
```bash
cd /opt/netdata-child
docker compose ps                            # status
docker compose logs -f                       # live logs
docker compose logs 2>&1 | grep -i "connected\|error"        # check stream
docker compose restart                       # restart after config change
docker compose stop                          # stop
docker compose start                         # start
docker compose down                          # stop and remove container
```

#### Remove Docker agent — docker run
```bash
docker stop netdata-child
docker rm   netdata-child
docker rmi  netdata/netdata:stable           # optional — frees ~200MB disk

sudo rm -rf /etc/netdata /var/lib/netdata /var/cache/netdata
```

#### Remove Docker agent — docker compose
```bash
cd /opt/netdata-child
docker compose down
docker rmi netdata/netdata:stable            # optional

rm -rf /opt/netdata-child
sudo rm -rf /etc/netdata /var/lib/netdata /var/cache/netdata
```

---

### Step 3 — Verify a node is streaming

After any install, check within 30 seconds:

```bash
# On the parent VM — look for the child connecting
docker logs dcm_netdata 2>&1 | grep -i "baremetal-01\|connected" | tail -5

# On the child (systemd)
journalctl -u netdata --no-pager | grep -i "connected\|stream" | tail -5
# Expected: Successfully connected to 192.168.86.130:19999

# On the child (Docker)
docker logs netdata-child 2>&1 | grep -i "connected\|stream" | tail -5
```

Then open `http://192.168.86.130:19999` — the host dropdown (top-right) will show the new node.

---

### Adding More Nodes

Same script, different `--name` each time. No restarts needed on the parent.

```bash
# systemd — online
sudo bash /tmp/install-netdata-child-systemd.sh \
  --parent 192.168.86.130 --apikey YOUR-KEY --name storage-server-01

# Docker run — online
sudo bash /tmp/install-netdata-child-docker.sh \
  --parent 192.168.86.130 --apikey YOUR-KEY --name storage-server-01

# Docker run — offline
sudo bash /tmp/install-netdata-child-docker.sh \
  --parent 192.168.86.130 --apikey YOUR-KEY --name storage-server-01 \
  --offline /opt/netdata-image-YYYYMMDD.tar
```

---

### Remove the Parent (stop all monitoring)

```bash
cd /appdata/dc-prod
docker compose stop netdata
docker compose rm -f netdata
rm -rf volumes/netdata
docker rmi netdata/netdata:stable          # optional

# To prevent Netdata starting again on next compose up,
# comment out the netdata service block in docker-compose.yml
```

---

### Scripts Reference

| Script | Where to run | Purpose |
|--------|-------------|---------|
| `scripts/save-netdata-offline.sh` | Internet machine | Save parent Docker image for air-gapped DC Manager VM |
| `scripts/load-netdata-offline.sh` | DC Manager VM | Load parent image and start |
| `scripts/save-netdata-child-offline.sh` | Internet machine | Create systemd offline package (default) |
| `scripts/save-netdata-child-offline.sh --docker` | Internet machine | Save Docker image tar for air-gapped Docker children |
| `scripts/save-netdata-child-offline.sh --both` | Internet machine | Create both packages in one run |
| `scripts/install-netdata-child-systemd.sh` | Each child node | Install Netdata as a native systemd service |
| `scripts/install-netdata-child-docker.sh` | Each child node | Install Netdata as a Docker container (run or compose) |

---

### Configuration Files

| File | Used by | Purpose |
|------|---------|---------|
| `monitoring/netdata.conf` | Parent container | History, memory, streaming accept, web access |
| `monitoring/stream.conf` | Reference — copied to child `/etc/netdata/stream.conf` | Parent IP, API key, reconnect settings |
| `monitoring/netdata-child.conf` | Reference for manual installs | Minimal child config |
| `monitoring/health_alarm_notify.conf` | Parent container | Email/Slack alert settings (all off by default) |

**Change API key across all nodes:**
```bash
NEW_KEY=$(uuidgen)

# Parent
sed -i "s/api key = .*/api key = $NEW_KEY/" /appdata/dc-prod/monitoring/netdata.conf
sed -i "s/api key = .*/api key = $NEW_KEY/" /appdata/dc-prod/monitoring/stream.conf
docker restart dcm_netdata

# Each child — systemd
sed -i "s/api key = .*/api key = $NEW_KEY/" /etc/netdata/stream.conf
systemctl restart netdata

# Each child — Docker
sed -i "s/api key = .*/api key = $NEW_KEY/" /etc/netdata/stream.conf
docker restart netdata-child
# or: cd /opt/netdata-child && docker compose restart
```

---

### Data Volumes

```
volumes/netdata/
├── config/    ← Netdata runtime config (auto-generated)
├── lib/       ← Metric history database (persists across restarts)
└── cache/     ← Working cache (safe to delete if disk is full)
```


## Changelog

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
