-- Migration: Add zone column to racks table
-- Run on existing installs:
-- docker exec dcm_postgres psql -U dcuser -d dcmanager -f /tmp/migrate-add-zone.sql

ALTER TABLE racks ADD COLUMN IF NOT EXISTS zone TEXT;

-- Verify
SELECT rack_id, datacenter, zone, row_label, total_u FROM racks ORDER BY datacenter, zone, row_label;
