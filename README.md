# ⬡ DC Manager Pro

<div align="center">

![Version](https://img.shields.io/badge/version-1.0.0-00c8ff?style=flat-square)
![Python](https://img.shields.io/badge/Python-3.12-3776AB?style=flat-square&logo=python&logoColor=white)
![FastAPI](https://img.shields.io/badge/FastAPI-0.111-009688?style=flat-square&logo=fastapi&logoColor=white)
![PostgreSQL](https://img.shields.io/badge/PostgreSQL-16-4169E1?style=flat-square&logo=postgresql&logoColor=white)
![Docker](https://img.shields.io/badge/Docker-Compose-2496ED?style=flat-square&logo=docker&logoColor=white)
![Nginx](https://img.shields.io/badge/Nginx-1.25-009639?style=flat-square&logo=nginx&logoColor=white)
![License](https://img.shields.io/badge/license-MIT-green?style=flat-square)

**Production-ready Datacenter Asset Management platform.**  
Track servers, racks, cabling, and spare parts — with role-based access control, persistent PostgreSQL storage, and automated backups.

[Quick Start](#-quick-start) · [Features](#-features) · [Roles](#-role-based-access-control) · [Backup & Restore](#-backup--restore) · [API](#-api-reference) · [Bare-metal](#-bare-metal--vm-deployment)

</div>

---

## ✨ Features

| Module | Capabilities |
|--------|-------------|
| **Assets** | Full CRUD for servers, switches, routers, firewalls, LIUs, PDUs. Custom hardware fields (admin-configurable). Server Type field. Rack U-slot positioning. |
| **Rack View** | Visual U-slot diagrams per rack. Color-coded by asset type. Click-through to asset detail. |
| **Connectivity** | Full 4-hop path: `Server → LIU-A → LIU-B → Switch`. Port-level cable tracking with speed, VLAN, and purpose. |
| **Stock / Parts** | SSD, NVMe, HDD, RAM, NIC, Disk Clips, Transceivers and more. Stock transactions: IN / OUT / ALLOCATE / RETURN / ADJUST. Low-stock alerts. |
| **Export / Import** | Styled Excel export (Assets + Stock + Connectivity). Blank import templates with example rows. Drag-and-drop Excel import. |
| **Users** | Superuser manages all users and roles. Full CRUD with email and department. |
| **Field Manager** | Superuser adds/removes custom hardware fields (text, number, dropdown, textarea). System fields are locked. |
| **Auth** | JWT-based login. Role-enforced API. Session persists on refresh. Rate-limited login endpoint. |

---

## 🏗 Architecture

```
Browser
  │
  ▼
┌─────────────────────────────────────────────────┐
│  Nginx  :80   — Static SPA + Reverse Proxy      │
│  Rate limiting · Security headers · Gzip        │
└──────────────┬──────────────────────────────────┘
               │  /api/*
               ▼
┌──────────────────────────────────────────────────┐
│  FastAPI  :8000  (internal only)                 │
│  JWT auth · REST API · Excel export/import       │
└──────────────┬───────────────────────────────────┘
               │
               ▼
┌──────────────────────────────────────────────────┐
│  PostgreSQL 16  — Persistent named volume        │
│  Auto-backup container  →  ./backups/            │
└──────────────────────────────────────────────────┘
```

**Tech stack:**
- **Frontend** — Vanilla HTML/CSS/JS SPA (no framework, zero build step)
- **Backend** — Python 3.12 + FastAPI + asyncpg (async PostgreSQL driver)
- **Database** — PostgreSQL 16 with full schema, indexes, and seed data
- **Proxy** — Nginx 1.25 with rate limiting and security headers
- **Auth** — HS256 JWT (no external dependencies)

---

## 🚀 Quick Start

### Prerequisites
- Docker 24+ and Docker Compose v2

### 1 — Clone & Configure

```bash
git clone https://github.com/YOUR_USERNAME/dc-manager-pro.git
cd dc-manager-pro

cp .env.example .env
```

Open `.env` and set at minimum:

```env
DB_PASS=your_strong_database_password_here

# Generate with: python3 -c "import secrets; print(secrets.token_hex(32))"
JWT_SECRET=your_generated_32char_secret_here
```

### 2 — Build & Run

```bash
docker compose up -d --build
```

First boot takes ~60 seconds as PostgreSQL initializes and seeds data.

### 3 — Open the App

```
http://localhost:3000
```

### Default Login Credentials

| Role | Username | Password | Access Level |
|------|----------|----------|--------------|
| **Superuser** | `superuser` | `Super@123` | Full access — users, fields, everything |
| **Admin** | `admin` | `Admin@123` | Read + Write — assets, stock, connectivity |
| **User** | `viewer` | `Viewer@123` | Read-only + Excel export |

> ⚠️ **Change all passwords immediately after first login via the Users section.**

---

## 🔐 Role-Based Access Control

| Permission | Superuser | Admin | User |
|------------|:---------:|:-----:|:----:|
| View assets, racks, stock, connectivity | ✓ | ✓ | ✓ |
| Add / Edit / Delete assets | ✓ | ✓ | — |
| Manage stock & transactions | ✓ | ✓ | — |
| Add / Edit connectivity | ✓ | ✓ | — |
| Import from Excel | ✓ | ✓ | — |
| Export to Excel | ✓ | ✓ | ✓ |
| Manage users | ✓ | — | — |
| Add / remove hardware fields | ✓ | — | — |
| View permissions matrix | ✓ | — | — |

---

## 📦 Project Structure

```
dc-manager-pro/
├── docker-compose.yml          ← Orchestrates all services
├── .env.example                ← Copy to .env and configure
├── .gitignore
├── README.md
│
├── backend/
│   ├── Dockerfile              ← Python 3.12-slim
│   ├── main.py                 ← FastAPI app — all routes, auth, export/import
│   ├── init.sql                ← PostgreSQL schema + indexes + seed data
│   └── requirements.txt
│
├── frontend/
│   ├── Dockerfile              ← Nginx serving static files
│   └── index.html              ← Full SPA — all UI in one file
│
├── nginx/
│   └── nginx.conf              ← Reverse proxy, rate limiting, security headers
│
└── scripts/
    ├── backup.sh               ← Runs daily at 02:00 AM via cron container
    ├── manual-backup.sh        ← One-click manual backup
    └── restore.sh              ← Interactive restore from .sql.gz file
```

---

## 💾 Backup & Restore

### Automated Backups

The `backup` container runs a cron job every day at **02:00 AM** automatically.

```
backups/
├── daily/    ← Last 30 days  (dcmanager_YYYY-MM-DD_HHMMSS.sql.gz)
└── weekly/   ← Last 12 weeks (dcmanager_weekYYYY-WW.sql.gz)
```

### Manual Backup

```bash
# Via helper script
./scripts/manual-backup.sh

# Or directly
docker exec dcm_postgres pg_dump -U dcuser dcmanager \
  | gzip > backups/manual/dcmanager_$(date +%Y%m%d_%H%M%S).sql.gz
```

### Restore

```bash
# Interactive restore (confirms before overwriting)
./scripts/restore.sh backups/daily/dcmanager_2025-01-15_020001.sql.gz
```

### Offsite / Cloud Backup

```bash
# Rsync to remote server (add to crontab)
rsync -az ./backups/ user@backup-server:/backups/dcmanager/

# AWS S3
aws s3 sync ./backups/ s3://your-bucket/dcmanager/

# Rclone (works with GCS, Azure Blob, Backblaze B2, etc.)
rclone sync ./backups/ remote:dcmanager-backups
```

---

## 🖥 Bare-Metal / VM Deployment

For environments without Docker:

### 1 — Install Dependencies

```bash
# Ubuntu 22.04 / Debian 12
sudo apt update && sudo apt install -y python3.12 python3.12-venv postgresql-16 nginx

# RHEL 9 / Rocky 9 / AlmaLinux 9
sudo dnf install -y python3.12 postgresql-server postgresql-contrib nginx
sudo postgresql-setup --initdb && sudo systemctl enable --now postgresql
```

### 2 — Database

```bash
sudo -u postgres psql << 'SQL'
CREATE USER dcuser WITH PASSWORD 'your_password';
CREATE DATABASE dcmanager OWNER dcuser;
GRANT ALL PRIVILEGES ON DATABASE dcmanager TO dcuser;
SQL

sudo -u postgres psql -d dcmanager < backend/init.sql
```

### 3 — Python Backend (systemd service)

```bash
cd backend
python3.12 -m venv venv && source venv/bin/activate
pip install -r requirements.txt

sudo tee /etc/systemd/system/dcmanager.service << 'EOF'
[Unit]
Description=DC Manager Pro API
After=network.target postgresql.service

[Service]
Type=simple
User=www-data
WorkingDirectory=/opt/dc-manager-pro/backend
Environment="DATABASE_URL=postgresql://dcuser:your_password@localhost:5432/dcmanager"
Environment="JWT_SECRET=your_32char_jwt_secret"
Environment="TOKEN_TTL_HOURS=24"
ExecStart=/opt/dc-manager-pro/backend/venv/bin/uvicorn main:app \
          --host 127.0.0.1 --port 8000 --workers 2
Restart=always
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF

sudo systemctl daemon-reload && sudo systemctl enable --now dcmanager
```

### 4 — Nginx

```bash
sudo cp nginx/nginx.conf /etc/nginx/conf.d/dcmanager.conf
sudo mkdir -p /var/www/dcmanager
sudo cp frontend/index.html /var/www/dcmanager/

# Update root path in config
sudo sed -i 's|/usr/share/nginx/html|/var/www/dcmanager|' \
  /etc/nginx/conf.d/dcmanager.conf

sudo nginx -t && sudo systemctl reload nginx
```

---

## 🔒 HTTPS / SSL

### Let's Encrypt (public domain)

```bash
sudo apt install certbot python3-certbot-nginx
sudo certbot --nginx -d dcmanager.yourcompany.com
```

### Self-signed (internal / intranet)

```bash
sudo openssl req -x509 -nodes -days 3650 -newkey rsa:2048 \
  -keyout /etc/nginx/ssl/dcmanager.key \
  -out    /etc/nginx/ssl/dcmanager.crt \
  -subj "/CN=dcmanager.local/O=YourCompany/C=IN"
```

Then add to your `nginx.conf` server block:
```nginx
listen 443 ssl;
ssl_certificate     /etc/nginx/ssl/dcmanager.crt;
ssl_certificate_key /etc/nginx/ssl/dcmanager.key;
ssl_protocols       TLSv1.2 TLSv1.3;
ssl_ciphers         HIGH:!aNULL:!MD5;
```

---

## 📡 API Reference

All endpoints require `Authorization: Bearer <token>` except `/api/auth/login` and `/api/health`.

| Method | Endpoint | Role | Description |
|--------|----------|------|-------------|
| `POST` | `/api/auth/login` | — | Login → JWT token |
| `GET` | `/api/auth/me` | Any | Current user info |
| `GET` | `/api/stats` | Any | Dashboard statistics |
| `GET` `POST` | `/api/assets` | Any / Write | List / create assets |
| `GET` `PUT` `DELETE` | `/api/assets/{id}` | Any / Write | Get / update / delete |
| `GET` `POST` | `/api/racks` | Any / Write | List / create racks |
| `GET` `POST` | `/api/stock` | Any / Write | List / create stock |
| `PUT` `DELETE` | `/api/stock/{id}` | Write | Update / delete stock |
| `POST` | `/api/stock/transaction` | Write | IN / OUT / ALLOCATE / RETURN / ADJUST |
| `GET` | `/api/stock/{id}/transactions` | Any | Transaction history |
| `GET` `POST` | `/api/connectivity` | Any / Write | List / create connections |
| `PUT` `DELETE` | `/api/connectivity/{id}` | Write | Update / delete |
| `GET` `POST` `PUT` `DELETE` | `/api/users` | Superuser | Full user management |
| `GET` `POST` `DELETE` | `/api/hw-fields` | Superuser | Hardware field management |
| `GET` | `/api/export/excel` | Any | Download full Excel export |
| `POST` | `/api/import/excel?sheet=Assets` | Write | Bulk import from Excel |
| `GET` | `/api/health` | — | Health check (for load balancers) |

> Interactive API docs available at `http://your-server:3000/api/docs`

---

## 🛡 Security Checklist

Before going to production:

- [ ] Changed `DB_PASS` from default
- [ ] Generated a unique `JWT_SECRET` (32+ characters)
- [ ] Changed **all three** default user passwords after first login
- [ ] Set `ALLOWED_ORIGINS` to your specific domain (not `*`)
- [ ] Removed or blocked `DB_EXTERNAL_PORT` (set to empty `""` in `.env`)
- [ ] Enabled HTTPS / SSL
- [ ] Configured firewall — only ports 80/443 open to public
- [ ] Tested backup restore at least once

---

## 🔧 Operations

### View Logs

```bash
docker compose logs -f               # all services
docker compose logs -f backend       # API only
docker compose logs -f db            # database only
```

### Update Application

```bash
git pull
docker compose up -d --build
```

### Stop / Start

```bash
docker compose stop        # stop, keep data
docker compose start       # start again
docker compose down        # remove containers (volume data preserved)
docker compose down -v     # ⚠️ WIPES ALL DATA — only for full reset
```

### Direct Database Access

```bash
docker exec -it dcm_postgres psql -U dcuser dcmanager
```

---

## 📋 Excel Import Format

Download blank templates from the app (Export & Import → Download Blank Templates).

### Assets Sheet

| Column | Required | Description |
|--------|----------|-------------|
| `hostname` | ✓ | Unique server/device name |
| `asset_type` | ✓ | Server, Switch, Router, Firewall, LIU, PDU, etc. |
| `status` | | Online, Offline, Maintenance, Decommissioned, Spare |
| `server_type` | | Rack Server, Tower, Blade, Dense Server, Virtual |
| `datacenter` | | Datacenter name/code |
| `rack_id` | | Must match a rack ID |
| `u_start` | | Starting U position |
| `u_height` | | Height in U slots |
| `mgmt_ip` | | Management IP address |
| `oob_ip` | | OOB / IPMI / iDRAC IP |
| `asset_tag` | | Physical asset tag |
| `serial_number` | | Device serial number |
| + custom fields | | Any fields added via Field Manager |

### Stock Sheet

| Column | Required | Description |
|--------|----------|-------------|
| `category` | ✓ | SSD, NVMe, HDD, RAM, NIC, Disk Clip, etc. |
| `brand` | | Samsung, Dell, Kingston… |
| `model` | | 870 EVO, PM9A3… |
| `spec` | | 2TB, 64GB DDR4-3200… |
| `form_factor` | | 2.5", M.2 2280, RDIMM, SFP+… |
| `interface` | | SATA III, NVMe PCIe 4.0, DDR4… |
| `total_qty` | | Total units in stock |
| `available_qty` | | Available (not allocated) units |
| `location` | | Physical location (Shelf A-3, Cabinet 2…) |
| `unit_cost` | | Cost per unit in ₹ |

### Connectivity Sheet

| Column | Required | Description |
|--------|----------|-------------|
| `src_hostname` | ✓ | Source server hostname |
| `src_slot` | | Source slot (slot1) |
| `src_port` | | Source port (port1) |
| `src_port_label` | | Combined label (slot1port1) |
| `liu_a_rack` | | LIU-A rack ID |
| `liu_a_hostname` | | LIU-A device hostname |
| `liu_a_port` | | LIU-A port |
| `liu_b_rack` | | LIU-B rack ID |
| `liu_b_hostname` | | LIU-B device hostname |
| `liu_b_port` | | LIU-B port |
| `dst_hostname` | | Destination switch hostname |
| `dst_port` | | Destination switch port (Gi1/0/10) |
| `cable_type` | | Fiber SM, Fiber MM, CAT6, DAC, AOC… |
| `speed` | | 1G, 10G, 25G, 40G, 100G |
| `vlan` | | VLAN ID |
| `purpose` | | Data, Management, Storage, Heartbeat, BMC/IPMI |

---

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch: `git checkout -b feat/your-feature`
3. Commit your changes: `git commit -m 'feat: add some feature'`
4. Push to the branch: `git push origin feat/your-feature`
5. Open a Pull Request

---

## 📄 License

MIT License — free to use, modify, and distribute.

---

<div align="center">
Built for datacenter operations teams who need a simple, self-hosted, no-subscription asset tracker.
</div>
