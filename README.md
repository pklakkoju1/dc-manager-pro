# DC Manager Pro — v2.4.0

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
│   ├── main.py               ← FastAPI app, all API routes
│   ├── init.sql              ← PostgreSQL schema (no demo data)
│   └── requirements.txt
├── frontend/
│   ├── Dockerfile
│   └── index.html            ← Full SPA
├── nginx/
│   └── nginx.conf
├── scripts/
│   ├── entrypoint-backup.sh      ← Backup container entrypoint
│   ├── manual-backup.sh          ← Run a manual backup
│   ├── restore.sh                ← Restore from backup
│   ├── export-offline.sh         ← Bundle for air-gapped servers
│   ├── import-offline.sh         ← Install on air-gapped servers
│   ├── migrate-volumes.sh        ← Migrate from named to local volumes
│   ├── migrate-server-types.sql  ← Update server_type options on existing installs
│   └── migrate-add-zone.sql      ← Add zone column to racks (existing installs)
├── volumes/                      ← ALL persistent data (back this up!)
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
- **Network fields:** Provisioning IP (Prov IP), BMC IP (iDRAC/iLO/IPMI), Data IP, Backup IP, MAC, VLAN, Additional IPs
- **Hardware fields:** Fully configurable via Field Manager (Superuser only)
- **Asset History:** Full audit trail per asset — tracks creation, status changes, rack moves, hardware changes
- Inline connectivity entry from asset form
- Export/Import via Excel

### Asset Table
- Resizable columns (drag column edge)
- Column chooser (toggle which columns are visible)
- Items per page: 50 / 100 / All
- Pagination with page navigation
- Filter by Type and Status

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
- Each rack card shows Datacenter · Zone · Row as subtitle
- Filter by Datacenter, Zone, and Row independently
- Edit rack details inline (✎ button — admin/superuser)
- Delete empty racks (✕ button — superuser only; blocked if rack has assets)
- Click any asset in rack diagram to open asset detail

### Rack Fields
| Field | Description |
|-------|-------------|
| Rack ID | Unique identifier (e.g. R-01, INHYDNARF1NR218) |
| Datacenter | Physical datacenter or pod (e.g. HYN-POD-2) |
| Zone | Zone within the datacenter (e.g. Zone-1) |
| Row | Row within the zone (e.g. Row-1) |
| Total U | Rack height in U (default 42) |
| Notes | Optional notes |

### Stock Management
- SKU tracking with category, brand, model, spec, form factor
- Transactions: IN / OUT / ALLOCATE / RETURN / ADJUST
- Per-SKU transaction history
- Low stock warning (≤5 units)

### Connectivity
- Full path tracking: Server Port → LIU-A → LIU-B → Switch Port
- Cable type, speed, VLAN, purpose

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
- Dark mode (default) and Light mode toggle — saved in browser
- Light mode: clean white theme with professional blue accents
- Sidebar navigation with role-aware menu items
- Toast notifications, modal forms, table search/filter
- Version and developer credit in sidebar footer

---

## Export / Import

### Export (Download)
Downloads a full Excel workbook with all data across sheets:
- **Assets** — all assets with all fields including rack_zone and rack_row
- **Racks** — all racks with datacenter, zone, row
- **Stock** — all stock items
- **Connectivity** — all cabling records

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

Run these on existing installs when upgrading — safe to run multiple times:

```bash
# Add zone column to racks table (v2.3.0+)
docker cp scripts/migrate-add-zone.sql dcm_postgres:/tmp/
docker exec dcm_postgres psql -U dcuser -d dcmanager -f /tmp/migrate-add-zone.sql

# Update server_type options (v2.1.0+)
docker cp scripts/migrate-server-types.sql dcm_postgres:/tmp/
docker exec dcm_postgres psql -U dcuser -d dcmanager -f /tmp/migrate-server-types.sql
```

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

Interactive docs: `http://your-server:3000/api/docs`

| Endpoint | Method | Auth | Description |
|----------|--------|------|-------------|
| `/api/auth/login` | POST | None | Login → JWT |
| `/api/auth/me` | GET | Any | Current user |
| `/api/stats` | GET | Any | Dashboard stats |
| `/api/assets` | GET/POST | Any/Write | List/create assets |
| `/api/assets/{id}` | GET/PUT/DELETE | Any/Write | Asset CRUD |
| `/api/assets/{id}/history` | GET | Any | Asset audit history |
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
- Added: Server Type options Type-A to Type-F, Type-S, Type-T, Type-X to Type-Z
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
