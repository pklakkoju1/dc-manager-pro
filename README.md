<div align="center">

# 🖥️ DC Manager Pro

[![version](https://img.shields.io/badge/version-3.0.1-38bdf8?style=flat-square&labelColor=0a0a0f)](.)
[![python](https://img.shields.io/badge/Python-3.12-3776ab?style=flat-square&logo=python&logoColor=white&labelColor=0a0a0f)](.)
[![fastapi](https://img.shields.io/badge/FastAPI-0.111-009688?style=flat-square&logo=fastapi&logoColor=white&labelColor=0a0a0f)](.)
[![postgres](https://img.shields.io/badge/PostgreSQL-16-336791?style=flat-square&logo=postgresql&logoColor=white&labelColor=0a0a0f)](.)
[![docker](https://img.shields.io/badge/Docker-Compose-2496ed?style=flat-square&logo=docker&logoColor=white&labelColor=0a0a0f)](.)
[![nginx](https://img.shields.io/badge/Nginx-1.25-009900?style=flat-square&logo=nginx&logoColor=white&labelColor=0a0a0f)](.)
[![license](https://img.shields.io/badge/license-MIT-22c55e?style=flat-square&labelColor=0a0a0f)](.)

**A self-hosted, ultra-modern Datacenter Infrastructure Management (DCIM) platform.**  
Track assets, visualise racks, manage cabling, monitor stock — all in one beautiful UI.

[Features](#-features) · [Quick Start](#-quick-start) · [Usage Guide](#-usage-guide) · [API](#-api) · [Changelog](#-changelog)

---

</div>

## ✨ Features

| | Feature | Description |
|-|---------|-------------|
| 🖥️ | **Asset Management** | Track servers, switches, LIUs, PDUs, VMs and more with full hardware fields |
| 📊 | **Rack View** | Visual rack diagrams with hostname/serial per slot, prefix colour-coding, utilisation bars |
| 🔌 | **Connectivity** | Full cable path tracking: Server → LIU-A → LIU-B → Switch with speed/VLAN/purpose |
| 📦 | **Stock / Parts** | Spare parts inventory with transaction history and low-stock alerts |
| 📤 | **Excel Export/Import** | Bulk export all data, import from templates, export rack layout to Excel |
| 🔍 | **Search & Filter** | Real-time search + multi-filter on every page, resizable & sortable columns |
| 👥 | **Role-Based Access** | Superuser / Admin / Viewer roles with fine-grained permissions |
| 🔐 | **Secure** | JWT auth, bcrypt passwords, HTTPS/TLS 1.3, auto-logout on inactivity |
| 🌙 | **Dark / Light Mode** | Glassmorphism dark mode + clean slate-blue light mode |
| 📜 | **Audit Trail** | Full per-asset history log — every change recorded with user, time and detail |
| 🔧 | **Field Manager** | Add custom hardware fields to asset forms without touching code |
| 🐳 | **Docker-first** | One-command deploy, automated backups, air-gapped support |

---

## 🚀 Quick Start

### Prerequisites

```bash
# Install Docker Engine (Ubuntu/Debian)
curl -fsSL https://get.docker.com | sh
sudo usermod -aG docker $USER && newgrp docker
docker --version && docker compose version
```

### Deploy in 5 Steps

```bash
# 1. Extract the release zip
unzip dc-manager-production.zip && cd dc-prod

# 2. Configure environment
cp .env.example .env && nano .env
# Required: DB_PASS (no @ # % chars)  |  JWT_SECRET (32+ random chars)

# 3. Create volume directories
mkdir -p volumes/postgres volumes/backups/daily volumes/backups/weekly volumes/backups/manual

# 4. Generate SSL certificate
./scripts/generate-certs.sh 192.168.86.130   # ← your server IP

# 5. Start
docker compose up -d --build
sleep 30 && curl -k https://localhost/api/health
```

> **Open:** `https://YOUR-SERVER-IP`  
> **Default login:** `admin` / `Admin@123` — **change immediately!**

### Update (no data loss)

```bash
cd /appdata/dc-prod
# Drop in new index.html / main.py, then:
docker compose up -d --build frontend backend
```

---

## 📖 Usage Guide

### 🔐 Authentication & Roles

| Role | Capabilities |
|------|-------------|
| **Superuser** | Full access — users, permissions, all data, delete anything |
| **Admin** | Create/edit/delete assets, racks, stock, connectivity |
| **Viewer** | Read-only — view everything, export data |

- Session auto-expires after inactivity — a warning banner appears 60s before logout
- Click **Stay Logged In** to extend the session
- Manage users at **Admin → Users** (superuser only)

---

### ◈ Dashboard

Home screen showing datacenter health at a glance.

**Clickable KPI cards** — tap any card to navigate directly:

| Card | Navigates to |
|------|-------------|
| Total Assets | All Assets |
| Servers | All Assets |
| Racks | Rack View |
| Connections | Connectivity |
| Stock SKUs | Stock / Parts |
| Low Stock | Stock / Parts |

- **Assets by Type** — bar chart breakdown by asset type
- **Stock Summary** — inventory by category with fill bars
- **Recent Assets** — last 8 modified assets with hostname, type and rack location

---

### ◻ All Assets

Full inventory table for every physical and virtual asset.

**Toolbar:**
```
[ Search hostname/IP/serial/rack ]  [ All Types ▾ ]  [ All Status ▾ ]  [ 50/pg ▾ ]  [ ⊞ Cols ]
```

**Table features:**
- 🔍 Real-time search across hostname, IP, serial, rack
- ↕️ Click any column header to sort (toggle asc/desc)
- ↔️ Drag column edges to resize
- ☑️ Row checkboxes + select-all for bulk delete
- 🗂️ Toggle optional columns: Data IP, Backup IP, App Owner, etc.
- 📄 Pagination with configurable page size

**Asset fields:**

| Section | Fields |
|---------|--------|
| Identity | Hostname, Asset Type, Status, Server Type |
| Location | Datacenter, Rack ID, U Start, U Height |
| Network | Prov IP, BMC IP *(clickable link → opens `https://ip`)*, Data IP, Backup IP, MAC, VLAN |
| Hardware | Make, Model, Serial No, Asset Tag, PO Number, EOL Date, App Owner |
| Custom | Any fields defined in Field Manager |

**Asset detail panel** (click any hostname):
- **Info tab** — all fields in clean read view, IP links open in new tab
- **History tab** — full audit trail: every change with user, timestamp and old→new values
- **Topology tab** — draggable network diagram showing cable paths to switches/LIUs

---

### ▤ Rack View

Visual rack diagrams — see exactly what's in every U position.

**Reading a rack card:**

```
┌─ R-PROD-01 ──────────────────────── 18/42U  ✎ ✕ ─┐
│ [HYD-POD]  [Zone-1]  [Row Row-1]               │
├────────────────────────────────────────────────────┤
│ ████████░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ 43%          │
├───┬─────────────────────────────────┬───┤
│42 │  —                              │42 │  (empty)
│36 │  webappserver01 / SN12345       │36 │  (server)
│32 │  databaseserver01 / SN123456    │32 │  (server)
└───┴─────────────────────────────────┴───┘
```

**Colour coding — servers with the same hostname prefix share a colour:**
- `HYNRBBMPRUPICAS01–10` → one colour (e.g. sky blue)
- `HYNRBBMPRUPIK8S01–N` → different colour (e.g. emerald)
- Switches/Routers/Firewalls → green
- LIU / Patch Panels → orange
- PDUs → amber

**Utilisation bar** colours automatically:
- 🟢 Green — < 60% full
- 🟡 Amber — 60–85% full
- 🔴 Red — > 85% full

**Toolbar:**
```
[ Search racks ]  [ All Datacenters ▾ ]  [ All Zones ▾ ]  [ All Rows ▾ ]  [ + New Rack ]  [ ↓ Export Rack ]
```

**Export Rack to Excel** produces a `.xlsx` with:
- *Rack Assets* sheet — one row per asset: hostname, serial, BMC IP, Mgmt IP, make, model, PO number
- *Full U Layout* sheet — every U position including empty slots for physical audit

---

### ◫ Stock / Parts

Spare parts inventory tracker.

**Per item:** Category, Brand, Model, Spec, Form factor, Interface, Total/Available/Allocated qty, Location, Unit cost

**Actions:**
- `+` / `−` buttons record stock transactions (in/out movements)
- Every transaction is logged
- Items with ≤5 available units are flagged as **Low Stock** in the sidebar and dashboard

---

### ⇄ Connectivity

Full physical cable path tracking.

**Path model:**
```
Server (hostname / slot / port)
  → LIU-A (rack / hostname / port)
    → LIU-B (rack / hostname / port)   [optional]
      → Switch (hostname / port)
```

**Per record:** Cable type, Speed, VLAN, Purpose  
**Toolbar:** Search + filter by cable type + filter by speed + bulk delete  
**Sort:** Click any column header  
**Topology:** Click an asset → Topology tab → see draggable visual path diagram

---

### ↓ Export / Import

| Action | Details |
|--------|---------|
| **Export All** | `.xlsx` with Assets, Stock and Connectivity sheets — all fields included |
| **Export Rack View** | Rack layout with hostname/serial/IP/make/model for audit |
| **Import** | Upload a filled `.xlsx` — select sheet type (Assets / Stock / Connectivity) |
| **Templates** | Download blank templates with correct headers and example rows |

Import rules:
- Row 1 = header row (do not modify headers)
- IDs auto-generated on import — leave ID column blank
- Duplicate hostnames on import → update existing record
- Invalid rows are skipped and reported in the result summary

---

### ⚙️ Field Manager *(Superuser)*

Add custom fields to the Asset Hardware tab — no code changes required.

- Types: Text, Number, Date, Select (with options)
- Mark fields as Required or Optional
- System fields (Make, Model, Serial, etc.) are locked and cannot be removed

---

## 🏗️ Tech Stack

| Layer | Technology |
|-------|-----------|
| **Backend** | Python 3.12 · FastAPI · asyncpg · Uvicorn |
| **Database** | PostgreSQL 16 |
| **Frontend** | Vanilla JS (SPA) · Inter font · JetBrains Mono |
| **Proxy** | Nginx 1.25 (HTTPS, TLS 1.2/1.3) |
| **Container** | Docker · Docker Compose v2 |
| **Excel** | openpyxl (backend) · SheetJS (frontend) |
| **Auth** | JWT (python-jose) · bcrypt (passlib) |

---

## 🐳 Docker Reference

```bash
# View logs
docker logs dcm_backend  --tail 50 -f
docker logs dcm_frontend --tail 20

# Shell access
docker exec -it dcm_backend  bash
docker exec -it dcm_postgres psql -U dcuser -d dcmanager

# Stop / start (data preserved)
docker compose stop
docker compose start

# Full rebuild (⚠ wipes all data)
docker compose down --volumes && rm -rf volumes/postgres/*
docker compose up -d --build

# Manual backup
./scripts/manual-backup.sh

# Restore from backup
./scripts/restore.sh backups/manual/backup_file.sql.gz
```

---

## 🔒 HTTPS / SSL

```bash
# Generate self-signed cert (valid 10 years)
./scripts/generate-certs.sh YOUR-SERVER-IP

# App is served on port 443 — HTTP (80) auto-redirects to HTTPS
# Accept the browser security warning for self-signed certs
# See README → HTTPS section for CA-signed cert instructions
```

---

## 🔑 Environment Variables

```env
SERVER_IP=192.168.86.130   # Your server IP
DB_USER=dcuser             # PostgreSQL username
DB_PASS=changeme123        # No @ # % special chars
DB_NAME=dcmanager          # Database name
DB_HOST=postgres           # 'localhost' for bare metal
JWT_SECRET=<32+ chars>     # Long random string
TOKEN_TTL_HOURS=24         # Session lifetime
ALLOWED_ORIGINS=*          # CORS — use * for internal tools
```

---

## 🌐 API

Interactive docs: `https://your-server/api/docs`

| Endpoint | Method | Auth | Description |
|----------|--------|------|-------------|
| `/api/auth/login` | POST | None | Login → JWT token |
| `/api/auth/me` | GET | Any | Current user info |
| `/api/stats` | GET | Any | Dashboard statistics |
| `/api/assets` | GET/POST | Any/Write | List or create assets |
| `/api/assets/{id}` | GET/PUT/DELETE | Any/Write | Asset CRUD |
| `/api/assets/{id}/history` | GET | Any | Asset audit trail |
| `/api/assets/check-slot` | GET | Any | Check rack slot availability |
| `/api/racks` | GET/POST | Any/Write | List or create racks |
| `/api/racks/{id}` | PUT/DELETE | Write/Super | Edit or delete rack |
| `/api/stock` | GET/POST/PUT/DELETE | Any/Write | Stock CRUD |
| `/api/stock/transaction` | POST | Write | Record stock movement |
| `/api/connectivity` | GET/POST/PUT/DELETE | Any/Write | Connectivity CRUD |
| `/api/users` | GET/POST/PUT/DELETE | Superuser | User management |
| `/api/hw-fields` | GET/POST/PUT/DELETE | Super/Any | Custom field management |
| `/api/export/excel` | GET | Any | Export all data to Excel |
| `/api/import/excel?sheet=X` | POST | Write | Bulk import from Excel |
| `/api/audit` | GET | Superuser | Full audit log |
| `/api/health` | GET | None | Health check |

---

## 📦 Directory Structure

```
dc-prod/
├── backend/
│   ├── main.py              FastAPI app — all routes, JWT auth, business logic
│   ├── init.sql             DB schema + default admin user
│   ├── requirements.txt
│   └── Dockerfile
├── frontend/
│   ├── index.html           Single-page app (~2700 lines)
│   └── Dockerfile
├── nginx/
│   └── nginx.conf           HTTPS, TLS 1.2/1.3, HTTP→HTTPS redirect
├── certs/                   SSL certificate (generated by script)
├── scripts/
│   ├── generate-certs.sh    Generate self-signed SSL cert
│   ├── manual-backup.sh     Trigger manual database backup
│   ├── restore.sh           Restore from backup file
│   ├── export-offline.sh    Package app for air-gapped deploy
│   ├── import-offline.sh    Import on air-gapped server
│   └── migrate-*.sql        Database migration scripts
├── volumes/
│   ├── postgres/            PostgreSQL data (persistent)
│   └── backups/             Daily/weekly/manual backups
├── docker-compose.yml
├── .env.example
└── README.md
```

---

## 💾 Backup & Restore

```bash
# Docker — backups run automatically (daily + weekly via cron)
# Manual backup
docker exec dcm_postgres pg_dump -U dcuser dcmanager | gzip > backup.sql.gz

# Restore
gunzip -c backup.sql.gz | docker exec -i dcm_postgres psql -U dcuser dcmanager

# Using scripts
./scripts/manual-backup.sh
./scripts/restore.sh volumes/backups/manual/backup_file.sql.gz
```

---

## 🛠️ Database Migrations

Run these when upgrading an existing install:

```bash
# Add zone column (v2.3+)
docker cp scripts/migrate-add-zone.sql dcm_postgres:/tmp/
docker exec dcm_postgres psql -U dcuser -d dcmanager -f /tmp/migrate-add-zone.sql

# Update server types (v2.1+)
docker cp scripts/migrate-server-types.sql dcm_postgres:/tmp/
docker exec dcm_postgres psql -U dcuser -d dcmanager -f /tmp/migrate-server-types.sql
```

---

## 📋 Default Credentials

| Field | Value |
|-------|-------|
| Username | `admin` |
| Password | `Admin@123` |
| URL | `https://YOUR-SERVER-IP` |

> ⚠️ **Change the default password immediately after first login.**

---

## 📜 Changelog

### v3.0.1 — 2026-03-14
> UI polish release — glassmorphism design system, improved rack readability

- **New:** Full glassmorphism UI — frosted glass sidebar, topbar, KPI cards, modals, rack cards, toasts
- **New:** Ultra-modern zinc/slate dark palette (`#0a0a0f` base, `rgba` whisper borders)
- **New:** Ambient background gradient canvas (sky/violet/emerald radial gradients)
- **New:** Glass inputs — `backdrop-filter` on all form fields, focus glow rings
- **New:** Pill-shaped badges and tags across all tables and history view
- **New:** Gradient primary button with glow shadow on hover
- **New:** Rack hostname/serial on one line (`HOSTNAME / SERIAL`) — compact, readable
- **New:** BMC IP clickable link in asset table and detail panel (`https://ip` opens in new tab)
- **New:** Prov IP, Data IP, Backup IP also clickable in asset detail panel
- **Fixed:** Toolbar no longer scrolls — uses `flex-wrap` gracefully within available width
- **Fixed:** Rack slot hostname colours now adapt correctly in light mode (dark text on tinted bg)
- **Changed:** Rack header — DC name on line 1, Zone + Row chips side by side on line 2
- **Changed:** Light mode — cool slate-blue palette replaces blinding white
- **Changed:** Scrollbar — 4px ultra-thin, near-invisible

---

### v3.0.0 — 2026-03-13
> Major feature release — connectivity overhaul, rack redesign, topology view

- **New:** Connectivity table — resizable columns, sort, select-all, bulk delete, cable/speed filters
- **New:** Asset detail — Topology tab with draggable SVG network diagram
- **New:** Rack View — hostname-prefix colour grouping (same prefix = same colour, 12-colour palette)
- **New:** Rack View — U numbers on both left and right sides of every slot
- **New:** Rack View — utilisation bar (green/amber/red based on fill %)
- **New:** Rack View — DC/Zone/Row as colour-coded chips on rack card header
- **New:** Rack View — Export to Excel (Rack Assets + Full U Layout sheets)
- **New:** Rack View — search box, all toolbar controls in single horizontal row
- **New:** Dashboard KPI cards are clickable — navigate directly to section
- **New:** Rack slot shows `hostname / serial` on single line
- **Changed:** Full design-token CSS system (`--radius`, `--shadow`, `--glass`, `--blur`)
- **Changed:** Font updated to Inter
- **Changed:** All toolbars horizontal (Assets, Connectivity, Stock, Rack View)

---

### v2.8.0 — 2026-03-13
- **New:** HTTPS/TLS 1.2/1.3 — app served on port 443, HTTP redirects automatically
- **New:** `scripts/generate-certs.sh` — 10-year self-signed SSL cert
- **New:** HSTS header for enhanced security
- **Changed:** Nginx SSL hardening, docker-compose ports 443+80 (replaces APP_PORT 3000)

---

### v2.7.0 — 2026-03-12
- **New:** Slot conflict check on add/edit — warns if U position is occupied
- **New:** Slot conflict check on import — conflicting rows skipped and reported
- **Fixed:** Rack zones/rows filters correctly populated
- **Fixed:** Import accepts both new and legacy column names

---

### v2.6.0 — 2026-03-12
- **New:** Asset multi-select checkboxes + bulk delete with confirmation

---

### v2.5.0 — 2026-03-12
- **Fixed:** Export rack_zone/rack_row column shift
- **Fixed:** Import backwards-compatible with old and new column names

---

### v2.4.0 — 2026-03-11
- **Fixed:** Rack View crash on filter
- **New:** Assets import auto-creates rack records from rack_zone/rack_row

---

### v2.3.0 — 2026-03-11
- **New:** Datacenter → Zone → Row 3-level rack hierarchy
- **New:** Rack edit and delete buttons, audit logging
- **New:** Racks sheet in Excel export/import
- **DB:** `migrate-add-zone.sql`

---

### v2.2.0 — 2026-03-11
- **New:** Auto-logout (10 min) with 60s warning banner
- **New:** Per-asset history/audit trail tab
- **New:** Resizable columns, column chooser, pagination in Assets table

---

### v2.1.0 — 2026-03-10
- **New:** Light / Dark mode toggle
- **New:** PO Number, EOL Date, App Owner, Data IP, Backup IP fields
- **New:** VM asset type, extended server type options
- **Fixed:** Field Manager crash, Export auth error

---

### v2.0.0 — 2026-03-09
- Production Docker stack: FastAPI + PostgreSQL + Nginx
- JWT auth with role-based access
- Full asset, stock, connectivity management
- Excel export/import, automated backups, air-gapped deployment

---

### v1.0.0 — 2026-03-08
- Initial single-file localStorage prototype

---

## 📄 License

```
MIT License — Copyright (c) 2026 pklakkoju

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software to use, copy, modify, merge, publish, distribute, sublicense,
and/or sell copies, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND.
```

---

<div align="center">

**DC Manager Pro** · Built by pklakkoju · MIT License

</div>
