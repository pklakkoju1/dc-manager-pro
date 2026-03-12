# DC Manager Pro — v2.3.9

**Production Datacenter Asset Management Platform**  
Developed by **pklakkoju**

---

## Stack

| Component | Technology |
|-----------|------------|
| Frontend  | Single-page HTML/JS/CSS (Nginx) |
| Backend   | FastAPI (Python 3.12) |
| Database  | PostgreSQL 16 |
| Proxy     | Nginx 1.25 |
| Backups   | Automated daily cron (postgres:alpine) |

---

## Quick Start

```bash
cp .env.example .env
nano .env            # Set DB_PASS and JWT_SECRET (avoid @ # % in password)
docker compose up -d --build
# Open: http://YOUR-SERVER-IP:3000
# Login: admin / Admin@123  ← change immediately!
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
│   ├── main.py           ← FastAPI app, all API routes
│   ├── init.sql          ← PostgreSQL schema (no demo data)
│   └── requirements.txt
├── frontend/
│   ├── Dockerfile
│   └── index.html        ← Full SPA
├── nginx/
│   └── nginx.conf
├── scripts/
│   ├── entrypoint-backup.sh    ← Backup container entrypoint
│   ├── manual-backup.sh        ← Run a manual backup
│   ├── restore.sh              ← Restore from backup
│   ├── export-offline.sh       ← Bundle for air-gapped servers
│   ├── import-offline.sh       ← Install on air-gapped servers
│   ├── migrate-volumes.sh      ← Migrate from named to local volumes
│   └── migrate-server-types.sql← Update server_type options on existing installs
├── volumes/                    ← ALL persistent data (back this up!)
│   ├── postgres/               ← PostgreSQL data files
│   └── backups/
│       ├── daily/              ← Auto daily backups (retained 30 days)
│       ├── weekly/             ← Auto weekly backups (retained 12 weeks)
│       └── manual/             ← Manual backups
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
- **Asset fields:** Hostname, Type, Status, Datacenter, Rack ID, U Position
- **Identity fields:** Asset Tag, Serial Number, PO Number, EOL Date, App/Asset Owner
- **Network fields:** Provisioning IP (Prov IP), BMC IP (iDRAC/iLO/IPMI), Data IP, Backup IP, MAC, VLAN, Additional IPs
- **Hardware fields:** Configurable via Field Manager (Superuser only)
- Inline connectivity entry from asset form
- Export/Import via Excel

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

### Stock Management
- SKU tracking with category, brand, model, spec, form factor
- Transactions: IN / OUT / ALLOCATE / RETURN / ADJUST
- Per-SKU transaction history
- Low stock warning (≤5 units)

### Connectivity
- Full path tracking: Server Port → LIU-A → LIU-B → Switch Port
- Cable type, speed, VLAN, purpose

### UI
- Dark mode (default) and Light mode toggle (saved in browser)
- Light mode: clean white theme with professional blue accents
- Sidebar navigation with role-aware menu items
- Toast notifications, modal forms, table search/filter

---

## Backup & Restore

```bash
# Manual backup
./scripts/manual-backup.sh
# Output: volumes/backups/manual/dcmanager_manual_YYYYMMDD_HHMMSS.sql.gz

# Restore
./scripts/restore.sh volumes/backups/daily/dcmanager_2026-03-09_020001.sql.gz

# Auto backups
# Daily at 02:00 AM → volumes/backups/daily/  (30 day retention)
# Weekly Sunday 03:00 → volumes/backups/weekly/ (12 week retention)
```

**Backup solution integration:** Point your backup tool to:
```
/appdata/dc-prod/volumes/
```

---

## Offline / Air-Gapped Deployment

```bash
# On internet server — create bundle
./scripts/export-offline.sh

# Transfer bundle to offline server
scp dc-manager-offline-*.tar user@offline-server:/opt/

# On offline server
cd /opt && tar -xf dc-manager-offline-*.tar
./import-offline.sh
```

---

## API

Interactive docs available at: `http://your-server:3000/api/docs`

| Endpoint | Method | Auth | Description |
|----------|--------|------|-------------|
| `/api/auth/login` | POST | None | Login → JWT |
| `/api/auth/me` | GET | Any | Current user |
| `/api/stats` | GET | Any | Dashboard stats |
| `/api/assets` | GET/POST | Any/Write | List/create assets |
| `/api/assets/{id}` | GET/PUT/DELETE | Any/Write | Asset CRUD |
| `/api/racks` | GET/POST | Any/Write | Rack management |
| `/api/stock` | GET/POST/PUT/DELETE | Any/Write | Stock CRUD |
| `/api/stock/transaction` | POST | Write | Stock transaction |
| `/api/connectivity` | GET/POST/PUT/DELETE | Any/Write | Connectivity CRUD |
| `/api/users` | GET/POST/PUT/DELETE | Superuser | User management |
| `/api/hw-fields` | GET/POST/PUT/DELETE | Super/Any | Field management |
| `/api/export/excel` | GET | Any | Export all data |
| `/api/import/excel?sheet=X` | POST | Write | Bulk import |
| `/api/health` | GET | None | Health check |

---

## Environment Variables (.env)

```env
APP_PORT=3000           # Web UI port
DB_USER=dcuser          # PostgreSQL username
DB_PASS=changeme123     # PostgreSQL password (avoid @ # % symbols)
DB_NAME=dcmanager       # Database name
DB_EXTERNAL_PORT=5432   # PostgreSQL external port
JWT_SECRET=<32+ chars>  # JWT signing secret
TOKEN_TTL_HOURS=24      # Session duration
ALLOWED_ORIGINS=*       # CORS origins
```

---

## Changelog

### v2.1.0 (2026-03-10)
- Fixed: Field Manager "Add Field" and "Edit Opts" buttons not opening modal (null element crash)
- Fixed: Export returning "Not authenticated" (was using window.location without auth header)
- Added: Light mode with clean white/blue professional theme
- Added: Dark/Light mode toggle button in sidebar (preference saved in browser)
- Added: PO Number, EOL Date, App/Asset Owner fields in asset General tab
- Added: Data IP and Backup IP (BKUP IP) fields in asset Network tab
- Added: VM option to asset Type dropdown
- Renamed: Management IP → Provisioning IP (Prov IP)
- Renamed: OOB/IPMI IP → BMC IP (iDRAC / iLO / IPMI)
- Added: Server Type options Type-A to Type-F, Type-S, Type-T, Type-X to Type-Z
- Added: "Other" option in dropdown fields shows free-text input box
- Added: Superuser can now edit options on all fields including system fields
- Added: Version display (v2.1.0) and developer credit in sidebar footer
- Removed: Demo credentials block from login page

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
