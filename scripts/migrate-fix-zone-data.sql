-- Migration: Fix racks where zone value was stored in row_label before zone column existed
-- Only moves row_label → zone when zone is NULL and row_label looks like a zone (e.g. Zone-1, Zone-8)
-- Run on existing installs:
-- docker cp scripts/migrate-fix-zone-data.sql dcm_postgres:/tmp/
-- docker exec dcm_postgres psql -U dcuser -d dcmanager -f /tmp/migrate-fix-zone-data.sql

-- Preview what will be moved (safe to run first)
SELECT rack_id, datacenter, zone, row_label,
       'row_label → zone' as action
FROM racks
WHERE zone IS NULL
  AND row_label IS NOT NULL
  AND row_label ILIKE '%zone%';

-- Apply: move row_label into zone where zone is empty and row_label contains 'zone'
UPDATE racks
SET zone = row_label,
    row_label = NULL
WHERE zone IS NULL
  AND row_label IS NOT NULL
  AND row_label ILIKE '%zone%';

-- Verify final state
SELECT rack_id, datacenter, zone, row_label FROM racks ORDER BY datacenter, zone, row_label;
