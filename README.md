# ⬡ DC Manager Pro — v3.0.0

<div align="center">

![Version](https://img.shields.io/badge/version-3.0.0-00c8ff?style=flat-square)
![Python](https://img.shields.io/badge/Python-3.12-3776AB?style=flat-square&logo=python&logoColor=white)
![FastAPI](https://img.shields.io/badge/FastAPI-0.111-009688?style=flat-square&logo=fastapi&logoColor=white)
![PostgreSQL](https://img.shields.io/badge/PostgreSQL-16-4169E1?style=flat-square&logo=postgresql&logoColor=white)
![Docker](https://img.shields.io/badge/Docker-Compose-2496ED?style=flat-square&logo=docker&logoColor=white)
![Nginx](https://img.shields.io/badge/Nginx-1.25-009639?style=flat-square&logo=nginx&logoColor=white)
![License](https://img.shields.io/badge/license-MIT-green?style=flat-square)

**Production-ready Datacenter Asset Management platform.**  
Track servers, racks, cabling, and spare parts — with role-based access control, persistent PostgreSQL storage, and automated backups.

Developed by **pklakkoju**

</div>

---

---

## What is DC Manager Pro?

DC Manager Pro is a self-hosted web application for managing physical datacenter infrastructure. It gives you a single place to track every server, switch, LIU, PDU and other asset in your datacenter — where it lives in the rack, what IP it has, what cables connect it, and what spare parts you have on the shelf. Everything runs on your own server with no external dependencies or cloud services.

Think of it as a lightweight DCIM (Datacenter Infrastructure Management) tool built for small-to-medium datacenters that need something practical and fast to deploy.

---

## Features & How to Use Them

### 🔐 Login & User Roles

When you open the app you land on the sign-in page. Enter your username and password.

There are three roles:

| Role | What they can do |
|------|-----------------|
| **Superuser** | Full access — manage users, roles, all data, delete anything |
| **Admin** | Add, edit and delete assets, racks, stock and connectivity |
| **Viewer** | Read-only — can view everything but cannot make changes |

The first account created is `admin / Admin@123` — **change this immediately** after first login. Superusers can create and manage users from the **Admin → Users** menu.

The session auto-expires after inactivity. A warning banner appears 60 seconds before logout — click **Stay Logged In** to extend.

---

### ◈ Dashboard

The dashboard is the home screen. It shows you the health of your datacenter at a glance.

**KPI Cards** (top row) — click any card to jump straight to that section:
- **Total Assets** → goes to All Assets page
- **Servers** → goes to All Assets filtered view
- **Racks** → goes to Rack View
- **Connections** → goes to Connectivity page
- **Stock SKUs** → goes to Stock / Parts page
- **Low Stock** → goes to Stock / Parts (items with ≤5 units remaining)

**Assets by Type** — horizontal bar chart showing how many of each asset type (Server, Switch, LIU, etc.) you have.

**Stock Summary** — breakdown of parts inventory by category with bar indicators.

**Recent Assets** — the last 8 assets added or modified, with hostname, type, rack location and management IP.

---

### ◻ All Assets

The main inventory table. Every physical and virtual asset in your datacenter.

**Searching & Filtering:**
- Type in the search box to filter by hostname, IP address, serial number or rack ID — results update as you type
- Use the **All Types** dropdown to filter by asset type (Server, VM, Switch, Router, Firewall, LIU, Patch Panel, PDU, KVM, Other)
- Use the **All Status** dropdown to filter by status (Online, Offline, Maintenance, Decommissioned, Spare)
- Use the **50/pg** dropdown to control how many rows appear per page

**Columns:**
- Click **⊞ Cols** to show/hide columns — toggle Data IP, Backup IP, App Owner and more
- Drag the edge of any column header to resize it
- Click any column header to sort ascending/descending

**Adding an Asset:**
Click **+ Add Asset** (top right). Fill in:
- Hostname, asset type, status
- Datacenter, rack ID and U position (checks for slot conflicts automatically)
- Management IP (Prov IP), BMC/OOB IP, MAC address, VLAN
- Hardware tab: Make, Model, Serial Number, Asset Tag, PO Number, EOL Date, App Owner, Data IP, Backup IP
- Any custom hardware fields defined in Field Manager

**Editing / Deleting:**
Each row has **Edit** and **Del** buttons. Deleting is permanent — there is no recycle bin. Bulk-select rows using the checkboxes then click **🗑 Delete** to remove multiple assets at once.

**Clicking a hostname** opens the Asset Detail panel with three tabs:
- **Info** — all asset fields in a clean read panel, with clickable links for BMC IP, Prov IP, Data IP and Backup IP (opens `https://ip` in a new tab)
- **History** — full audit trail of every change made to the asset (who, what, when)
- **Topology** — draggable network diagram showing how this asset connects to switches and LIUs

---

### ▤ Rack View

A visual representation of your physical racks. Each rack is drawn as a card showing every U position from top (42U) to bottom (1U).

**Reading a rack card:**
- The rack ID is shown in the header in cyan
- Below it: the Datacenter name, and Zone + Row side by side as colour-coded chips
- The thin bar under the header is the **utilisation bar** — green when <60% full, amber at 60–85%, red above 85%
- The `xx/42U` in the top right shows used U vs total U
- U numbers appear on both the left and right edge of every slot
- Each filled slot shows: **hostname / serial number** on one line
- Empty slots are shown as blank rows

**Colour coding:**
- Servers with the same hostname prefix (e.g. `HYNRBBMPRUPICAS01` through `HYNRBBMPRUPICAS10`) automatically share the same colour across all racks — makes it easy to see which group of servers is where
- Switches/Routers/Firewalls = green
- LIUs/Patch Panels = orange
- PDUs = amber
- Other = purple

**Filtering:** Use the toolbar dropdowns to filter by Datacenter, Zone or Row. The search box filters by rack ID or datacenter name.

**Clicking a slot** opens the full Asset Detail panel for that asset.

**New Rack:** Click **+ New Rack** to define a rack. Enter the Rack ID, Datacenter, Zone, Row and total U height (default 42U).

**Export Rack:** Click **↓ Export Rack** to download an Excel file of the current rack view with two sheets:
- *Rack Assets* — one row per filled slot (hostname, serial, BMC IP, Mgmt IP, make, model, PO number etc.)
- *Full U Layout* — every U position including empty slots, useful for physical audits

---

### ◫ Stock / Parts

Tracks spare parts and hardware inventory — drives, RAM, NICs, transceivers, cables, PSUs, fans and anything else you keep on the shelf.

**Each stock item has:**
- Category, Brand, Model, Spec (e.g. `1.92TB`, `32GB DDR4`)
- Form factor and interface type
- Total qty, Available qty, Allocated qty
- Storage location (e.g. `Shelf A3`)
- Unit cost

**Adding stock:** Click **+ Add Stock Item**. Fill in the details and set an initial quantity.

**Stock transactions:** Use the **+ / −** buttons on each row to record stock in/out movements. Every transaction is logged.

**Low stock warning:** Items with ≤5 available units are highlighted in the sidebar counter and on the Dashboard. Set a minimum threshold when creating items.

**Searching:** Use the search box or the Category dropdown to find items quickly.

---

### ⇄ Connectivity

Tracks the physical cabling path from a server port all the way through to the switch — including intermediate LIUs (patch panels / fibre termination units).

**A connectivity record captures the full path:**
```
Server port  →  LIU-A (rack/hostname/port)  →  LIU-B  →  Switch port
```

**Each record stores:**
- Source server hostname, slot, port and port label
- LIU-A details (rack, hostname, port)
- LIU-B details (optional — for multi-hop paths)
- Destination switch hostname and port
- Cable type (Fiber SM, Fiber MM, DAC, Copper)
- Speed (1G, 10G, 25G, 40G, 100G, 400G)
- VLAN and purpose (e.g. Management, Data, Storage)

**Filtering:** Filter by cable type or speed using the toolbar dropdowns. Search by hostname, port label or purpose.

**Sort:** Click any column header to sort. Click again to reverse.

**Bulk delete:** Select rows with checkboxes then click **🗑 Delete** to remove multiple records at once.

**Topology view:** Open any asset's detail panel and click the **Topology** tab to see a draggable visual diagram of all connectivity paths for that asset.

---

### ↓ Export / Import

**Export to Excel:** Downloads a single `.xlsx` file with three sheets — Assets, Stock and Connectivity — containing every field including custom hardware fields.

**Import from Excel:** Upload a filled-in `.xlsx` to bulk-load assets, stock or connectivity records. Use the **Download Templates** button first to get the correct column headers. Row 1 must be the header row. IDs are auto-generated on import — do not fill the ID column.

**Import rules:**
- Assets: hostname must be unique
- Existing records are updated if the ID column matches; new rows are inserted
- Invalid rows are skipped and reported in the result summary

---

### ⚙ Field Manager *(Superuser only)*

Lets you add custom fields to the Asset form's Hardware tab — useful for site-specific data like rack unit power draw, warranty ticket number, firmware version etc.

**Adding a field:** Click **+ Add Field**, enter a name, choose a type (Text, Number, Date, Select) and mark it required or optional. It immediately appears in the Asset form for all users.

**System fields** (Make, Model, Serial, PO Number etc.) are locked and cannot be removed.

---

### 🔒 Permissions *(Superuser only)*

Shows a matrix of what each role (Viewer, Admin, Superuser) can do across each section of the app. This is read-only documentation — roles are fixed by design and cannot be customised.

---

### 👤 Users *(Superuser only)*

Create, edit and delete user accounts. Each user is assigned one of the three roles. Passwords are hashed with bcrypt — never stored in plain text.

---

### ◑ Light / Dark Mode

Click the **◑** button in the top-left of the sidebar to toggle between dark mode (default deep navy) and light mode (cool slate-blue). The preference is saved in the browser.

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
| Vanilla JS | Built-in | No framework — pure DOM manipulation |

### Infrastructure
| Component | Software | Version | Purpose |
|-----------|----------|---------|---------|
| Web server / Proxy | Nginx | 1.25 | Serves frontend, reverse-proxies API |
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
    listen 3000;
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
sudo ufw allow 3000/tcp

# Open browser: http://YOUR-SERVER-IP:3000
```

#### Step 6 — Verify
```bash
sudo systemctl status postgresql dc-manager nginx
curl http://127.0.0.1:8000/api/health
# Expected: {"status":"ok"}
# Full app: https://YOUR-SERVER-IP
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

#### Bare Metal — HTTPS / SSL Setup

##### Step 1 — Install OpenSSL (usually pre-installed)
```bash
sudo apt install -y openssl
```

##### Step 2 — Generate Self-Signed Certificate

**Option A — Using the bundled script (recommended):**
```bash
cd /opt/dc-manager/dc-prod

# Pass your server IP as argument
./scripts/generate-certs.sh 192.168.86.130

# Output:
# dc-prod/certs/server.crt  ← certificate (public)
# dc-prod/certs/server.key  ← private key (keep secret)
```

Then copy the generated certs to the Nginx directory:
```bash
sudo mkdir -p /etc/nginx/certs
sudo cp /opt/dc-manager/dc-prod/certs/server.crt /etc/nginx/certs/server.crt
sudo cp /opt/dc-manager/dc-prod/certs/server.key /etc/nginx/certs/server.key
sudo chmod 600 /etc/nginx/certs/server.key
sudo chmod 644 /etc/nginx/certs/server.crt
```

**Option B — Generate directly (manual):**
```bash
SERVER_IP="192.168.86.130"   # ← change to your server IP
sudo mkdir -p /etc/nginx/certs

sudo openssl req -x509 -nodes -newkey rsa:2048 \
  -keyout /etc/nginx/certs/server.key \
  -out    /etc/nginx/certs/server.crt \
  -days   3650 \
  -subj   "/C=IN/ST=Telangana/L=Hyderabad/O=DC Manager/CN=$SERVER_IP" \
  -addext "subjectAltName=IP:$SERVER_IP,IP:127.0.0.1"

sudo chmod 600 /etc/nginx/certs/server.key
sudo chmod 644 /etc/nginx/certs/server.crt
```

##### Step 3 — Update Nginx Config for HTTPS
```bash
sudo tee /etc/nginx/sites-available/dc-manager << 'EOF'
# HTTP → HTTPS redirect
server {
    listen 80;
    server_name _;
    return 301 https://$host$request_uri;
}

# HTTPS main server
server {
    listen 443 ssl;
    http2  on;
    server_name _;

    ssl_certificate     /etc/nginx/certs/server.crt;
    ssl_certificate_key /etc/nginx/certs/server.key;

    ssl_protocols             TLSv1.2 TLSv1.3;
    ssl_ciphers               ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256:ECDHE-ECDSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-GCM-SHA384:DHE-RSA-AES128-GCM-SHA256;
    ssl_prefer_server_ciphers off;
    ssl_session_cache         shared:SSL:10m;
    ssl_session_timeout       1d;

    add_header Strict-Transport-Security "max-age=63072000; includeSubDomains" always;
    add_header X-Frame-Options           "SAMEORIGIN"    always;
    add_header X-Content-Type-Options    "nosniff"       always;
    add_header X-XSS-Protection          "1; mode=block" always;

    root  /var/www/dc-manager;
    index index.html;

    location /api/ {
        proxy_pass         http://127.0.0.1:8000;
        proxy_set_header   Host              $host;
        proxy_set_header   X-Real-IP         $remote_addr;
        proxy_set_header   X-Forwarded-For   $proxy_add_x_forwarded_for;
        proxy_set_header   X-Forwarded-Proto https;
        proxy_read_timeout 300s;
        client_max_body_size 50M;
    }

    location /api/auth/login {
        proxy_pass       http://127.0.0.1:8000/api/auth/login;
        proxy_set_header Host      $host;
        proxy_set_header X-Real-IP $remote_addr;
    }

    location / {
        try_files $uri $uri/ /index.html;
    }

    gzip on;
    gzip_types text/html text/css application/javascript application/json;
}
EOF

sudo nginx -t && sudo systemctl reload nginx
```

##### Step 4 — Open Firewall Ports
```bash
sudo ufw allow 443/tcp
sudo ufw allow 80/tcp
# Remove old port 3000 if previously opened
sudo ufw delete allow 3000/tcp
```

##### Step 5 — Verify
```bash
curl -k https://localhost/api/health
# Expected: {"status":"ok"}
# Open: https://YOUR-SERVER-IP
```

##### Bare Metal — Certificate Renewal (every 10 years)
```bash
cd /opt/dc-manager/dc-prod
./scripts/generate-certs.sh 192.168.86.130
sudo cp certs/server.crt /etc/nginx/certs/server.crt
sudo cp certs/server.key /etc/nginx/certs/server.key
sudo chmod 600 /etc/nginx/certs/server.key
sudo systemctl reload nginx
```

##### Bare Metal — Using Your Own Certificate
```bash
sudo cp your-cert.crt /etc/nginx/certs/server.crt
sudo cp your-cert.key /etc/nginx/certs/server.key
sudo chmod 600 /etc/nginx/certs/server.key
sudo systemctl reload nginx
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
sudo firewall-cmd --permanent --add-port=443/tcp
sudo firewall-cmd --permanent --add-port=80/tcp
sudo firewall-cmd --reload


# SELinux — allow Nginx to connect to backend
sudo setsebool -P httpd_can_network_connect 1

# HTTPS — generate certificate using the bundled script
sudo dnf install -y openssl
cd /opt/dc-manager/dc-prod
./scripts/generate-certs.sh 192.168.86.130
sudo mkdir -p /etc/nginx/certs
sudo cp certs/server.crt /etc/nginx/certs/server.crt
sudo cp certs/server.key /etc/nginx/certs/server.key
sudo chmod 600 /etc/nginx/certs/server.key
# Then apply the same Nginx HTTPS config from the Ubuntu HTTPS step above
```

---


## HTTPS / SSL Setup

HTTP on port 80 automatically redirects to HTTPS on port 443 — no port number needed in the URL (`https://192.168.86.130`).

### Docker — HTTPS Setup

#### Step 1 — Generate Self-Signed Certificate
```bash
cd /appdata/dc-prod

# Pass your server IP as argument
./scripts/generate-certs.sh 192.168.86.130

# Output:
# certs/server.crt  ← certificate (public)
# certs/server.key  ← private key (keep secret, never commit to git)
```

#### Step 2 — Deploy
```bash
docker compose up -d --build
```

#### Step 3 — Access
```
https://192.168.86.130
```

Your browser will show a security warning because the certificate is self-signed. This is expected for internal tools.

**Chrome/Edge:** Click **Advanced** → **Proceed to 192.168.86.130 (unsafe)**  
**Firefox:** Click **Advanced** → **Accept the Risk and Continue**

---

### Suppress the Browser Warning (Optional)

To permanently trust the certificate on your machine so the warning never appears:

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
sudo security add-trusted-cert -d -r trustRoot   -k /Library/Keychains/System.keychain certs/server.crt
# Restart browser
```

**Linux (Chrome/Edge):**
```bash
# Ubuntu/Debian
sudo cp certs/server.crt /usr/local/share/ca-certificates/dc-manager.crt
sudo update-ca-certificates
# Restart browser
```

**Linux (Firefox):** Firefox manages its own trust store.  
Go to **Settings → Privacy & Security → Certificates → View Certificates → Authorities → Import** → select `server.crt` → trust for websites.

---

#### Docker — Renewing the Certificate

Self-signed certs are valid for 10 years. When renewal is needed:
```bash
cd /appdata/dc-prod
./scripts/generate-certs.sh 192.168.86.130
docker compose restart frontend
```

#### Docker — Using Your Own Certificate (.crt + .key)

If you have a corporate CA or wildcard certificate:
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

> ⚠ **Change the default password immediately after first login via User Management.**

---

## Directory Structure

```
dc-prod/
├── backend/
│   ├── Dockerfile
│   ├── main.py               <- FastAPI app, all API routes
│   ├── init.sql              <- PostgreSQL schema (no demo data)
│   └── requirements.txt
├── frontend/
│   ├── Dockerfile
│   └── index.html            <- Full SPA (HTML + CSS + JS in one file)
├── nginx/
│   └── nginx.conf            <- Docker Nginx config
├── scripts/
│   ├── entrypoint-backup.sh      <- Backup container entrypoint
│   ├── manual-backup.sh          <- Run a manual backup
│   ├── restore.sh                <- Restore from backup
│   ├── export-offline.sh         <- Bundle for air-gapped servers
│   ├── import-offline.sh         <- Install on air-gapped servers
│   ├── migrate-volumes.sh        <- Migrate from named to local volumes
│   ├── migrate-server-types.sql  <- Update server_type options
│   └── migrate-add-zone.sql      <- Add zone column to racks table
├── volumes/                      <- ALL persistent data — back this up!
│   ├── postgres/                 <- PostgreSQL data files
│   └── backups/
│       ├── daily/                <- Auto daily (30 day retention)
│       ├── weekly/               <- Auto weekly (12 week retention)
│       └── manual/               <- Manual backups
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
- **Network fields:** Provisioning IP (Prov IP), BMC IP (iDRAC/iLO/IPMI), Data IP, Backup IP, MAC, VLAN, Additional IPs
- **Hardware fields:** Fully configurable via Field Manager (Superuser only)
- **Asset History:** Full audit trail per asset — tracks creation, status changes, rack moves, hardware changes
- **Slot conflict protection:** Warns before saving if rack+U position is already occupied; hard-fails on import to prevent duplicate placement
- Inline connectivity entry from asset form
- Export/Import via Excel

### Asset Table
- Resizable columns (drag column edge)
- Column chooser (toggle which columns are visible)
- Items per page: 50 / 100 / All with pagination
- Filter by Type and Status
- Multi-select checkboxes + select-all in header
- Bulk delete (admin/superuser only) with confirmation

### Asset Types
Server, VM, Switch, Router, Firewall, LIU, Patch Panel, PDU, KVM, Other

### Server Types (Hardware field)
Rack Server, Tower, Blade, Dense Server, High-Density, Virtual, VM,
Type-A through Type-F, Type-S, Type-T, Type-X through Type-Z, Other (with free-text input)

### Field Manager (Superuser)
- Add custom hardware fields: text, number, dropdown, textarea
- Edit labels, options, placeholder on all fields including system fields
- "Other" option in dropdowns automatically shows a free-text input
- Live preview of hardware form

### Rack View
- Visual rack diagrams showing U positions and assets
- **3-level hierarchy:** Datacenter → Zone → Row
- Filter by Datacenter, Zone, and Row independently
- Edit rack details (✎ — admin/superuser), Delete empty racks (✕ — superuser)
- Click any asset in diagram to open asset detail

### Rack Fields
| Field | Description |
|-------|-------------|
| Rack ID | Unique identifier (e.g. R-01, RACK-HYD-001) |
| Datacenter | Physical datacenter or pod (e.g. HYN-POD-2) |
| Zone | Zone within the datacenter (e.g. Zone-1) |
| Row | Row within the zone (e.g. Row-1) |
| Total U | Rack height in U (default 42) |
| Notes | Optional notes |

### Stock Management
- SKU tracking: category, brand, model, spec, form factor
- Transactions: IN / OUT / ALLOCATE / RETURN / ADJUST
- Per-SKU transaction history, low stock warning (≤5 units)

### Connectivity
- Full path: Server Port → LIU-A → LIU-B → Switch Port
- Cable type, speed, VLAN, purpose

### Asset History / Audit Log
| Event | Colour |
|-------|--------|
| ASSET_CREATED | Green |
| ASSET_RELOCATED | Yellow |
| ASSET_STATUS_CHANGE | Purple |
| ASSET_UPDATED | Blue |
| ASSET_DELETED | Red |

Access via the **History** tab in any asset detail panel.

### Session Security
- Auto-logout after 10 minutes of inactivity
- 60-second warning banner with "Stay Logged In" button
- Activity tracked: mouse, keyboard, scroll, touch

### UI
- Dark mode (default) and Light mode toggle — saved in browser
- Sidebar navigation with role-aware menu items
- Toast notifications, modal forms, column chooser

---

## Export / Import

### Export
Downloads a full Excel workbook: Assets, Racks, Stock, Connectivity sheets.  
Assets sheet includes `rack_zone` and `rack_row` columns (joined from racks table).

### Import Templates
Single workbook with: Assets_Template, Stock_Template, Connectivity_Template.  
Importing assets with `rack_zone`/`rack_row` automatically creates rack records — no separate rack import needed.

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
| app_owner | | Application / asset owner |
| notes | | Free text |
| *(custom hw fields)* | | Any field_key from Field Manager |

---

## Database Migrations (Existing Installs)

All scripts are safe to run multiple times (idempotent):

```bash
# Docker
docker cp scripts/migrate-add-zone.sql    dcm_postgres:/tmp/
docker cp scripts/migrate-server-types.sql dcm_postgres:/tmp/
docker exec dcm_postgres psql -U dcuser -d dcmanager -f /tmp/migrate-add-zone.sql
docker exec dcm_postgres psql -U dcuser -d dcmanager -f /tmp/migrate-server-types.sql

# Bare metal
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

# Automated: Daily 02:00 (30d retention) + Weekly Sunday 03:00 (12w retention)
# Point your backup tool at: ./volumes/
```

### Bare Metal
```bash
# Backup
PGPASSWORD=YourPass pg_dump -U dcuser -h localhost dcmanager \
  | gzip > /opt/dc-manager/backups/manual/dcmanager_$(date +%Y%m%d_%H%M%S).sql.gz

# Restore
gunzip -c backup.sql.gz | PGPASSWORD=YourPass psql -U dcuser -h localhost dcmanager
```

---

## Offline / Air-Gapped Deployment

```bash
# Internet-connected server
./scripts/export-offline.sh

# Transfer
scp dc-manager-offline-*.tar user@offline-server:/opt/

# Offline server
cd /opt && tar -xf dc-manager-offline-*.tar && ./import-offline.sh
```

---

## API

Interactive docs: `http://your-server:3000/api/docs`

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
SERVER_IP=192.168.86.130  # Your server IP (for cert generation)
DB_USER=dcuser            # PostgreSQL username
DB_PASS=changeme123     # Password — no @ # % special chars
DB_NAME=dcmanager       # Database name
DB_HOST=postgres        # Use 'localhost' for bare metal
DB_EXTERNAL_PORT=5432   # PostgreSQL external port (Docker only)
JWT_SECRET=<32+ chars>  # Long random string for JWT signing
TOKEN_TTL_HOURS=24      # Session lifetime in hours
ALLOWED_ORIGINS=*       # CORS — use * for internal tools
```

---

## Changelog

### v3.0.0 (2026-03-13)
- Added: Connectivity table — resizable columns (drag column edge)
- Added: Connectivity table — select-all checkbox + per-row checkboxes
- Added: Connectivity table — bulk delete selected connections with confirmation
- Added: Connectivity table — sort by Server, Port Label, Switch, Cable, Speed, VLAN, Purpose (click column header)
- Added: Connectivity table — filter by Cable Type and Speed dropdowns
- Added: Connectivity table — LIU-B column toggle (column chooser parity with Assets table)
- Redesigned: Rack View — modern card layout with rounded corners, gradient headers, hover effects
- Redesigned: Rack View — DC/Zone/Row shown as colour-coded chips on each rack card (cyan/green/purple)
- Redesigned: Rack View — utilisation bar under each rack header (green → cyan gradient)
- Redesigned: Rack View — improved slot rows: taller rows, hover brightness, cleaner U number column
- Redesigned: Rack View — DC group headers with left accent bar; Zone subheaders with colour-coded border
- Redesigned: Rack View — rack legend bar (Server / Switch / LIU / PDU / Other)
- Redesigned: Rack View — full dark and light mode support for all new elements
- Added: Asset detail modal — Topology tab with draggable network diagram
- Added: Topology diagram — focal device center (★), connected nodes in arc, draggable with mouse and touch
- Added: Topology diagram — SVG edges with port labels, arrowhead markers
- Added: Topology diagram — colour-coded nodes: Server=cyan, LIU=orange, Switch=green, Other=purple
- Updated: Version bumped to v3.0.0
- Changed: Rack View — removed TYPE legend bar and SERVER GROUPS legend bar (cleaner view, colours self-evident on slots)
- Changed: Rack View — rack card width increased to 240px so hostname + serial number both display clearly on every slot
- Changed: Rack View — all slots (including 1U) now show hostname on line 1 and serial number on line 2
- Changed: Rack View — 1U slot height increased to 18px to accommodate two text lines
- Added: Dashboard KPI cards are now clickable — Total Assets/Servers → Assets page, Racks → Rack View, Connections → Connectivity, Stock SKUs/Low Stock → Stock / Parts
- Added: Rack View toolbar — search box + all filters (DC, Zone, Row, New Rack, Export) now in a single horizontal row matching the Assets page style
- Added: Rack View — search box to filter racks by ID, datacenter or zone name
- Added: Rack View — U-position numbers displayed on **both left and right** sides of every slot
- Added: Rack View — hostname-prefix colour grouping (same prefix = same colour, 12-colour palette)
- Added: Rack View — live server-group legend bar showing prefix → colour mapping
- Added: Rack View — utilisation bar colour-codes: green <60%, amber 60–85%, red >85%
- Changed: Light mode — cool slate-blue tinted palette (not blinding white), clearly readable
- Changed: All toolbars (Assets, Connectivity, Stock) — filters displayed side-by-side in a single horizontal row
- Changed: Font updated to Inter for improved readability across all pages
- Changed: Full design-token system (--radius, --shadow CSS variables)

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
- Added: Slot conflict check on manual asset add/edit — confirmation dialog with conflicting hostname and U range
- Added: Slot conflict check on import — conflicting rows skipped and counted as errors (hard fail)
- Added: `/api/assets/check-slot` endpoint — supports multi-U devices, excludes self on edit
- Fixed: Rack view Zones filter now correctly populated from `zone` field; Rows from `row_label`
- Fixed: Zones dropdown declared in HTML directly — no longer dynamically injected (was always empty on load)
- Fixed: Rack data normalisation — `row_label` containing "zone" automatically treated as zone in UI
- Fixed: Import accepts both `rack_zone`/`rack_row` and legacy `zone`/`row_label` column names

### v2.6.0 (2026-03-12)
- Added: Asset multi-select checkboxes + select-all in header
- Added: Bulk delete toolbar button — visible only when assets selected, shows count, requires confirmation
- Added: Selection clears and table refreshes after bulk delete

### v2.5.0 (2026-03-12)
- Fixed: Export rack_zone/rack_row column shift — zone was appearing in rack_row column
- Fixed: Import backwards-compatible with both new and old column names for rack zone/row

### v2.4.0 (2026-03-11)
- Fixed: Rack View crash "filterZ is not defined"
- Changed: rack_zone and rack_row merged into Assets template (no separate Racks template)
- Added: Assets import auto-creates rack records from rack_zone/rack_row
- Added: Export includes rack_zone and rack_row in Assets sheet

### v2.3.0 (2026-03-11)
- Added: Separate Datacenter, Zone, Row fields on racks (new `zone` DB column)
- Added: Rack edit (✎) and delete (✕) buttons on rack cards
- Added: 3-level rack grouping: Datacenter → Zone → Row
- Added: Three independent rack view filters (Datacenter, Zone, Row)
- Added: Rack create/edit audit logging
- Added: Racks sheet in Excel export and import
- DB migration: `scripts/migrate-add-zone.sql`

### v2.2.0 (2026-03-11)
- Added: Auto-logout after 10 min inactivity with 60s warning banner
- Added: Asset History tab — per-asset audit trail
- Added: Audit log for all asset changes (create, update, relocate, status, delete)
- Added: Resizable columns, column chooser, items-per-page, pagination in Assets table
- Fixed: Assets table column mismatch (Prov IP showing server_type data)
- Fixed: Dashboard Racks count including assets with rack references

### v2.1.0 (2026-03-10)
- Fixed: Field Manager modal crash on Add Field / Edit Opts
- Fixed: Export "Not authenticated" error
- Added: Light / Dark mode toggle (saved in browser)
- Added: PO Number, EOL Date, App Owner, Data IP, Backup IP fields
- Added: VM asset type, extended Server Type options
- Added: "Other" free-text in dropdown fields
- Renamed: Management IP → Provisioning IP, OOB IP → BMC IP

### v2.0.0 (2026-03-09)
- Production Docker stack: FastAPI + PostgreSQL + Nginx
- JWT auth with role-based access (superuser / admin / user)
- Full asset, stock, connectivity management
- Excel export and import
- Automated daily/weekly backups, offline/air-gapped deployment

### v1.0.0 (2026-03-08)
- Initial single-file localStorage prototype
