-- DC Manager Pro — PostgreSQL Schema
-- Run once on first deploy; idempotent via IF NOT EXISTS

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
-- SEED DATA (only if tables are empty)
-- ══════════════════════════════════════════════════

-- Default users (passwords: Admin@123, Super@123, Viewer@123 — SHA-256 hashed)
INSERT INTO users (name, username, pw_hash, role, email, dept)
SELECT 'Super Administrator','superuser',
    encode(digest('Super@123','sha256'),'hex'),
    'superuser','superuser@datacenter.local','DC Operations'
WHERE NOT EXISTS (SELECT 1 FROM users WHERE username='superuser');

INSERT INTO users (name, username, pw_hash, role, email, dept)
SELECT 'DC Admin','admin',
    encode(digest('Admin@123','sha256'),'hex'),
    'admin','admin@datacenter.local','IT Management'
WHERE NOT EXISTS (SELECT 1 FROM users WHERE username='admin');

INSERT INTO users (name, username, pw_hash, role, email, dept)
SELECT 'Read Only Viewer','viewer',
    encode(digest('Viewer@123','sha256'),'hex'),
    'user','viewer@datacenter.local','Monitoring'
WHERE NOT EXISTS (SELECT 1 FROM users WHERE username='viewer');

-- Default hardware fields
INSERT INTO hw_fields (field_key,label,field_type,placeholder,options,required,sort_order,is_system)
SELECT 'server_type','Server Type','select','Rack Server, Tower, Blade…',
    'Rack Server'||chr(10)||'Tower'||chr(10)||'Blade'||chr(10)||'Dense Server'||chr(10)||'High-Density'||chr(10)||'Virtual',
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

-- Sample racks
INSERT INTO racks (rack_id,datacenter,row_label,total_u)
VALUES ('R-01','DC1-Mumbai','A',42),('R-02','DC1-Mumbai','A',42),('R-10','DC1-Mumbai','B',42)
ON CONFLICT (rack_id) DO NOTHING;

-- Sample assets
INSERT INTO assets (hostname,asset_type,status,server_type,datacenter,rack_id,u_start,u_height,mgmt_ip,oob_ip,asset_tag,serial_number,notes,hw_data)
VALUES ('web-prod-01','Server','Online','Rack Server','DC1-Mumbai','R-01',10,2,'192.168.10.11','10.0.1.11','TAG-001','SN100001','Primary web server',
    '{"make":"Dell","model":"PowerEdge R750","cpu":"2x Xeon Gold 6348 / 56c","ram":"256 GB DDR4 ECC","stor":"4x 1.92TB NVMe","os":"Ubuntu 22.04","nports":4,"pspd":"25G"}')
ON CONFLICT (hostname) DO NOTHING;

INSERT INTO assets (hostname,asset_type,status,server_type,datacenter,rack_id,u_start,u_height,mgmt_ip,oob_ip,asset_tag,serial_number,notes,hw_data)
VALUES ('db-prod-01','Server','Online','Rack Server','DC1-Mumbai','R-01',12,2,'192.168.10.12','10.0.1.12','TAG-002','SN100002','PostgreSQL primary',
    '{"make":"HPE","model":"ProLiant DL380 Gen10","cpu":"2x Xeon Silver 4316","ram":"512 GB DDR4 ECC","stor":"8x 960GB SSD","os":"RHEL 8.6","nports":4,"pspd":"25G"}')
ON CONFLICT (hostname) DO NOTHING;

INSERT INTO assets (hostname,asset_type,status,datacenter,rack_id,u_start,u_height,mgmt_ip,asset_tag,serial_number,hw_data)
VALUES ('core-sw-01','Switch','Online','DC1-Mumbai','R-02',1,1,'192.168.1.1','TAG-010','SN200001',
    '{"make":"Cisco","model":"Nexus 9348GC","os":"NX-OS 9.3","nports":48,"pspd":"100G"}')
ON CONFLICT (hostname) DO NOTHING;

INSERT INTO assets (hostname,asset_type,status,datacenter,rack_id,u_start,u_height,mgmt_ip,asset_tag,serial_number,hw_data)
VALUES ('LIU-02','LIU','Online','DC1-Mumbai','R-02',4,1,NULL,'TAG-020','SN300001',
    '{"make":"Panduit","model":"FWME2"}')
ON CONFLICT (hostname) DO NOTHING;

INSERT INTO assets (hostname,asset_type,status,datacenter,rack_id,u_start,u_height,mgmt_ip,asset_tag,serial_number,hw_data)
VALUES ('LIU-10','LIU','Online','DC1-Mumbai','R-10',4,1,NULL,'TAG-021','SN300002',
    '{"make":"Panduit","model":"FWME2"}')
ON CONFLICT (hostname) DO NOTHING;

-- Sample stock
INSERT INTO stock (category,brand,model,spec,form_factor,interface,total_qty,avail_qty,alloc_qty,unit_cost,storage_loc)
VALUES
('NVMe','Samsung','PM9A3','1.92TB','U.2','NVMe PCIe 4.0',20,14,6,32000,'Shelf A-1'),
('SSD','Micron','5400 Pro','960GB','2.5"','SATA III',30,22,8,8500,'Shelf A-2'),
('HDD','Seagate','Exos X18','18TB','3.5"','SAS 12G',24,18,6,22000,'Shelf A-3'),
('RAM','Samsung','M393A8G40BB4','64GB DDR4-3200 RDIMM','RDIMM','DDR4',40,28,12,14000,'Shelf B-1'),
('RAM','Kingston','KSM32RD4/32','32GB DDR4-3200 RDIMM','RDIMM','DDR4',60,4,56,7500,'Shelf B-2'),
('NIC','Intel','X710-DA4','4-port 10GbE SFP+','PCIe x8','10GbE',10,7,3,28000,'Cabinet 1'),
('Disk Clip','Dell','R750-HDD-Tray','2.5" to 3.5" drive tray','Other','Other',50,38,12,800,'Shelf C-1'),
('Transceiver','Cisco','SFP-10G-SR','10G SFP+ SR 850nm','SFP+','10GbE',20,5,15,3500,'Cabinet 2')
ON CONFLICT DO NOTHING;

-- Sample connectivity
INSERT INTO connectivity (src_hostname,src_slot,src_port,src_port_label,liu_a_rack,liu_a_hostname,liu_a_port,liu_b_rack,liu_b_hostname,liu_b_port,dst_hostname,dst_port,cable_type,speed,vlan,purpose)
VALUES
('web-prod-01','slot1','port1','slot1port1','R-02','LIU-02','port5','R-10','LIU-10','port5','core-sw-01','Gi1/0/10','Fiber SM','10G','100','Data'),
('web-prod-01','slot1','port2','slot1port2','R-02','LIU-02','port6','R-10','LIU-10','port6','core-sw-01','Gi1/0/11','Fiber SM','10G','200','Management'),
('db-prod-01','slot1','port1','slot1port1','R-02','LIU-02','port7','R-10','LIU-10','port7','core-sw-01','Gi1/0/12','Fiber SM','25G','100','Data')
ON CONFLICT DO NOTHING;
