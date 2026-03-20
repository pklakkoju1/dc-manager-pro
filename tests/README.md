# DC Manager Pro — Test Suite (v3.1)

Three levels of testing — run from the `tests/` directory on any machine
that can reach your DC Manager server.

---

## Files

| File | Purpose |
|------|---------|
| `config.py` | Target URL and credentials — edit before running |
| `smoke_test.py` | Quick 30-second sanity check after every deployment |
| `test_api.py` | Full functional + integration test suite (v3.1 — covers all features) |
| `locustfile.py` | Load test with realistic user behaviour profiles |
| `requirements-test.txt` | Python dependencies |
| `reports/` | Load test HTML reports (created by Locust) |

---

## Setup (one time)

```bash
cd /appdata/dc-prod/tests

pip install -r requirements-test.txt
```

Edit `config.py` to match your server:

```python
BASE_URL   = "https://192.168.86.130"   # your server IP
ADMIN_USER = "admin"
ADMIN_PASS = "Admin@123"
```

Or pass via environment variables:

```bash
DCM_URL=https://10.0.0.50 DCM_PASS=MyPass python test_api.py
```

---

## Recommended run order

```bash
# Step 1 — quick sanity check
python smoke_test.py

# Step 2 — full functional tests
python test_api.py

# Step 3 — load test (interactive)
locust -f locustfile.py --host https://192.168.86.130
```

Or as a single command:

```bash
python smoke_test.py && \
python test_api.py && \
locust -f locustfile.py --host https://192.168.86.130 \
  --users 20 --spawn-rate 3 --run-time 3m \
  --headless --html reports/load-$(date +%Y%m%d).html
```

---

## 1. Smoke Test (~30 seconds)

Run after every deployment. Checks the app is alive before running deeper tests.

```bash
python smoke_test.py

# Against a different server:
python smoke_test.py https://10.0.0.50
```

**Checks:**
- App reachable, DB connected
- HTTP → HTTPS redirect working
- Admin login succeeds, bad password rejected
- `/api/stats`, `/api/assets`, `/api/racks`, `/api/stock`, `/api/connectivity` all return 200
- Unauthenticated request blocked (401)
- Excel export works and returns valid file
- Frontend HTML loads and contains expected content

**Expected output:**
```
DC Manager Pro — Smoke Test
Target: https://192.168.86.130

  ✓  App is reachable
  ✓  Database is connected
  ✓  HTTP redirects to HTTPS
  ✓  Admin login succeeds
  ✓  Bad password rejected (401)
  ✓  Stats endpoint OK
  ✓  Assets endpoint OK
  ✓  Racks endpoint OK
  ✓  Stock endpoint OK
  ✓  Connectivity endpoint OK
  ✓  Unauthenticated request blocked (401)
  ✓  Excel export works
  ✓  Frontend loads (200)
  ✓  Frontend has DC Manager content

────────────────────────────────────────
  Passed: 14   Failed: 0   Time: 4.2s
────────────────────────────────────────
```

---

## 2. Functional & Integration Tests (~2–3 minutes)

Tests every API endpoint with real database operations. Creates test records,
validates responses, and cleans up after itself. All test records are prefixed
`TEST-AUTO-` so they are identifiable if cleanup fails.

```bash
python test_api.py
```

### What gets tested (v3.1)

| Section | Tests |
|---------|-------|
| **1. Health** | `/api/health`, `/api/health/db` — status and DB connection |
| **2. Auth** | Valid login, wrong password, wrong username, empty credentials, token validation, pw_hash hidden, unauthenticated requests |
| **3. Stats** | All 8 fields present, correct types, unauthenticated blocked |
| **4. Racks** | Create, upsert (duplicate rack_id), update, non-existent 404, auth enforcement |
| **5. Assets** | Create, search, filter by type, get by ID, slot check (free + conflict), update, asset history, **unified full-history** (asset + parts + connectivity events), auth enforcement |
| **6. Stock + Audit** | Create, all 5 tx types (IN/OUT/ALLOCATE/RETURN/ADJUST), **ALLOCATE with `allocated_to` asset hostname**, **ASSET_PART_ALLOCATED appears in asset full-history**, **stock `/history` endpoint** (audit + tx merged), `username` in transactions, insufficient stock 400, invalid tx type 400, non-existent 404, audit log `entity=stock` filter |
| **7. Connectivity + Audit** | Create, **second connection on same server with different `src_port_label`** (dedup fix), update (switch port change), **connectivity `/history` endpoint**, **CONN_CREATED and CONN_UPDATED in history**, **connectivity events in asset full-history**, audit log `entity=connectivity` filter, auth enforcement |
| **8. Users** | Create user and admin, duplicate username 409, login as new user, user role blocked from assets/users/audit, update role, cannot delete self, auth enforcement |
| **9. HW Fields** | Create custom field, duplicate key 409, update label, cannot delete system field, auth enforcement |
| **10. Export** | Excel download, correct content-type, Content-Disposition header, non-empty file, valid XLSX magic bytes, auth enforcement |
| **11. Audit Log** | List with pagination, `total`/`items`/`limit`/`offset` structure, filter by `entity=stock`, filter by `entity=connectivity`, filter by `action=STOCK_ALLOCATE`, filter by `action=CONN_UPDATED` (validates `→` change detection in detail), search by keyword, admin can access, user role blocked, auth enforcement |
| **12. RBAC** | Admin can read all, admin can write assets and stock transactions, admin can access audit log, admin CANNOT manage users, admin CANNOT manage hw-fields, admin CANNOT delete racks |
| **13. Edge Cases** | Unknown endpoint 404, malformed JSON 422, missing required field 422, stock qty=0 no crash, very long hostname no crash, delete rack with assets 400, ALLOCATE to non-existent hostname allowed (informational field, not FK) |
| **Cleanup** | Deletes all test records in correct dependency order |

### New tests added in v3.1 (vs previous version)

| Feature | Test |
|---------|------|
| `GET /api/assets/{id}/full-history` | Entry structure, action/detail/username fields present |
| Stock `allocated_to` field | ALLOCATE sends hostname, verifies `ASSET_PART_ALLOCATED` in asset history |
| Stock `GET /api/stock/{id}/history` | Returns merged audit + transaction records |
| Stock tx `username` field | Verified in transaction history response |
| Connectivity second port | Same server, different `src_port_label` → both imported (not deduped) |
| `GET /api/connectivity/{id}/history` | Returns CONN_CREATED + CONN_UPDATED entries |
| Connectivity in asset full-history | CONN_* actions appear after creating connectivity |
| Audit `action=STOCK_ALLOCATE` filter | Filters correctly, all items have matching action |
| Audit `action=CONN_UPDATED` filter | Detail contains `→` (change detection working) |
| Admin can access audit log | Admin role returns 200, not 403 |
| Admin can do stock transactions | Admin role can POST to /api/stock/transaction |

**Expected output:**
```
════════════════════════════════════════════════════════
  Results
════════════════════════════════════════════════════════
  Passed : 110+
  Failed : 0
  Skipped: 0
  Time   : ~20s
════════════════════════════════════════════════════════
```

---

## 3. Load Test (Locust)

Simulates concurrent users to find performance bottlenecks and breaking points.

### Option A — Interactive Web UI (start here)

```bash
locust -f locustfile.py --host https://192.168.86.130
```

Open `http://localhost:8089`:
1. Set **Users**: start with 10
2. Set **Spawn rate**: 2 per second
3. Click **Start swarming**
4. Watch live RPS, response times, failure rate
5. Click **Stop** → download report from **Download Data** tab

### Option B — Headless

```bash
# Light — 10 users, 2 minutes (baseline)
locust -f locustfile.py --host https://192.168.86.130 \
  --users 10 --spawn-rate 2 --run-time 2m \
  --headless --html reports/load-light.html

# Moderate — 30 users, 5 minutes (normal production)
locust -f locustfile.py --host https://192.168.86.130 \
  --users 30 --spawn-rate 3 --run-time 5m \
  --headless --html reports/load-moderate.html

# Stress — 100 users, 10 minutes (find the limit)
locust -f locustfile.py --host https://192.168.86.130 \
  --users 100 --spawn-rate 5 --run-time 10m \
  --headless --html reports/load-stress.html

# Soak — 20 users, 30 minutes (memory leak check)
locust -f locustfile.py --host https://192.168.86.130 \
  --users 20 --spawn-rate 2 --run-time 30m \
  --headless --html reports/load-soak.html
```

### User profiles

| Type | Weight | Behaviour |
|------|--------|-----------|
| `ReadUser` | 3x | Browse assets, search, filter, rack view, dashboard stats, slot checks |
| `WriteUser` | 2x | Create/update/delete assets, stock transactions (IN/ALLOCATE/RETURN), connectivity CRUD |
| `HeavyUser` | 1x | Excel export, audit log fetch, multi-slot checks, full-dashboard refresh |

### Performance targets

| Metric | Healthy | Investigate |
|--------|---------|-------------|
| Median response time | < 200ms | > 500ms |
| 95th percentile | < 500ms | > 2000ms |
| Requests/sec | > 20 RPS | dropping under load |
| Failure rate | 0% | any failures |
| `/api/export/excel` | < 2000ms | > 5000ms |
| `/api/audit` | < 300ms | > 1000ms |

### Monitor Netdata during load test

Open `https://YOUR-IP/monitor/` (or sidebar → Monitoring → Netdata) while running:

- **dcm_backend** container — CPU/RAM, watch for sustained 100% CPU
- **dcm_postgres** — connections (should stay well below `max_connections = 100`)
- **Host RAM** — watch for steady growth (memory leak indicator)
- **Disk I/O** — spikes expected during export, sustained high = problem

---

## Interpreting Failures

### Functional test failures

| Message | Cause | Fix |
|---------|-------|-----|
| `Login failed — check credentials` | Wrong URL or password in `config.py` | Update `BASE_URL`, `ADMIN_PASS` |
| `201 → 409 on POST /api/assets` | Test data from previous failed run still in DB | Run cleanup manually or check DB |
| `ASSET_PART_ALLOCATED not in full-history` | Stock tx `allocated_to` not saved | Check `migrate-audit-v2.sql` was run |
| `CONN_UPDATED not in conn history` | Old connectivity record without audit | Only new connections after v3.1.0 are audited |
| `401 on authenticated endpoint` | Token expired mid-test | Increase `TOKEN_TTL_HOURS` in `.env` |
| `500 on any endpoint` | Server error | `docker logs dcm_backend --tail 50` |
| `Connection refused` | App not running | `docker ps` and `docker compose up -d` |

### If cleanup fails (test records remain in DB)

```bash
# Find test records
docker exec dcm_postgres psql -U dcuser -d dcmanager \
  -c "SELECT hostname FROM assets WHERE hostname LIKE 'TEST-AUTO-%';"

# Manual cleanup
docker exec dcm_postgres psql -U dcuser -d dcmanager \
  -c "DELETE FROM connectivity WHERE src_hostname LIKE 'TEST-AUTO-%';"
docker exec dcm_postgres psql -U dcuser -d dcmanager \
  -c "DELETE FROM assets WHERE hostname LIKE 'TEST-AUTO-%';"
docker exec dcm_postgres psql -U dcuser -d dcmanager \
  -c "DELETE FROM stock WHERE model LIKE 'TEST-AUTO-%';"
docker exec dcm_postgres psql -U dcuser -d dcmanager \
  -c "DELETE FROM racks WHERE rack_id LIKE 'TEST-AUTO-%';"
docker exec dcm_postgres psql -U dcuser -d dcmanager \
  -c "DELETE FROM users WHERE username LIKE 'test-auto-%';"
```

### Load test failures

```bash
# Backend errors during load test
docker logs dcm_backend --tail 50 -f

# Check DB connection count
docker exec dcm_postgres psql -U dcuser -d dcmanager \
  -c "SELECT count(*) FROM pg_stat_activity;"

# Live resource usage
docker stats
```

---

## Prerequisites check

Before running tests confirm:

```bash
# App is running
docker ps | grep -E "dcm_postgres|dcm_backend|dcm_frontend"

# API is healthy
curl -k https://YOUR-IP/api/health

# DB migration was applied (required for v3.1 audit tests)
docker exec dcm_postgres psql -U dcuser -d dcmanager \
  -c "\d audit_log" | grep related_entity
# Should show: related_entity | text

docker exec dcm_postgres psql -U dcuser -d dcmanager \
  -c "\d stock_transactions" | grep allocated_to
# Should show: allocated_to | text
```

If `related_entity` or `allocated_to` columns are missing, run the migration:

```bash
docker cp scripts/migrate-audit-v2.sql dcm_postgres:/tmp/
docker exec dcm_postgres psql -U dcuser -d dcmanager \
  -f /tmp/migrate-audit-v2.sql
```
