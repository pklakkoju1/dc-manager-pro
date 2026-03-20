-- ══════════════════════════════════════════════════════════════
-- DC Manager Pro — Migration: Full Audit Trail for Stock & Connectivity
-- Run on existing installs:
--   docker cp scripts/migrate-audit-v2.sql dcm_postgres:/tmp/
--   docker exec dcm_postgres psql -U dcuser -d dcmanager -f /tmp/migrate-audit-v2.sql
-- ══════════════════════════════════════════════════════════════

-- ── 1. Add linked-entity columns to audit_log ──────────────────
-- These allow linking an audit entry to a related entity
-- e.g. a stock transaction linked to the asset it was allocated to
ALTER TABLE audit_log
    ADD COLUMN IF NOT EXISTS related_entity    TEXT,
    ADD COLUMN IF NOT EXISTS related_entity_id TEXT;

-- Index for fast lookup: "all audit entries related to asset X"
CREATE INDEX IF NOT EXISTS idx_audit_related
    ON audit_log(related_entity, related_entity_id);

-- ── 2. Add allocated_to column to stock_transactions ──────────────
-- Records which asset a part was allocated to (hostname)
ALTER TABLE stock_transactions
    ADD COLUMN IF NOT EXISTS allocated_to TEXT;   -- asset hostname

-- Index for fast lookup: "all parts allocated to asset X"
CREATE INDEX IF NOT EXISTS idx_stx_allocated
    ON stock_transactions(allocated_to);

-- ── 3. Add username column to stock_transactions ─────────────────
-- Records who made the transaction
ALTER TABLE stock_transactions
    ADD COLUMN IF NOT EXISTS username TEXT;

-- ── Done ──────────────────────────────────────────────────────────
DO $$ BEGIN
    RAISE NOTICE 'Migration complete: audit_log now tracks stock and connectivity changes';
    RAISE NOTICE 'stock_transactions now tracks allocated_to (asset hostname) and username';
END $$;
