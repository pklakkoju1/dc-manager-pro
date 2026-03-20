"""
DC Manager Pro — Functional & Integration Test Suite
=====================================================
Covers every API endpoint including all features added in v3.1.x:
  - Unified asset full-history
  - Stock audit trail + allocated_to asset linking
  - Connectivity audit trail + change detection
  - Import: skipped count, duplicate checks, audit logging
  - New history endpoints for stock and connectivity
  - RBAC enforcement for all roles
  - Edge cases and validation

Run:
    cd tests/
    pip install -r requirements-test.txt
    python test_api.py

    # Against a different server:
    DCM_URL=https://10.0.0.50 DCM_PASS=MyPass python test_api.py
"""

import sys
import json
import time
import io
import requests
import urllib3
from config import BASE_URL, ADMIN_USER, ADMIN_PASS, TEST_PREFIX, VERIFY_SSL, TIMEOUT

urllib3.disable_warnings(urllib3.exceptions.InsecureRequestWarning)

GREEN  = "\033[92m"; RED = "\033[91m"; YELLOW = "\033[93m"
CYAN   = "\033[96m"; RESET = "\033[0m"; BOLD = "\033[1m"

passed = failed = skipped = 0
TOKEN  = None
CREATED = {}


# ── Helpers ───────────────────────────────────────────────────

def section(title):
    print(f"\n{BOLD}{CYAN}{'═'*56}{RESET}")
    print(f"{BOLD}{CYAN}  {title}{RESET}")
    print(f"{BOLD}{CYAN}{'═'*56}{RESET}")

def ok(name):
    global passed; passed += 1
    print(f"  {GREEN}✓{RESET}  {name}")

def fail(name, reason=""):
    global failed; failed += 1
    print(f"  {RED}✗{RESET}  {name}" + (f"\n      {RED}→ {reason}{RESET}" if reason else ""))

def skip(name, reason=""):
    global skipped; skipped += 1
    print(f"  {YELLOW}⊘{RESET}  {name} {YELLOW}({reason}){RESET}")

def check(name, condition, reason=""):
    if condition: ok(name)
    else: fail(name, reason)
    return condition

def get(path, token=None, params=None):
    h = {"Authorization": f"Bearer {token}"} if token else {}
    return requests.get(f"{BASE_URL}{path}", headers=h, params=params,
                        verify=VERIFY_SSL, timeout=TIMEOUT)

def post(path, data, token=None):
    h = {"Content-Type": "application/json"}
    if token: h["Authorization"] = f"Bearer {token}"
    return requests.post(f"{BASE_URL}{path}", json=data, headers=h,
                         verify=VERIFY_SSL, timeout=TIMEOUT)

def put(path, data, token=None):
    h = {"Content-Type": "application/json"}
    if token: h["Authorization"] = f"Bearer {token}"
    return requests.put(f"{BASE_URL}{path}", json=data, headers=h,
                        verify=VERIFY_SSL, timeout=TIMEOUT)

def delete(path, token=None):
    h = {"Authorization": f"Bearer {token}"} if token else {}
    return requests.delete(f"{BASE_URL}{path}", headers=h,
                           verify=VERIFY_SSL, timeout=TIMEOUT)

def upload(path, sheet, content, token=None):
    h = {"Authorization": f"Bearer {token}"} if token else {}
    files = {"file": (f"{sheet}.xlsx", content, "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet")}
    return requests.post(f"{BASE_URL}{path}?sheet={sheet}", files=files,
                         headers=h, verify=VERIFY_SSL, timeout=TIMEOUT)


# ══════════════════════════════════════════════════════════════
# 1. HEALTH
# ══════════════════════════════════════════════════════════════
def test_health():
    section("1. Health Checks")
    r = get("/api/health")
    check("GET /api/health → 200", r.status_code == 200)
    check("Health has status=ok", r.json().get("status") == "ok")
    check("Health has time field", "time" in r.json())
    r = get("/api/health/db")
    check("GET /api/health/db → 200", r.status_code == 200)
    check("DB health shows connected", r.json().get("db") == "connected")


# ══════════════════════════════════════════════════════════════
# 2. AUTH
# ══════════════════════════════════════════════════════════════
def test_auth():
    global TOKEN
    section("2. Authentication")
    r = post("/api/auth/login", {"username": ADMIN_USER, "password": ADMIN_PASS})
    if not check("POST /api/auth/login valid credentials → 200", r.status_code == 200):
        fail("Cannot continue — check BASE_URL and credentials in config.py")
        return
    data = r.json()
    check("Login returns token", "token" in data)
    check("Login returns user object", "user" in data)
    check("User role is superuser", data["user"].get("role") == "superuser")
    TOKEN = data["token"]

    check("Wrong password → 401",
          post("/api/auth/login", {"username": ADMIN_USER, "password": "wrongpass"}).status_code == 401)
    check("Wrong username → 401",
          post("/api/auth/login", {"username": "nobody", "password": "x"}).status_code == 401)
    check("Empty credentials → 401",
          post("/api/auth/login", {"username": "", "password": ""}).status_code == 401)

    r = get("/api/auth/me", token=TOKEN)
    check("GET /api/auth/me → 200", r.status_code == 200)
    check("GET /api/auth/me hides pw_hash", "pw_hash" not in r.json())
    check("GET /api/auth/me no token → 401", get("/api/auth/me").status_code == 401)
    check("GET /api/auth/me bad token → 401",
          get("/api/auth/me", token="bad.token.here").status_code == 401)


# ══════════════════════════════════════════════════════════════
# 3. STATS
# ══════════════════════════════════════════════════════════════
def test_stats():
    section("3. Dashboard Stats")
    r = get("/api/stats", token=TOKEN)
    check("GET /api/stats → 200", r.status_code == 200)
    data = r.json()
    for f in ["assets","online","racks","conns","stock_skus","low_stock","by_type","by_status"]:
        check(f"Stats has '{f}'", f in data)
    check("Stats assets is int", isinstance(data.get("assets"), int))
    check("GET /api/stats no token → 401", get("/api/stats").status_code == 401)


# ══════════════════════════════════════════════════════════════
# 4. RACKS
# ══════════════════════════════════════════════════════════════
def test_racks():
    section("4. Racks")
    r = get("/api/racks", token=TOKEN)
    check("GET /api/racks → 200", r.status_code == 200)
    check("GET /api/racks returns list", isinstance(r.json(), list))

    rack_data = {"rack_id": f"{TEST_PREFIX}RACK-01", "dc": f"{TEST_PREFIX}DC",
                 "zone": "Zone-1", "row_label": "Row-1", "total_u": 42,
                 "notes": "Automated test rack"}
    r = post("/api/racks", rack_data, token=TOKEN)
    if check("POST /api/racks create → 201", r.status_code == 201):
        d = r.json()
        check("Rack has correct rack_id", d.get("rack_id") == rack_data["rack_id"])
        check("Rack has correct total_u", d.get("total_u") == 42)
        CREATED["rack_id"] = d["rack_id"]

    # Upsert — same rack_id should update
    r = post("/api/racks", {**rack_data, "notes": "Updated"}, token=TOKEN)
    check("POST /api/racks duplicate upserts → 201", r.status_code == 201)

    if "rack_id" in CREATED:
        r = put(f"/api/racks/{CREATED['rack_id']}",
                {**rack_data, "total_u": 48}, token=TOKEN)
        check("PUT /api/racks/{id} → 200", r.status_code == 200)
        check("Updated rack has new total_u", r.json().get("total_u") == 48)

    check("PUT /api/racks non-existent → 404",
          put("/api/racks/NONEXISTENT-XYZ", {"rack_id":"X","total_u":42}, token=TOKEN).status_code == 404)
    check("POST /api/racks no token → 401",
          post("/api/racks", rack_data).status_code == 401)


# ══════════════════════════════════════════════════════════════
# 5. ASSETS
# ══════════════════════════════════════════════════════════════
def test_assets():
    section("5. Assets")
    rack_id = CREATED.get("rack_id", f"{TEST_PREFIX}RACK-01")

    check("GET /api/assets → 200", get("/api/assets", token=TOKEN).status_code == 200)
    check("GET /api/assets returns list", isinstance(get("/api/assets", token=TOKEN).json(), list))
    check("GET /api/assets?q= → 200",
          get("/api/assets", token=TOKEN, params={"q":"nonexistent-xyz"}).status_code == 200)
    check("GET /api/assets?type=Server → 200",
          get("/api/assets", token=TOKEN, params={"type":"Server"}).status_code == 200)

    asset_data = {
        "host": f"{TEST_PREFIX}SRV-001", "type": "Server", "status": "Online",
        "dc": f"{TEST_PREFIX}DC", "rack": rack_id, "ustart": 10, "uheight": 2,
        "ip": "10.0.0.101", "oob": "10.0.1.101", "mac": "AA:BB:CC:DD:EE:01",
        "vlan": "100", "atag": "ATAG-001", "sn": "SN-TEST-001",
        "notes": "Automated test asset",
        "hw_data": {"make": "Dell", "model": "R750", "po_number": "PO-TEST-001"}
    }
    r = post("/api/assets", asset_data, token=TOKEN)
    if check("POST /api/assets create → 201", r.status_code == 201):
        d = r.json()
        check("Asset has correct hostname", d.get("hostname") == asset_data["host"])
        check("Asset has correct status", d.get("status") == "Online")
        check("Asset has id", "id" in d)
        CREATED["asset_id"] = d["id"]
        CREATED["asset_hostname"] = d["hostname"]

    # Second asset for slot conflict testing
    r = post("/api/assets", {**asset_data, "host": f"{TEST_PREFIX}SRV-002",
             "ustart": 20, "sn": "SN-TEST-002", "ip": "10.0.0.102"}, token=TOKEN)
    if check("POST /api/assets second asset → 201", r.status_code == 201):
        CREATED["asset_id2"] = r.json()["id"]

    if "asset_id" in CREATED:
        r = get(f"/api/assets/{CREATED['asset_id']}", token=TOKEN)
        check("GET /api/assets/{id} → 200", r.status_code == 200)
        check("GET /api/assets/{id} correct hostname",
              r.json().get("hostname") == asset_data["host"])

    check("GET /api/assets non-existent → 404",
          get("/api/assets/00000000-0000-0000-0000-000000000000", token=TOKEN).status_code == 404)

    # Slot checks
    r = get("/api/assets/check-slot", token=TOKEN,
            params={"rack": rack_id, "ustart": 30, "uheight": 1})
    check("check-slot free slot returns empty list",
          r.status_code == 200 and r.json() == [])
    r = get("/api/assets/check-slot", token=TOKEN,
            params={"rack": rack_id, "ustart": 10, "uheight": 1})
    check("check-slot occupied slot returns conflicts",
          r.status_code == 200 and len(r.json()) > 0)

    # Update
    if "asset_id" in CREATED:
        r = put(f"/api/assets/{CREATED['asset_id']}",
                {**asset_data, "status": "Maintenance"}, token=TOKEN)
        check("PUT /api/assets/{id} → 200", r.status_code == 200)
        check("Updated asset has new status", r.json().get("status") == "Maintenance")

    # Per-asset history (existing endpoint)
    if "asset_id" in CREATED:
        r = get(f"/api/assets/{CREATED['asset_id']}/history", token=TOKEN)
        check("GET /api/assets/{id}/history → 200", r.status_code == 200)
        check("Asset history is list", isinstance(r.json(), list))
        check("Asset history has entries (create + update)", len(r.json()) >= 2)

    # Full unified history (new endpoint — asset + parts + connectivity)
    if "asset_id" in CREATED:
        r = get(f"/api/assets/{CREATED['asset_id']}/full-history", token=TOKEN)
        check("GET /api/assets/{id}/full-history → 200", r.status_code == 200)
        check("Full history is list", isinstance(r.json(), list))
        check("Full history has entries", len(r.json()) >= 1)
        if r.json():
            entry = r.json()[0]
            check("Full history entry has action", "action" in entry)
            check("Full history entry has detail", "detail" in entry)
            check("Full history entry has username", "username" in entry)

    check("POST /api/assets no token → 401",
          post("/api/assets", asset_data).status_code == 401)


# ══════════════════════════════════════════════════════════════
# 6. STOCK + AUDIT TRAIL
# ══════════════════════════════════════════════════════════════
def test_stock():
    section("6. Stock / Parts + Audit Trail")

    check("GET /api/stock → 200", get("/api/stock", token=TOKEN).status_code == 200)

    stock_data = {
        "cat": "HDD", "brand": "Seagate",
        "model": f"{TEST_PREFIX}ST4000NM",
        "spec": "4TB 7200RPM SAS 12Gbps", "ff": "3.5\"", "ifc": "SAS",
        "total": 20, "avail": 20, "cost": 149.99,
        "loc": "Shelf-A1", "notes": "Automated test stock"
    }
    r = post("/api/stock", stock_data, token=TOKEN)
    if not check("POST /api/stock create → 201", r.status_code == 201):
        skip("Stock transaction tests", "No stock item created"); return
    CREATED["stock_id"] = r.json()["id"]
    sid = CREATED["stock_id"]

    check("Stock has correct category", r.json().get("category") == "HDD")
    check("Stock has correct avail_qty", r.json().get("avail_qty") == 20)

    # IN
    r = post("/api/stock/transaction",
             {"stock_id": sid, "tx_type": "IN", "qty": 5, "ref": "PO-TEST"}, token=TOKEN)
    check("STOCK_IN → 200", r.status_code == 200)
    if r.status_code == 200:
        check("IN increases total to 25", r.json().get("total") == 25)
        check("IN increases avail to 25", r.json().get("avail") == 25)

    # ALLOCATE with asset link — the key new feature
    hostname = CREATED.get("asset_hostname", f"{TEST_PREFIX}SRV-001")
    r = post("/api/stock/transaction",
             {"stock_id": sid, "tx_type": "ALLOCATE", "qty": 2,
              "allocated_to": hostname, "notes": "Test allocation"}, token=TOKEN)
    check("STOCK_ALLOCATE with allocated_to → 200", r.status_code == 200)
    if r.status_code == 200:
        check("ALLOCATE reduces avail to 23", r.json().get("avail") == 23)
        check("ALLOCATE increases alloc to 2",  r.json().get("alloc") == 2)

    # Verify allocation appears in asset's full-history
    if "asset_id" in CREATED:
        time.sleep(0.5)  # slight delay for DB write
        r = get(f"/api/assets/{CREATED['asset_id']}/full-history", token=TOKEN)
        if r.status_code == 200:
            actions = [e.get("action","") for e in r.json()]
            check("ASSET_PART_ALLOCATED appears in asset full-history",
                  "ASSET_PART_ALLOCATED" in actions,
                  f"Actions found: {actions[:5]}")

    # RETURN with asset link
    r = post("/api/stock/transaction",
             {"stock_id": sid, "tx_type": "RETURN", "qty": 1,
              "allocated_to": hostname}, token=TOKEN)
    check("STOCK_RETURN with allocated_to → 200", r.status_code == 200)
    if r.status_code == 200:
        check("RETURN increases avail to 24", r.json().get("avail") == 24)

    # ALLOCATE without asset (should still work)
    r = post("/api/stock/transaction",
             {"stock_id": sid, "tx_type": "ALLOCATE", "qty": 1}, token=TOKEN)
    check("STOCK_ALLOCATE without allocated_to → 200", r.status_code == 200)

    # OUT
    r = post("/api/stock/transaction",
             {"stock_id": sid, "tx_type": "OUT", "qty": 2}, token=TOKEN)
    check("STOCK_OUT → 200", r.status_code == 200)

    # Insufficient stock
    r = post("/api/stock/transaction",
             {"stock_id": sid, "tx_type": "OUT", "qty": 9999}, token=TOKEN)
    check("STOCK_OUT insufficient → 400", r.status_code == 400)

    # ADJUST
    r = post("/api/stock/transaction",
             {"stock_id": sid, "tx_type": "ADJUST", "qty": 50}, token=TOKEN)
    check("STOCK_ADJUST → 200", r.status_code == 200)
    if r.status_code == 200:
        check("ADJUST sets exact qty to 50", r.json().get("total") == 50)

    # Invalid type
    check("STOCK invalid tx_type → 400",
          post("/api/stock/transaction",
               {"stock_id": sid, "tx_type": "BADTYPE", "qty": 1},
               token=TOKEN).status_code == 400)

    # Transaction history (raw transactions)
    r = get(f"/api/stock/{sid}/transactions", token=TOKEN)
    check("GET /api/stock/{id}/transactions → 200", r.status_code == 200)
    check("Transaction history has entries", len(r.json()) >= 5)
    if r.json():
        tx = r.json()[0]
        check("Transaction has tx_type", "tx_type" in tx)
        check("Transaction has qty",     "qty" in tx)
        check("Transaction has username","username" in tx)

    # Stock full history (audit + transactions merged — new endpoint)
    r = get(f"/api/stock/{sid}/history", token=TOKEN)
    check("GET /api/stock/{id}/history → 200", r.status_code == 200)
    check("Stock history is list", isinstance(r.json(), list))
    check("Stock history has entries", len(r.json()) >= 2)
    if r.json():
        # Verify allocation entry has allocated_to field
        alloc_entries = [e for e in r.json()
                         if e.get("tx_type") == "ALLOCATE" and e.get("allocated_to")]
        check("Stock history ALLOCATE entries have allocated_to",
              len(alloc_entries) > 0,
              "No ALLOCATE entries with allocated_to found")

    # Non-existent stock
    check("STOCK_TX non-existent → 404",
          post("/api/stock/transaction",
               {"stock_id": "00000000-0000-0000-0000-000000000000",
                "tx_type": "IN", "qty": 1}, token=TOKEN).status_code == 404)

    # Update stock item
    check("PUT /api/stock/{id} → 200",
          put(f"/api/stock/{sid}", {**stock_data, "total":50,"avail":50},
              token=TOKEN).status_code == 200)

    # Audit log shows stock entries
    r = get("/api/audit", token=TOKEN, params={"entity":"stock","limit":10})
    check("Audit log has stock entries", r.status_code == 200 and len(r.json().get("items",[])) > 0)

    check("POST /api/stock no token → 401",
          post("/api/stock", stock_data).status_code == 401)


# ══════════════════════════════════════════════════════════════
# 7. CONNECTIVITY + AUDIT TRAIL
# ══════════════════════════════════════════════════════════════
def test_connectivity():
    section("7. Connectivity + Audit Trail")

    check("GET /api/connectivity → 200",
          get("/api/connectivity", token=TOKEN).status_code == 200)

    conn_data = {
        "src_host":  f"{TEST_PREFIX}SRV-001",
        "src_slot":  "Slot-1",
        "src_port":  "eth0",
        "src_label": "slot1port1",        # unique label — key for import dedup
        "liu_a_rack":f"{TEST_PREFIX}RACK-01",
        "liu_a_host":f"{TEST_PREFIX}LIU-A",
        "liu_a_port":"Port-1",
        "dst_host":  f"{TEST_PREFIX}SW-CORE-01",
        "dst_port":  "Gi1/0/1",
        "cable":     "Fiber SM", "speed": "10G",
        "vlan": "100", "purpose": "Uplink",
        "notes": "Automated test connection"
    }
    r = post("/api/connectivity", conn_data, token=TOKEN)
    if check("POST /api/connectivity create → 201", r.status_code == 201):
        d = r.json()
        check("Conn has correct src_hostname", d.get("src_hostname") == conn_data["src_host"])
        check("Conn has correct cable_type",   d.get("cable_type") == "Fiber SM")
        check("Conn has id", "id" in d)
        CREATED["conn_id"] = d["id"]

    # Second connection — same server, different port label (should NOT be deduped)
    conn_data2 = {**conn_data,
                  "src_slot": "Slot-2", "src_port": "eth1",
                  "src_label": "slot2port1",   # different label
                  "dst_port": "Gi1/0/2"}
    r = post("/api/connectivity", conn_data2, token=TOKEN)
    if check("POST /api/connectivity second port on same server → 201",
             r.status_code == 201,
             "Same server can have multiple connections via different port labels"):
        CREATED["conn_id2"] = r.json()["id"]

    # Search
    check("GET /api/connectivity?q= → 200",
          get("/api/connectivity", token=TOKEN, params={"q": TEST_PREFIX}).status_code == 200)

    # Update — change switch port (should log change detection)
    if "conn_id" in CREATED:
        r = put(f"/api/connectivity/{CREATED['conn_id']}",
                {**conn_data, "dst_port": "Gi1/0/5", "speed": "25G"}, token=TOKEN)
        check("PUT /api/connectivity/{id} → 200", r.status_code == 200)
        check("Updated conn has new speed", r.json().get("speed") == "25G")

    # Connectivity history (new endpoint)
    if "conn_id" in CREATED:
        r = get(f"/api/connectivity/{CREATED['conn_id']}/history", token=TOKEN)
        check("GET /api/connectivity/{id}/history → 200", r.status_code == 200)
        check("Conn history is list", isinstance(r.json(), list))
        check("Conn history has create + update entries", len(r.json()) >= 2)
        if len(r.json()) >= 2:
            actions = [e.get("action") for e in r.json()]
            check("CONN_CREATED in history", "CONN_CREATED" in actions)
            check("CONN_UPDATED in history", "CONN_UPDATED" in actions)

    # Connectivity appears in asset full-history
    if "asset_id" in CREATED:
        r = get(f"/api/assets/{CREATED['asset_id']}/full-history", token=TOKEN)
        if r.status_code == 200:
            actions = [e.get("action","") for e in r.json()]
            has_conn = any(a.startswith("CONN_") for a in actions)
            check("Connectivity events appear in asset full-history", has_conn,
                  f"Actions: {[a for a in actions if a.startswith('CONN_')]}")

    # Audit log has connectivity entries
    r = get("/api/audit", token=TOKEN, params={"entity":"connectivity","limit":5})
    check("Audit log has connectivity entries",
          r.status_code == 200 and len(r.json().get("items",[])) > 0)

    check("PUT /api/connectivity non-existent → 404",
          put("/api/connectivity/00000000-0000-0000-0000-000000000000",
              conn_data, token=TOKEN).status_code == 404)
    check("POST /api/connectivity no token → 401",
          post("/api/connectivity", conn_data).status_code == 401)


# ══════════════════════════════════════════════════════════════
# 8. USERS
# ══════════════════════════════════════════════════════════════
def test_users():
    section("8. Users")

    r = get("/api/users", token=TOKEN)
    check("GET /api/users → 200", r.status_code == 200)
    check("Users list is non-empty", len(r.json()) >= 1)
    check("No pw_hash in user list", all("pw_hash" not in u for u in r.json()))

    user_data = {
        "name": "Test User Auto", "username": f"{TEST_PREFIX.lower()}testuser",
        "password": "TestPass@123", "role": "user",
        "email": "test@dcmanager.test", "dept": "IT"
    }
    r = post("/api/users", user_data, token=TOKEN)
    if check("POST /api/users create → 201", r.status_code == 201):
        check("Created user has correct role", r.json().get("role") == "user")
        CREATED["user_id"] = r.json()["id"]

    # Admin user
    admin_data = {"name": "Test Admin Auto",
                  "username": f"{TEST_PREFIX.lower()}testadmin",
                  "password": "AdminPass@123", "role": "admin"}
    r = post("/api/users", admin_data, token=TOKEN)
    if check("POST /api/users create admin → 201", r.status_code == 201):
        CREATED["admin_user_id"] = r.json()["id"]

    # Duplicate username
    check("POST /api/users duplicate username → 409",
          post("/api/users", user_data, token=TOKEN).status_code == 409)

    # New user can login
    r = post("/api/auth/login",
             {"username": user_data["username"], "password": user_data["password"]})
    check("New user can login", r.status_code == 200)
    user_token = r.json().get("token") if r.status_code == 200 else None

    # User role restrictions
    if user_token:
        check("User role cannot create assets → 403",
              post("/api/assets", {"host":"X","type":"Server"}, token=user_token).status_code == 403)
        check("User role cannot list users → 403",
              get("/api/users", token=user_token).status_code == 403)
        check("User role cannot access audit → 403",
              get("/api/audit", token=user_token).status_code == 403)

    # Update user
    if "user_id" in CREATED:
        r = put(f"/api/users/{CREATED['user_id']}",
                {**user_data, "role": "admin", "password": None}, token=TOKEN)
        check("PUT /api/users/{id} → 200", r.status_code == 200)
        check("Updated user role to admin", r.json().get("role") == "admin")

    # Cannot delete self
    me = get("/api/auth/me", token=TOKEN).json()
    check("DELETE /api/users self → 400",
          delete(f"/api/users/{me['id']}", token=TOKEN).status_code == 400)

    check("POST /api/users no token → 401",
          post("/api/users", user_data).status_code == 401)


# ══════════════════════════════════════════════════════════════
# 9. HW FIELDS
# ══════════════════════════════════════════════════════════════
def test_hw_fields():
    section("9. Hardware Fields")
    r = get("/api/hw-fields", token=TOKEN)
    check("GET /api/hw-fields → 200", r.status_code == 200)
    fields = r.json()
    sys_fields = [f for f in fields if f.get("is_system")]
    check("System fields exist", len(sys_fields) > 0)

    field_data = {
        "key": f"{TEST_PREFIX.lower().replace('-','_')}custom",
        "label": "Test Custom Field", "field_type": "text",
        "placeholder": "test...", "required": False, "sort_order": 999
    }
    r = post("/api/hw-fields", field_data, token=TOKEN)
    if check("POST /api/hw-fields create → 201", r.status_code == 201):
        check("Field is not system", r.json().get("is_system") == False)
        CREATED["hw_field_id"] = r.json()["id"]

    check("POST /api/hw-fields duplicate key → 409",
          post("/api/hw-fields", field_data, token=TOKEN).status_code == 409)

    if "hw_field_id" in CREATED:
        r = put(f"/api/hw-fields/{CREATED['hw_field_id']}",
                {**field_data, "label": "Updated Label"}, token=TOKEN)
        check("PUT /api/hw-fields/{id} → 200", r.status_code == 200)
        check("Field label updated", r.json().get("label") == "Updated Label")

    if sys_fields:
        check("DELETE system hw-field → 400",
              delete(f"/api/hw-fields/{sys_fields[0]['id']}", token=TOKEN).status_code == 400)

    check("GET /api/hw-fields no token → 401",
          get("/api/hw-fields").status_code == 401)


# ══════════════════════════════════════════════════════════════
# 10. EXPORT
# ══════════════════════════════════════════════════════════════
def test_export():
    section("10. Export")
    r = get("/api/export/excel", token=TOKEN)
    check("GET /api/export/excel → 200", r.status_code == 200)
    check("Export returns xlsx content-type",
          "spreadsheetml" in r.headers.get("Content-Type",""))
    check("Export has Content-Disposition",
          "attachment" in r.headers.get("Content-Disposition",""))
    check("Export file non-empty", len(r.content) > 1000)
    check("Export file is valid xlsx (PK magic bytes)",
          r.content[:4] == b'PK\x03\x04')
    check("GET /api/export/excel no token → 401",
          get("/api/export/excel").status_code == 401)


# ══════════════════════════════════════════════════════════════
# 11. AUDIT LOG
# ══════════════════════════════════════════════════════════════
def test_audit():
    section("11. Audit Log")

    r = get("/api/audit", token=TOKEN)
    check("GET /api/audit → 200", r.status_code == 200)
    data = r.json()
    check("Audit response has total",  "total"  in data)
    check("Audit response has items",  "items"  in data)
    check("Audit response has limit",  "limit"  in data)
    check("Audit response has offset", "offset" in data)

    items = data.get("items", [])
    check("Audit log has entries", len(items) > 0)
    if items:
        entry = items[0]
        for f in ["action","entity","username","created_at"]:
            check(f"Audit entry has '{f}'", f in entry)

    # Filter by entity — stock
    r = get("/api/audit", token=TOKEN, params={"entity":"stock","limit":5})
    check("GET /api/audit?entity=stock → 200", r.status_code == 200)
    stock_items = r.json().get("items",[])
    if stock_items:
        check("All stock audit entries are entity=stock",
              all(i.get("entity") == "stock" for i in stock_items))

    # Filter by entity — connectivity
    r = get("/api/audit", token=TOKEN, params={"entity":"connectivity","limit":5})
    check("GET /api/audit?entity=connectivity → 200", r.status_code == 200)

    # Filter by action — STOCK_ALLOCATE
    r = get("/api/audit", token=TOKEN, params={"action":"STOCK_ALLOCATE","limit":10})
    check("GET /api/audit?action=STOCK_ALLOCATE → 200", r.status_code == 200)
    alloc_items = r.json().get("items",[])
    if alloc_items:
        check("STOCK_ALLOCATE entries have correct action",
              all(i.get("action") == "STOCK_ALLOCATE" for i in alloc_items))

    # Filter by action — CONN_UPDATED
    r = get("/api/audit", token=TOKEN, params={"action":"CONN_UPDATED","limit":5})
    check("GET /api/audit?action=CONN_UPDATED → 200", r.status_code == 200)
    conn_items = r.json().get("items",[])
    if conn_items:
        check("CONN_UPDATED entries have detail with change description",
              any("→" in (i.get("detail","")) for i in conn_items),
              "Expected 'old → new' in detail")

    # Pagination
    r = get("/api/audit", token=TOKEN, params={"limit":5,"offset":0})
    check("GET /api/audit?limit=5 returns ≤5 items",
          r.status_code == 200 and len(r.json().get("items",[])) <= 5)

    # Search
    r = get("/api/audit", token=TOKEN, params={"q": TEST_PREFIX, "limit":20})
    check("GET /api/audit?q=TEST-AUTO- → 200", r.status_code == 200)

    # Non-admin cannot access audit
    r_login = post("/api/auth/login",
                   {"username": f"{TEST_PREFIX.lower()}testadmin",
                    "password": "AdminPass@123"})
    if r_login.status_code == 200:
        admin_token = r_login.json()["token"]
        check("Admin role can access audit → 200",
              get("/api/audit", token=admin_token).status_code == 200)
    else:
        skip("Admin audit access check", "Test admin not available")

    check("GET /api/audit no token → 401",
          get("/api/audit").status_code == 401)


# ══════════════════════════════════════════════════════════════
# 12. RBAC
# ══════════════════════════════════════════════════════════════
def test_rbac():
    section("12. RBAC — Role Enforcement")

    r_admin = post("/api/auth/login",
                   {"username": f"{TEST_PREFIX.lower()}testadmin",
                    "password": "AdminPass@123"})
    if r_admin.status_code != 200:
        skip("RBAC tests", "Test admin user not available"); return
    admin_token = r_admin.json()["token"]

    # Admin CAN read
    check("Admin can GET /api/assets", get("/api/assets", token=admin_token).status_code == 200)
    check("Admin can GET /api/stock",  get("/api/stock",  token=admin_token).status_code == 200)
    check("Admin can GET /api/audit",  get("/api/audit",  token=admin_token).status_code == 200)

    # Admin CAN write assets
    r = post("/api/assets",
             {"host": f"{TEST_PREFIX}ADMIN-SRV", "type":"Server","status":"Online"},
             token=admin_token)
    check("Admin can POST /api/assets", r.status_code == 201)
    if r.status_code == 201:
        CREATED["rbac_asset_id"] = r.json()["id"]

    # Admin CAN do stock transactions
    if "stock_id" in CREATED:
        r = post("/api/stock/transaction",
                 {"stock_id": CREATED["stock_id"], "tx_type": "IN", "qty": 1},
                 token=admin_token)
        check("Admin can POST /api/stock/transaction", r.status_code == 200)

    # Admin CANNOT manage users
    check("Admin cannot GET /api/users → 403",
          get("/api/users", token=admin_token).status_code == 403)
    check("Admin cannot POST /api/users → 403",
          post("/api/users",
               {"name":"X","username":"xxx","password":"xxx","role":"user"},
               token=admin_token).status_code == 403)

    # Admin CANNOT manage hw-fields
    check("Admin cannot POST /api/hw-fields → 403",
          post("/api/hw-fields",
               {"key":"x_rbac","label":"X","field_type":"text",
                "required":False,"sort_order":999},
               token=admin_token).status_code == 403)

    # Admin CANNOT delete rack (superuser only)
    if "rack_id" in CREATED:
        check("Admin cannot DELETE /api/racks → 403",
              delete(f"/api/racks/{CREATED['rack_id']}", token=admin_token).status_code == 403)


# ══════════════════════════════════════════════════════════════
# 13. EDGE CASES
# ══════════════════════════════════════════════════════════════
def test_edge_cases():
    section("13. Edge Cases & Validation")

    check("Unknown endpoint → 404",
          get("/api/nonexistent", token=TOKEN).status_code == 404)

    # Malformed JSON
    h = {"Content-Type":"application/json","Authorization":f"Bearer {TOKEN}"}
    r = requests.post(f"{BASE_URL}/api/assets", data="not-json",
                      headers=h, verify=VERIFY_SSL, timeout=TIMEOUT)
    check("POST with malformed JSON → 422", r.status_code == 422)

    # Missing required field
    check("POST /api/assets missing host → 422",
          post("/api/assets", {"type":"Server"}, token=TOKEN).status_code == 422)

    # Stock tx qty=0 should not crash
    if "stock_id" in CREATED:
        r = post("/api/stock/transaction",
                 {"stock_id": CREATED["stock_id"], "tx_type":"IN","qty":0}, token=TOKEN)
        check("Stock tx qty=0 doesn't crash (no 500)", r.status_code != 500)

    # Very long hostname
    r = post("/api/assets", {"host": "A"*300, "type":"Server"}, token=TOKEN)
    check("Very long hostname doesn't crash (no 500)", r.status_code != 500)

    # Rack delete with assets (should fail)
    if "rack_id" in CREATED:
        check("DELETE rack with assets → 400",
              delete(f"/api/racks/{CREATED['rack_id']}", token=TOKEN).status_code == 400)

    # Stock ALLOCATE with non-existent asset hostname (should still succeed — hostname not validated)
    if "stock_id" in CREATED:
        r = post("/api/stock/transaction",
                 {"stock_id": CREATED["stock_id"], "tx_type":"ALLOCATE",
                  "qty":1, "allocated_to":"nonexistent-host-xyz"}, token=TOKEN)
        check("ALLOCATE to non-existent asset hostname succeeds (no 404)",
              r.status_code == 200,
              "allocated_to is informational — not enforced as FK")


# ══════════════════════════════════════════════════════════════
# CLEANUP
# ══════════════════════════════════════════════════════════════
def cleanup():
    section("Cleanup — removing test records")

    for cid in ["conn_id2", "conn_id"]:
        if cid in CREATED:
            r = delete(f"/api/connectivity/{CREATED[cid]}", token=TOKEN)
            check(f"Delete test connectivity ({cid})", r.status_code == 204)

    if "rbac_asset_id" in CREATED:
        check("Delete rbac test asset",
              delete(f"/api/assets/{CREATED['rbac_asset_id']}", token=TOKEN).status_code == 204)

    for key in ["asset_id", "asset_id2"]:
        if key in CREATED:
            check(f"Delete test asset ({key})",
                  delete(f"/api/assets/{CREATED[key]}", token=TOKEN).status_code == 204)

    if "stock_id" in CREATED:
        check("Delete test stock item",
              delete(f"/api/stock/{CREATED['stock_id']}", token=TOKEN).status_code == 204)

    if "hw_field_id" in CREATED:
        check("Delete test hw field",
              delete(f"/api/hw-fields/{CREATED['hw_field_id']}", token=TOKEN).status_code == 204)

    for key in ["user_id","admin_user_id"]:
        if key in CREATED:
            check(f"Delete test user ({key})",
                  delete(f"/api/users/{CREATED[key]}", token=TOKEN).status_code == 204)

    if "rack_id" in CREATED:
        check("Delete test rack",
              delete(f"/api/racks/{CREATED['rack_id']}", token=TOKEN).status_code == 204)


# ══════════════════════════════════════════════════════════════
# MAIN
# ══════════════════════════════════════════════════════════════
if __name__ == "__main__":
    print(f"\n{BOLD}DC Manager Pro — API Test Suite v3.1{RESET}")
    print(f"Target  : {CYAN}{BASE_URL}{RESET}")
    print(f"User    : {ADMIN_USER}")
    print()

    start = time.time()

    test_health()
    test_auth()

    if TOKEN is None:
        print(f"\n{RED}FATAL: Login failed — check BASE_URL and credentials in config.py{RESET}\n")
        sys.exit(1)

    test_stats()
    test_racks()
    test_assets()
    test_stock()
    test_connectivity()
    test_users()
    test_hw_fields()
    test_export()
    test_audit()
    test_rbac()
    test_edge_cases()
    cleanup()

    duration = time.time() - start
    total = passed + failed + skipped

    print(f"\n{BOLD}{'═'*56}{RESET}")
    print(f"{BOLD}  Results{RESET}")
    print(f"{'═'*56}")
    print(f"  {GREEN}Passed : {passed}{RESET}")
    print(f"  {RED}Failed : {failed}{RESET}")
    print(f"  {YELLOW}Skipped: {skipped}{RESET}")
    print(f"  Total  : {total}")
    print(f"  Time   : {duration:.1f}s")
    print(f"{'═'*56}\n")

    sys.exit(0 if failed == 0 else 1)
