# DC Manager Pro — Test Suite

Three levels of testing — run from the `tests/` directory.

---

## Setup (one time)

```bash
# On any machine that can reach your DC Manager server (not necessarily the server itself)
cd /appdata/dc-prod/tests

pip install -r requirements-test.txt
```

Edit `config.py` if your server IP or credentials differ from the defaults:

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

## 1. Smoke Test — run after every deployment (~30 seconds)

Checks the app is alive: health, login, core endpoints, HTTPS redirect, frontend.

```bash
python smoke_test.py

# Against a specific server:
python smoke_test.py https://10.0.0.50
```

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

## 2. Functional & Integration Tests — full test suite (~2-3 minutes)

Tests every API endpoint, all CRUD operations, role enforcement, business logic,
edge cases, and cleanup. Creates and deletes real test records in your database.

```bash
python test_api.py
```

**What gets tested:**

| Section | Tests |
|---------|-------|
| Health | `/api/health`, `/api/health/db` |
| Auth | Login, wrong password, expired token, `/api/auth/me` |
| Stats | All fields present, correct types |
| Racks | Create, upsert, update, delete, 404 on missing |
| Assets | Create, search, filter, get by ID, check-slot (free + conflict), update, history, delete |
| Stock | Create, all 5 transaction types (IN/OUT/ALLOCATE/RETURN/ADJUST), insufficient stock error, invalid type error, transaction history |
| Connectivity | Create, search, update, delete |
| Users | Create, duplicate username, login as new user, role enforcement, update, cannot delete self |
| HW Fields | Create, duplicate key, update, cannot delete system field |
| Export | Excel download, correct content-type, valid XLSX bytes |
| Audit Log | List, limit, entity filter, non-superuser blocked |
| RBAC | Admin can read/write, cannot manage users/fields, cannot delete racks |
| Edge Cases | Unknown endpoint 404, malformed JSON 422, missing required field |
| Cleanup | Deletes all TEST- prefixed records |

```bash
# Example output:
══════════════════════════════════════════════════════
  5. Assets
══════════════════════════════════════════════════════
  ✓  GET /api/assets → 200
  ✓  GET /api/assets returns list
  ✓  GET /api/assets?q= search returns list
  ✓  GET /api/assets?type=Server → 200
  ✓  POST /api/assets create → 201
  ✓  Asset has correct hostname
  ✓  Asset has correct status
  ✓  Asset has correct rack
  ✓  Asset has correct u_start
  ✓  Asset has id field
  ...
══════════════════════════════════════════════════════
  Results
══════════════════════════════════════════════════════
  Passed : 98
  Failed : 0
  Skipped: 0
  Time   : 18.4s
══════════════════════════════════════════════════════
```

---

## 3. Load Test (Locust) — performance and concurrency testing

Simulates multiple concurrent users hitting the API. Identifies performance
bottlenecks, slow endpoints, and breaking points.

### Install Locust (included in requirements-test.txt)
```bash
pip install locust
```

### Option A — Interactive Web UI (recommended for first run)

```bash
cd tests/
locust -f locustfile.py --host https://192.168.86.130
```

Open `http://localhost:8089` in your browser:
1. Set number of users (start with **10**)
2. Set spawn rate (users per second, start with **2**)
3. Click **Start swarming**
4. Watch live RPS, response times, and failure rate
5. Click **Stop** when done
6. Download the report from the **Download Data** tab

### Option B — Headless (CI / automated)

```bash
# Light test — 10 users, 2 minutes
locust -f locustfile.py \
  --host https://192.168.86.130 \
  --users 10 \
  --spawn-rate 2 \
  --run-time 2m \
  --headless \
  --html reports/load-test-light.html

# Moderate test — 30 users, 5 minutes
locust -f locustfile.py \
  --host https://192.168.86.130 \
  --users 30 \
  --spawn-rate 3 \
  --run-time 5m \
  --headless \
  --html reports/load-test-moderate.html

# Stress test — ramp to 100 users
locust -f locustfile.py \
  --host https://192.168.86.130 \
  --users 100 \
  --spawn-rate 5 \
  --run-time 10m \
  --headless \
  --html reports/load-test-stress.html
```

### User profiles in the load test

| User type | Weight | Behaviour |
|-----------|--------|-----------|
| `ReadUser` | 3x | Browse assets, search, view racks, dashboard stats |
| `WriteUser` | 2x | Create/update/delete assets, stock transactions |
| `HeavyUser` | 1x | Excel export, audit log, multi-slot checks |

### What to look for

| Metric | Healthy | Investigate |
|--------|---------|-------------|
| Median response time | < 200ms | > 500ms |
| 95th percentile | < 500ms | > 2000ms |
| Requests/sec | > 20 RPS | dropping under load |
| Failure rate | 0% | any failures |
| `/api/export/excel` | < 2000ms | > 5000ms |

### Monitoring during load test

Watch the Netdata dashboard at `http://192.168.86.130:19999` while the load test runs:

- **CPU** — should stay below 80%
- **RAM** — watch for steady growth (memory leak)
- **PostgreSQL connections** — should stay below `max_connections`
- **dcm_backend container** — CPU spikes are normal, sustained 100% is not
- **dcm_postgres container** — disk I/O and query rate

### Recommended test sequence

1. **Smoke test first** — confirm app is healthy before load testing
2. **Functional tests** — confirm all endpoints work correctly
3. **Light load test** — 10 users, 2 min — baseline performance
4. **Moderate load test** — 30 users, 5 min — normal production load
5. **Stress test** — ramp to 100 users — find the breaking point
6. **Soak test** — 20 users, 30 min — check for memory leaks

```bash
# Full recommended sequence:
python smoke_test.py && \
python test_api.py && \
locust -f locustfile.py --host https://192.168.86.130 \
  --users 30 --spawn-rate 3 --run-time 5m \
  --headless --html reports/load-test-$(date +%Y%m%d).html
```

---

## Interpreting Results

### Functional test failures

| Failure | Likely cause |
|---------|-------------|
| `Login failed — check credentials` | Wrong `ADMIN_USER`/`ADMIN_PASS` in `config.py` |
| `200 ≠ 201 on POST /api/assets` | Duplicate test data from previous run — check DB |
| `401 on authenticated endpoint` | Token expired or JWT_SECRET mismatch |
| `500 on any endpoint` | Server error — check `docker logs dcm_backend` |
| Connection refused | App not running — check `docker ps` |

### Load test failures

```bash
# Check backend logs during load test
docker logs dcm_backend --tail 50 -f

# Check DB connections
docker exec dcm_postgres psql -U dcuser -d dcmanager \
  -c "SELECT count(*) FROM pg_stat_activity;"

# Check resource usage
docker stats
```

---

## Files

| File | Purpose |
|------|---------|
| `config.py` | Target URL and credentials — edit before running |
| `smoke_test.py` | Quick 30-second sanity check |
| `test_api.py` | Full functional + integration test suite |
| `locustfile.py` | Load test with realistic user behaviour profiles |
| `requirements-test.txt` | Python dependencies |
| `reports/` | Load test HTML reports (created by Locust) |
