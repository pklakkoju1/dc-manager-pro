-- DC Manager Pro — PostgreSQL Schema
-- Clean version: no demo data, no sample assets/stock/connectivity
-- Only schema + system hardware fields are seeded

CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- ── Users ──────────────────────────────────────────
CREATE TABLE IF NOT EXISTS users (
    id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name        TEXT NOT NULL,
    username    TEXT NOT NULL UNIQUE,
    pw_hash     TEXT NOT NULL,
    role        TEXT NOT NULL DEFAULT 'user' CHECK (role IN ('user','admin','superuser')),
    email       TEXT,
    dept        TEXT,
    active      BOOLEAN NOT NULL DEFAULT true,
    last_login  TIMESTAMPTZ,
    created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ── Racks ──────────────────────────────────────────
CREATE TABLE IF NOT EXISTS racks (
    id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    rack_id     TEXT NOT NULL UNIQUE,
    datacenter  TEXT,
    zone        TEXT,
    row_label   TEXT,
    total_u     INT NOT NULL DEFAULT 42,
    notes       TEXT,
    created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ── Assets ─────────────────────────────────────────
CREATE TABLE IF NOT EXISTS assets (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    hostname        TEXT NOT NULL UNIQUE,
    asset_type      TEXT NOT NULL DEFAULT 'Server',
    status          TEXT NOT NULL DEFAULT 'Online'
                        CHECK (status IN ('Online','Offline','Maintenance','Decommissioned','Spare')),
    server_type     TEXT,
    datacenter      TEXT,
    rack_id         TEXT,
    u_start         INT,
    u_height        INT NOT NULL DEFAULT 1,
    mgmt_ip         TEXT,
    oob_ip          TEXT,
    mac_addr        TEXT,
    vlan            TEXT,
    extra_ips       TEXT,
    asset_tag       TEXT,
    serial_number   TEXT,
    notes           TEXT,
    hw_data         JSONB NOT NULL DEFAULT '{}',
    created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at      TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
CREATE INDEX IF NOT EXISTS idx_assets_rack   ON assets(rack_id);
CREATE INDEX IF NOT EXISTS idx_assets_status ON assets(status);
CREATE INDEX IF NOT EXISTS idx_assets_type   ON assets(asset_type);
CREATE INDEX IF NOT EXISTS idx_assets_dc     ON assets(datacenter);

-- ── Stock ──────────────────────────────────────────
CREATE TABLE IF NOT EXISTS stock (
    id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    category    TEXT NOT NULL,
    brand       TEXT,
    model       TEXT,
    spec        TEXT,
    form_factor TEXT,
    interface   TEXT,
    total_qty   INT NOT NULL DEFAULT 0,
    avail_qty   INT NOT NULL DEFAULT 0,
    alloc_qty   INT NOT NULL DEFAULT 0,
    unit_cost   NUMERIC(12,2),
    storage_loc TEXT,
    notes       TEXT,
    created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at  TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
CREATE INDEX IF NOT EXISTS idx_stock_cat ON stock(category);

-- ── Stock Transactions ─────────────────────────────
CREATE TABLE IF NOT EXISTS stock_transactions (
    id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    stock_id    UUID NOT NULL REFERENCES stock(id) ON DELETE CASCADE,
    tx_type     TEXT NOT NULL CHECK (tx_type IN ('IN','OUT','ALLOCATE','RETURN','ADJUST')),
    qty         INT NOT NULL,
    reference   TEXT,
    notes       TEXT,
    created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
CREATE INDEX IF NOT EXISTS idx_stx_stock ON stock_transactions(stock_id);

-- ── Connectivity ───────────────────────────────────
CREATE TABLE IF NOT EXISTS connectivity (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    src_hostname    TEXT,
    src_slot        TEXT,
    src_port        TEXT,
    src_port_label  TEXT,
    liu_a_rack      TEXT,
    liu_a_hostname  TEXT,
    liu_a_port      TEXT,
    liu_b_rack      TEXT,
    liu_b_hostname  TEXT,
    liu_b_port      TEXT,
    dst_hostname    TEXT,
    dst_port        TEXT,
    cable_type      TEXT,
    speed           TEXT,
    vlan            TEXT,
    purpose         TEXT,
    notes           TEXT,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at      TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
CREATE INDEX IF NOT EXISTS idx_conn_src ON connectivity(src_hostname);
CREATE INDEX IF NOT EXISTS idx_conn_dst ON connectivity(dst_hostname);

-- ── HW Fields ──────────────────────────────────────
CREATE TABLE IF NOT EXISTS hw_fields (
    id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    field_key   TEXT NOT NULL UNIQUE,
    label       TEXT NOT NULL,
    field_type  TEXT NOT NULL DEFAULT 'text' CHECK (field_type IN ('text','number','select','textarea')),
    placeholder TEXT,
    options     TEXT,
    required    BOOLEAN NOT NULL DEFAULT false,
    sort_order  INT NOT NULL DEFAULT 100,
    is_system   BOOLEAN NOT NULL DEFAULT false,
    created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ── Audit Log ──────────────────────────────────────
CREATE TABLE IF NOT EXISTS audit_log (
    id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id     UUID,
    username    TEXT,
    action      TEXT NOT NULL,
    entity      TEXT,
    entity_id   TEXT,
    detail      TEXT,
    ip_addr     TEXT,
    created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
CREATE INDEX IF NOT EXISTS idx_audit_user   ON audit_log(user_id);
CREATE INDEX IF NOT EXISTS idx_audit_entity ON audit_log(entity, entity_id);

-- ══════════════════════════════════════════════════
-- SYSTEM HARDWARE FIELDS (always seeded — not demo data)
-- These define the hardware form structure, required by the app
-- ══════════════════════════════════════════════════
INSERT INTO hw_fields (field_key,label,field_type,placeholder,options,required,sort_order,is_system)
SELECT 'server_type','Server Type','select','Rack Server, Tower, Blade…',
    'Rack Server'||chr(10)||'Tower'||chr(10)||'Blade'||chr(10)||'Dense Server'||chr(10)||'High-Density'||chr(10)||'Virtual'||chr(10)||'VM'||chr(10)||'Type-A'||chr(10)||'Type-B'||chr(10)||'Type-C'||chr(10)||'Type-D'||chr(10)||'Type-E'||chr(10)||'Type-F'||chr(10)||'Type-S'||chr(10)||'Type-T'||chr(10)||'Type-X'||chr(10)||'Type-Y'||chr(10)||'Type-Z'||chr(10)||'Other',
    false,10,true
WHERE NOT EXISTS (SELECT 1 FROM hw_fields WHERE field_key='server_type');

INSERT INTO hw_fields (field_key,label,field_type,placeholder,required,sort_order,is_system)
VALUES ('make','Make / Vendor','text','Dell, HPE, Cisco…',false,20,true)
ON CONFLICT (field_key) DO NOTHING;

INSERT INTO hw_fields (field_key,label,field_type,placeholder,required,sort_order,is_system)
VALUES ('model','Model','text','PowerEdge R750',false,30,true)
ON CONFLICT (field_key) DO NOTHING;

INSERT INTO hw_fields (field_key,label,field_type,placeholder,required,sort_order,is_system)
VALUES ('cpu','CPU','text','2x Xeon Gold 6348 / 56c',false,40,true)
ON CONFLICT (field_key) DO NOTHING;

INSERT INTO hw_fields (field_key,label,field_type,placeholder,required,sort_order,is_system)
VALUES ('ram','RAM','text','256 GB DDR4 ECC',false,50,true)
ON CONFLICT (field_key) DO NOTHING;

INSERT INTO hw_fields (field_key,label,field_type,placeholder,required,sort_order,is_system)
VALUES ('stor','Storage Config','text','4x 1.92TB NVMe SSD',false,60,true)
ON CONFLICT (field_key) DO NOTHING;

INSERT INTO hw_fields (field_key,label,field_type,placeholder,required,sort_order,is_system)
VALUES ('os','OS / Firmware','text','Ubuntu 22.04 LTS',false,70,true)
ON CONFLICT (field_key) DO NOTHING;

INSERT INTO hw_fields (field_key,label,field_type,placeholder,required,sort_order,is_system)
VALUES ('nports','Number of Ports','number','48',false,80,true)
ON CONFLICT (field_key) DO NOTHING;

INSERT INTO hw_fields (field_key,label,field_type,placeholder,required,sort_order,is_system)
VALUES ('pspd','Port Speed','text','10G / 25G / 100G',false,90,true)
ON CONFLICT (field_key) DO NOTHING;

-- ══════════════════════════════════════════════════
-- FIRST RUN: Create default superuser ONLY if no users exist
-- Username: admin  Password: Admin@123
-- ⚠ CHANGE THIS PASSWORD immediately after first login!
-- ══════════════════════════════════════════════════
INSERT INTO users (name, username, pw_hash, role, email, dept)
SELECT
    'Administrator',
    'admin',
    encode(digest('Admin@123','sha256'),'hex'),
    'superuser',
    'admin@company.local',
    'IT'
WHERE NOT EXISTS (SELECT 1 FROM users LIMIT 1);
