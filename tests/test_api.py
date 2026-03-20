"""
DC Manager Pro — Functional & Integration Test Suite
=====================================================
Tests every API endpoint: auth, assets, racks, stock,
connectivity, users, hw-fields, export, import, audit.

Run:
    cd tests/
    pip install -r requirements-test.txt
    python test_api.py

    # Or against a different server:
    DCM_URL=https://10.0.0.50 DCM_PASS=MyPass python test_api.py
"""

import sys
import json
import time
import requests
import urllib3
from config import BASE_URL, ADMIN_USER, ADMIN_PASS, TEST_PREFIX, VERIFY_SSL, TIMEOUT

urllib3.disable_warnings(urllib3.exceptions.InsecureRequestWarning)

# ── Colour output ──────────────────────────────────────────────
GREEN  = "\033[92m"
RED    = "\033[91m"
YELLOW = "\033[93m"
CYAN   = "\033[96m"
RESET  = "\033[0m"
BOLD   = "\033[1m"

passed = failed = skipped = 0
TOKEN  = None
CREATED = {}   # stores IDs of created test records for cleanup


# ── Test runner helpers ────────────────────────────────────────

def section(title):
    print(f"\n{BOLD}{CYAN}{'═'*55}{RESET}")
    print(f"{BOLD}{CYAN}  {title}{RESET}")
    print(f"{BOLD}{CYAN}{'═'*55}{RESET}")

def ok(name):
    global passed
    passed += 1
    print(f"  {GREEN}✓{RESET}  {name}")

def fail(name, reason=""):
    global failed
    failed += 1
    msg = f"  {RED}✗{RESET}  {name}"
    if reason:
        msg += f"\n      {RED}→ {reason}{RESET}"
    print(msg)

def skip(name, reason=""):
    global skipped
    skipped += 1
    print(f"  {YELLOW}⊘{RESET}  {name} {YELLOW}(skipped: {reason}){RESET}")

def check(name, condition, reason=""):
    if condition:
        ok(name)
    else:
        fail(name, reason)
    return condition


def get(path, token=None, params=None):
    h = {"Authorization": f"Bearer {token}"} if token else {}
    return requests.get(f"{BASE_URL}{path}", headers=h, params=params,
                        verify=VERIFY_SSL, timeout=TIMEOUT)

def post(path, data, token=None):
    h = {"Content-Type": "application/json"}
    if token:
        h["Authorization"] = f"Bearer {token}"
    return requests.post(f"{BASE_URL}{path}", json=data, headers=h,
                         verify=VERIFY_SSL, timeout=TIMEOUT)

def put(path, data, token=None):
    h = {"Content-Type": "application/json"}
    if token:
        h["Authorization"] = f"Bearer {token}"
    return requests.put(f"{BASE_URL}{path}", json=data, headers=h,
                        verify=VERIFY_SSL, timeout=TIMEOUT)

def delete(path, token=None):
    h = {"Authorization": f"Bearer {token}"} if token else {}
    return requests.delete(f"{BASE_URL}{path}", headers=h,
                           verify=VERIFY_SSL, timeout=TIMEOUT)


# ══════════════════════════════════════════════════════════════
# 1. HEALTH CHECKS
# ══════════════════════════════════════════════════════════════

def test_health():
    section("1. Health Checks")

    r = get("/api/health")
    check("GET /api/health returns 200", r.status_code == 200)
    check("Health response has status=ok", r.json().get("status") == "ok")
    check("Health response has time field", "time" in r.json())

    r = get("/api/health/db")
    check("GET /api/health/db returns 200", r.status_code == 200)
    check("DB health shows connected", r.json().get("db") == "connected")


# ══════════════════════════════════════════════════════════════
# 2. AUTHENTICATION
# ══════════════════════════════════════════════════════════════

def test_auth():
    global TOKEN
    section("2. Authentication")

    # Valid login
    r = post("/api/auth/login", {"username": ADMIN_USER, "password": ADMIN_PASS})
    if not check("POST /api/auth/login valid credentials → 200", r.status_code == 200):
        fail("Cannot continue without a valid token — check BASE_URL and credentials in config.py")
        return
    data = r.json()
    check("Login response contains token", "token" in data)
    check("Login response contains user object", "user" in data)
    check("User role is superuser", data["user"].get("role") == "superuser")
    TOKEN = data["token"]

    # Wrong password
    r = post("/api/auth/login", {"username": ADMIN_USER, "password": "wrongpassword"})
    check("POST /api/auth/login wrong password → 401", r.status_code == 401)

    # Wrong username
    r = post("/api/auth/login", {"username": "nobody", "password": "anything"})
    check("POST /api/auth/login wrong username → 401", r.status_code == 401)

    # No credentials
    r = post("/api/auth/login", {"username": "", "password": ""})
    check("POST /api/auth/login empty credentials → 401", r.status_code == 401)

    # GET /me with valid token
    r = get("/api/auth/me", token=TOKEN)
    check("GET /api/auth/me with valid token → 200", r.status_code == 200)
    check("GET /api/auth/me has no pw_hash in response", "pw_hash" not in r.json())

    # GET /me without token
    r = get("/api/auth/me")
    check("GET /api/auth/me without token → 401", r.status_code == 401)

    # GET /me with garbage token
    r = get("/api/auth/me", token="garbage.token.here")
    check("GET /api/auth/me with invalid token → 401", r.status_code == 401)


# ══════════════════════════════════════════════════════════════
# 3. STATS
# ══════════════════════════════════════════════════════════════

def test_stats():
    section("3. Dashboard Stats")

    r = get("/api/stats", token=TOKEN)
    check("GET /api/stats → 200", r.status_code == 200)
    data = r.json()
    for field in ["assets", "online", "racks", "conns", "stock_skus", "low_stock",
                  "by_type", "by_status"]:
        check(f"Stats response has '{field}' field", field in data)
    check("Stats assets is integer", isinstance(data.get("assets"), int))
    check("Stats by_type is list", isinstance(data.get("by_type"), list))

    # Unauthenticated
    r = get("/api/stats")
    check("GET /api/stats without token → 401", r.status_code == 401)


# ══════════════════════════════════════════════════════════════
# 4. RACKS
# ══════════════════════════════════════════════════════════════

def test_racks():
    section("4. Racks")

    # List
    r = get("/api/racks", token=TOKEN)
    check("GET /api/racks → 200", r.status_code == 200)
    check("GET /api/racks returns list", isinstance(r.json(), list))

    # Create
    rack_data = {
        "rack_id": f"{TEST_PREFIX}RACK-01",
        "dc": f"{TEST_PREFIX}DC",
        "zone": "Zone-1",
        "row_label": "Row-1",
        "total_u": 42,
        "notes": "Created by automated test"
    }
    r = post("/api/racks", rack_data, token=TOKEN)
    if check("POST /api/racks create → 201", r.status_code == 201):
        data = r.json()
        check("Created rack has correct rack_id", data.get("rack_id") == rack_data["rack_id"])
        check("Created rack has correct total_u", data.get("total_u") == 42)
        check("Created rack has zone", data.get("zone") == "Zone-1")
        CREATED["rack_id"] = data["rack_id"]

    # Create duplicate (ON CONFLICT DO UPDATE — should return 201 again with updated data)
    r = post("/api/racks", {**rack_data, "notes": "Updated by test"}, token=TOKEN)
    check("POST /api/racks duplicate rack_id upserts → 201", r.status_code == 201)

    # Update
    if "rack_id" in CREATED:
        r = put(f"/api/racks/{CREATED['rack_id']}",
                {**rack_data, "total_u": 48, "notes": "Updated"}, token=TOKEN)
        check("PUT /api/racks/{id} update → 200", r.status_code == 200)
        check("Updated rack has new total_u", r.json().get("total_u") == 48)

    # Update non-existent
    r = put("/api/racks/NONEXISTENT-RACK-XYZ",
            {"rack_id": "X", "total_u": 42}, token=TOKEN)
    check("PUT /api/racks/{id} non-existent → 404", r.status_code == 404)

    # Auth: create without token
    r = post("/api/racks", rack_data)
    check("POST /api/racks without token → 401", r.status_code == 401)


# ══════════════════════════════════════════════════════════════
# 5. ASSETS
# ══════════════════════════════════════════════════════════════

def test_assets():
    section("5. Assets")

    rack_id = CREATED.get("rack_id", f"{TEST_PREFIX}RACK-01")

    # List
    r = get("/api/assets", token=TOKEN)
    check("GET /api/assets → 200", r.status_code == 200)
    check("GET /api/assets returns list", isinstance(r.json(), list))

    # Search
    r = get("/api/assets", token=TOKEN, params={"q": "nonexistent-hostname-xyz"})
    check("GET /api/assets?q= search returns list", isinstance(r.json(), list))

    # Filter by type
    r = get("/api/assets", token=TOKEN, params={"type": "Server"})
    check("GET /api/assets?type=Server → 200", r.status_code == 200)

    # Create asset
    asset_data = {
        "host": f"{TEST_PREFIX}SRV-001",
        "type": "Server",
        "status": "Online",
        "dc": f"{TEST_PREFIX}DC",
        "rack": rack_id,
        "ustart": 10,
        "uheight": 2,
        "ip": "10.0.0.101",
        "oob": "10.0.1.101",
        "mac": "AA:BB:CC:DD:EE:01",
        "vlan": "100",
        "atag": "ATAG-001",
        "sn": "SN-TEST-001",
        "notes": "Automated test asset",
        "hw_data": {"make": "Dell", "model": "R750", "po_number": "PO-001"}
    }
    r = post("/api/assets", asset_data, token=TOKEN)
    if check("POST /api/assets create → 201", r.status_code == 201):
        data = r.json()
        check("Asset has correct hostname", data.get("hostname") == asset_data["host"])
        check("Asset has correct status", data.get("status") == "Online")
        check("Asset has correct rack", data.get("rack_id") == rack_id)
        check("Asset has correct u_start", data.get("u_start") == 10)
        check("Asset has id field", "id" in data)
        CREATED["asset_id"] = data["id"]
        CREATED["asset_hostname"] = data["hostname"]

    # Create second asset for slot conflict test
    asset_data2 = {**asset_data,
                   "host": f"{TEST_PREFIX}SRV-002",
                   "ustart": 20, "sn": "SN-TEST-002", "ip": "10.0.0.102"}
    r = post("/api/assets", asset_data2, token=TOKEN)
    if check("POST /api/assets second asset → 201", r.status_code == 201):
        CREATED["asset_id2"] = r.json()["id"]

    # GET by ID
    if "asset_id" in CREATED:
        r = get(f"/api/assets/{CREATED['asset_id']}", token=TOKEN)
        check("GET /api/assets/{id} → 200", r.status_code == 200)
        check("GET /api/assets/{id} correct hostname",
              r.json().get("hostname") == asset_data["host"])

    # GET non-existent
    r = get("/api/assets/00000000-0000-0000-0000-000000000000", token=TOKEN)
    check("GET /api/assets/{id} non-existent → 404", r.status_code == 404)

    # Check slot — available slot
    r = get("/api/assets/check-slot", token=TOKEN,
            params={"rack": rack_id, "ustart": 30, "uheight": 1})
    check("GET /api/assets/check-slot free slot → 200 empty list",
          r.status_code == 200 and r.json() == [])

    # Check slot — occupied slot
    r = get("/api/assets/check-slot", token=TOKEN,
            params={"rack": rack_id, "ustart": 10, "uheight": 1})
    check("GET /api/assets/check-slot occupied slot → returns conflicts",
          r.status_code == 200 and len(r.json()) > 0)

    # Update asset
    if "asset_id" in CREATED:
        updated = {**asset_data, "status": "Maintenance", "ustart": 10}
        r = put(f"/api/assets/{CREATED['asset_id']}", updated, token=TOKEN)
        check("PUT /api/assets/{id} update → 200", r.status_code == 200)
        check("Updated asset has new status", r.json().get("status") == "Maintenance")

    # Asset history
    if "asset_id" in CREATED:
        r = get(f"/api/assets/{CREATED['asset_id']}/history", token=TOKEN)
        check("GET /api/assets/{id}/history → 200", r.status_code == 200)
        check("Asset history is list", isinstance(r.json(), list))
        check("Asset history has entries (create + update)", len(r.json()) >= 2)

    # Auth checks
    r = post("/api/assets", asset_data)
    check("POST /api/assets without token → 401", r.status_code == 401)

    if "asset_id" in CREATED:
        r = delete(f"/api/assets/{CREATED['asset_id']}")
        check("DELETE /api/assets/{id} without token → 401", r.status_code == 401)


# ══════════════════════════════════════════════════════════════
# 6. STOCK
# ══════════════════════════════════════════════════════════════

def test_stock():
    section("6. Stock / Parts")

    # List
    r = get("/api/stock", token=TOKEN)
    check("GET /api/stock → 200", r.status_code == 200)
    check("GET /api/stock returns list", isinstance(r.json(), list))

    # Create
    stock_data = {
        "cat": "HDD",
        "brand": "Seagate",
        "model": f"{TEST_PREFIX}ST4000NM",
        "spec": "4TB 7200RPM SAS 12Gbps",
        "ff": "3.5\"",
        "ifc": "SAS",
        "total": 20,
        "avail": 20,
        "cost": 149.99,
        "loc": "Shelf-A1",
        "notes": "Automated test stock item"
    }
    r = post("/api/stock", stock_data, token=TOKEN)
    if check("POST /api/stock create → 201", r.status_code == 201):
        data = r.json()
        check("Stock has correct category", data.get("category") == "HDD")
        check("Stock has correct avail_qty", data.get("avail_qty") == 20)
        CREATED["stock_id"] = data["id"]

    if "stock_id" not in CREATED:
        skip("Stock transaction tests", "No stock item created")
        return

    sid = CREATED["stock_id"]

    # Transaction: IN
    r = post("/api/stock/transaction",
             {"stock_id": sid, "tx_type": "IN", "qty": 5, "ref": "PO-TEST-001"}, token=TOKEN)
    check("POST /api/stock/transaction IN → 200", r.status_code == 200)
    if r.status_code == 200:
        check("IN transaction increases total", r.json().get("total") == 25)
        check("IN transaction increases avail", r.json().get("avail") == 25)

    # Transaction: ALLOCATE
    r = post("/api/stock/transaction",
             {"stock_id": sid, "tx_type": "ALLOCATE", "qty": 3}, token=TOKEN)
    check("POST /api/stock/transaction ALLOCATE → 200", r.status_code == 200)
    if r.status_code == 200:
        check("ALLOCATE reduces avail", r.json().get("avail") == 22)
        check("ALLOCATE increases alloc", r.json().get("alloc") == 3)

    # Transaction: RETURN
    r = post("/api/stock/transaction",
             {"stock_id": sid, "tx_type": "RETURN", "qty": 1}, token=TOKEN)
    check("POST /api/stock/transaction RETURN → 200", r.status_code == 200)
    if r.status_code == 200:
        check("RETURN increases avail", r.json().get("avail") == 23)

    # Transaction: OUT
    r = post("/api/stock/transaction",
             {"stock_id": sid, "tx_type": "OUT", "qty": 2}, token=TOKEN)
    check("POST /api/stock/transaction OUT → 200", r.status_code == 200)
    if r.status_code == 200:
        check("OUT reduces total and avail", r.json().get("total") == 23)

    # Transaction: OUT with insufficient stock
    r = post("/api/stock/transaction",
             {"stock_id": sid, "tx_type": "OUT", "qty": 9999}, token=TOKEN)
    check("POST /api/stock/transaction OUT insufficient → 400", r.status_code == 400)

    # Transaction: ADJUST
    r = post("/api/stock/transaction",
             {"stock_id": sid, "tx_type": "ADJUST", "qty": 50}, token=TOKEN)
    check("POST /api/stock/transaction ADJUST → 200", r.status_code == 200)
    if r.status_code == 200:
        check("ADJUST sets exact qty", r.json().get("total") == 50)

    # Transaction: invalid type
    r = post("/api/stock/transaction",
             {"stock_id": sid, "tx_type": "BADTYPE", "qty": 1}, token=TOKEN)
    check("POST /api/stock/transaction invalid type → 400", r.status_code == 400)

    # Transaction history
    r = get(f"/api/stock/{sid}/transactions", token=TOKEN)
    check("GET /api/stock/{id}/transactions → 200", r.status_code == 200)
    check("Transaction history is list", isinstance(r.json(), list))
    check("Transaction history has entries", len(r.json()) >= 5)

    # Non-existent stock item
    r = post("/api/stock/transaction",
             {"stock_id": "00000000-0000-0000-0000-000000000000", "tx_type": "IN", "qty": 1},
             token=TOKEN)
    check("POST /api/stock/transaction non-existent item → 404", r.status_code == 404)

    # Update
    r = put(f"/api/stock/{sid}", {**stock_data, "total": 50, "avail": 50}, token=TOKEN)
    check("PUT /api/stock/{id} update → 200", r.status_code == 200)

    # Auth
    r = post("/api/stock", stock_data)
    check("POST /api/stock without token → 401", r.status_code == 401)


# ══════════════════════════════════════════════════════════════
# 7. CONNECTIVITY
# ══════════════════════════════════════════════════════════════

def test_connectivity():
    section("7. Connectivity")

    # List
    r = get("/api/connectivity", token=TOKEN)
    check("GET /api/connectivity → 200", r.status_code == 200)
    check("GET /api/connectivity returns list", isinstance(r.json(), list))

    # Create
    conn_data = {
        "src_host":   f"{TEST_PREFIX}SRV-001",
        "src_slot":   "Slot-1",
        "src_port":   "eth0",
        "src_label":  "uplink-01",
        "liu_a_rack": f"{TEST_PREFIX}RACK-01",
        "liu_a_host": f"{TEST_PREFIX}LIU-A",
        "liu_a_port": "Port-1",
        "liu_b_rack": None,
        "liu_b_host": None,
        "liu_b_port": None,
        "dst_host":   f"{TEST_PREFIX}SW-CORE-01",
        "dst_port":   "Gi1/0/1",
        "cable":      "Fiber SM",
        "speed":      "10G",
        "vlan":       "100",
        "purpose":    "Uplink",
        "notes":      "Automated test connection"
    }
    r = post("/api/connectivity", conn_data, token=TOKEN)
    if check("POST /api/connectivity create → 201", r.status_code == 201):
        data = r.json()
        check("Connectivity has correct src_hostname", data.get("src_hostname") == conn_data["src_host"])
        check("Connectivity has correct cable_type", data.get("cable_type") == "Fiber SM")
        check("Connectivity has id", "id" in data)
        CREATED["conn_id"] = data["id"]

    # Search
    r = get("/api/connectivity", token=TOKEN, params={"q": TEST_PREFIX})
    check("GET /api/connectivity?q= search → 200", r.status_code == 200)

    # Update
    if "conn_id" in CREATED:
        r = put(f"/api/connectivity/{CREATED['conn_id']}",
                {**conn_data, "speed": "25G", "vlan": "200"}, token=TOKEN)
        check("PUT /api/connectivity/{id} update → 200", r.status_code == 200)
        check("Updated conn has new speed", r.json().get("speed") == "25G")

    # Update non-existent
    r = put("/api/connectivity/00000000-0000-0000-0000-000000000000",
            conn_data, token=TOKEN)
    check("PUT /api/connectivity/{id} non-existent → 404", r.status_code == 404)

    # Auth
    r = post("/api/connectivity", conn_data)
    check("POST /api/connectivity without token → 401", r.status_code == 401)


# ══════════════════════════════════════════════════════════════
# 8. USERS
# ══════════════════════════════════════════════════════════════

def test_users():
    section("8. Users (Superuser only)")

    # List users (superuser)
    r = get("/api/users", token=TOKEN)
    check("GET /api/users → 200", r.status_code == 200)
    check("Users list is non-empty", len(r.json()) >= 1)
    users = r.json()
    check("No pw_hash in user list", all("pw_hash" not in u for u in users))

    # Create user
    user_data = {
        "name": "Test User Auto",
        "username": f"{TEST_PREFIX.lower()}testuser",
        "password": "TestPass@123",
        "role": "user",
        "email": "test@dcmanager.test",
        "dept": "IT"
    }
    r = post("/api/users", user_data, token=TOKEN)
    if check("POST /api/users create → 201", r.status_code == 201):
        data = r.json()
        check("Created user has correct username",
              data.get("username") == user_data["username"].lower())
        check("Created user has correct role", data.get("role") == "user")
        CREATED["user_id"] = data["id"]

    # Create duplicate username
    r = post("/api/users", user_data, token=TOKEN)
    check("POST /api/users duplicate username → 409", r.status_code == 409)

    # Create admin role user
    admin_user_data = {
        "name": "Test Admin Auto",
        "username": f"{TEST_PREFIX.lower()}testadmin",
        "password": "AdminPass@123",
        "role": "admin"
    }
    r = post("/api/users", admin_user_data, token=TOKEN)
    if check("POST /api/users create admin → 201", r.status_code == 201):
        CREATED["admin_user_id"] = r.json()["id"]

    # Test new user can login
    r = post("/api/auth/login",
             {"username": user_data["username"], "password": user_data["password"]})
    check("New user can login", r.status_code == 200)
    user_token = r.json().get("token") if r.status_code == 200 else None

    # Test user (role=user) cannot write assets
    if user_token:
        r = post("/api/assets",
                 {"host": f"{TEST_PREFIX}UNAUTH-SRV", "type": "Server"}, token=user_token)
        check("User role cannot create assets → 403", r.status_code == 403)

        r = get("/api/users", token=user_token)
        check("User role cannot list users → 403", r.status_code == 403)

    # Update user
    if "user_id" in CREATED:
        r = put(f"/api/users/{CREATED['user_id']}",
                {**user_data, "role": "admin", "password": None}, token=TOKEN)
        check("PUT /api/users/{id} update role → 200", r.status_code == 200)
        check("Updated user has new role", r.json().get("role") == "admin")

    # Cannot delete self
    me = get("/api/auth/me", token=TOKEN).json()
    r = delete(f"/api/users/{me['id']}", token=TOKEN)
    check("DELETE /api/users cannot delete self → 400", r.status_code == 400)

    # Auth: create without token
    r = post("/api/users", user_data)
    check("POST /api/users without token → 401", r.status_code == 401)

    # Auth: create with non-superuser token
    if user_token:
        r = post("/api/users",
                 {"name": "X", "username": "xxx", "password": "xxx", "role": "user"},
                 token=user_token)
        check("POST /api/users with non-superuser → 403", r.status_code == 403)


# ══════════════════════════════════════════════════════════════
# 9. HW FIELDS
# ══════════════════════════════════════════════════════════════

def test_hw_fields():
    section("9. Hardware Fields")

    # List
    r = get("/api/hw-fields", token=TOKEN)
    check("GET /api/hw-fields → 200", r.status_code == 200)
    check("HW fields returns list", isinstance(r.json(), list))
    fields = r.json()
    system_fields = [f for f in fields if f.get("is_system")]
    check("System fields exist (make, model, etc.)", len(system_fields) > 0)

    # Create custom field
    field_data = {
        "key":        f"{TEST_PREFIX.lower().replace('-','_')}custom_field",
        "label":      "Test Custom Field",
        "field_type": "text",
        "placeholder": "Enter value...",
        "options":    None,
        "required":   False,
        "sort_order": 999
    }
    r = post("/api/hw-fields", field_data, token=TOKEN)
    if check("POST /api/hw-fields create → 201", r.status_code == 201):
        data = r.json()
        check("Field has correct label", data.get("label") == field_data["label"])
        check("Field is not system", data.get("is_system") == False)
        CREATED["hw_field_id"] = data["id"]

    # Duplicate key
    r = post("/api/hw-fields", field_data, token=TOKEN)
    check("POST /api/hw-fields duplicate key → 409", r.status_code == 409)

    # Update
    if "hw_field_id" in CREATED:
        r = put(f"/api/hw-fields/{CREATED['hw_field_id']}",
                {**field_data, "label": "Updated Test Field"}, token=TOKEN)
        check("PUT /api/hw-fields/{id} update → 200", r.status_code == 200)
        check("Field label updated", r.json().get("label") == "Updated Test Field")

    # Cannot delete system field
    if system_fields:
        r = delete(f"/api/hw-fields/{system_fields[0]['id']}", token=TOKEN)
        check("DELETE system hw-field → 400", r.status_code == 400)

    # Auth
    r = get("/api/hw-fields")
    check("GET /api/hw-fields without token → 401", r.status_code == 401)


# ══════════════════════════════════════════════════════════════
# 10. EXPORT
# ══════════════════════════════════════════════════════════════

def test_export():
    section("10. Export")

    r = get("/api/export/excel", token=TOKEN)
    check("GET /api/export/excel → 200", r.status_code == 200)
    check("Export returns xlsx content-type",
          "spreadsheetml" in r.headers.get("Content-Type", ""))
    check("Export has Content-Disposition header",
          "attachment" in r.headers.get("Content-Disposition", ""))
    check("Export file is non-empty", len(r.content) > 1000)
    check("Export file starts with xlsx magic bytes",
          r.content[:4] == b'PK\x03\x04')

    # Auth
    r = get("/api/export/excel")
    check("GET /api/export/excel without token → 401", r.status_code == 401)


# ══════════════════════════════════════════════════════════════
# 11. AUDIT LOG
# ══════════════════════════════════════════════════════════════

def test_audit():
    section("11. Audit Log")

    r = get("/api/audit", token=TOKEN)
    check("GET /api/audit (superuser) → 200", r.status_code == 200)
    check("Audit log is list", isinstance(r.json(), list))
    if r.json():
        entry = r.json()[0]
        for field in ["action", "entity", "username", "created_at"]:
            check(f"Audit entry has '{field}'", field in entry)

    # Limit parameter
    r = get("/api/audit", token=TOKEN, params={"limit": 5})
    check("GET /api/audit?limit=5 returns ≤5 entries",
          r.status_code == 200 and len(r.json()) <= 5)

    # Filter by entity
    r = get("/api/audit", token=TOKEN, params={"entity": "asset"})
    check("GET /api/audit?entity=asset → 200", r.status_code == 200)

    # Auth: non-superuser login
    r_login = post("/api/auth/login",
                   {"username": f"{TEST_PREFIX.lower()}testadmin",
                    "password": "AdminPass@123"})
    if r_login.status_code == 200:
        admin_token = r_login.json()["token"]
        r = get("/api/audit", token=admin_token)
        check("GET /api/audit with admin role → 403", r.status_code == 403)
    else:
        skip("GET /api/audit non-superuser auth check", "test admin user not available")


# ══════════════════════════════════════════════════════════════
# 12. RBAC — Role-Based Access Control
# ══════════════════════════════════════════════════════════════

def test_rbac():
    section("12. RBAC — Role Enforcement")

    # Login as viewer-role user (created earlier as "user" role)
    r_login = post("/api/auth/login",
                   {"username": f"{TEST_PREFIX.lower()}testuser",
                    "password": "TestPass@123"})
    if r_login.status_code != 200:
        skip("RBAC tests", "Test user not available")
        return

    # Note: we updated testuser to admin in test_users, so use testadmin (role=admin)
    r_login2 = post("/api/auth/login",
                    {"username": f"{TEST_PREFIX.lower()}testadmin",
                     "password": "AdminPass@123"})
    if r_login2.status_code != 200:
        skip("RBAC admin tests", "Test admin not available")
        return

    admin_token = r_login2.json()["token"]

    # Admin CAN read assets
    r = get("/api/assets", token=admin_token)
    check("Admin role can GET /api/assets", r.status_code == 200)

    # Admin CAN create asset
    r = post("/api/assets",
             {"host": f"{TEST_PREFIX}ADMIN-SRV", "type": "Server", "status": "Online"},
             token=admin_token)
    check("Admin role can POST /api/assets", r.status_code == 201)
    if r.status_code == 201:
        CREATED["rbac_asset_id"] = r.json()["id"]

    # Admin CANNOT manage users
    r = get("/api/users", token=admin_token)
    check("Admin role cannot GET /api/users → 403", r.status_code == 403)

    # Admin CANNOT create hw fields
    r = post("/api/hw-fields",
             {"key": "x_test", "label": "X", "field_type": "text",
              "required": False, "sort_order": 999},
             token=admin_token)
    check("Admin role cannot POST /api/hw-fields → 403", r.status_code == 403)

    # Admin CANNOT delete rack (superuser only)
    if "rack_id" in CREATED:
        r = delete(f"/api/racks/{CREATED['rack_id']}", token=admin_token)
        check("Admin role cannot DELETE rack → 403", r.status_code == 403)

    # Admin CANNOT access audit log
    r = get("/api/audit", token=admin_token)
    check("Admin role cannot GET /api/audit → 403", r.status_code == 403)


# ══════════════════════════════════════════════════════════════
# 13. EDGE CASES & VALIDATION
# ══════════════════════════════════════════════════════════════

def test_edge_cases():
    section("13. Edge Cases & Validation")

    # Unknown endpoint
    r = get("/api/nonexistent", token=TOKEN)
    check("GET unknown endpoint → 404", r.status_code == 404)

    # Malformed JSON
    h = {"Content-Type": "application/json", "Authorization": f"Bearer {TOKEN}"}
    r = requests.post(f"{BASE_URL}/api/assets", data="not-json",
                      headers=h, verify=VERIFY_SSL, timeout=TIMEOUT)
    check("POST with malformed JSON → 422", r.status_code == 422)

    # Missing required field (host)
    r = post("/api/assets", {"type": "Server"}, token=TOKEN)
    check("POST /api/assets missing required 'host' → 422", r.status_code == 422)

    # Stock transaction with qty=0
    if "stock_id" in CREATED:
        r = post("/api/stock/transaction",
                 {"stock_id": CREATED["stock_id"], "tx_type": "IN", "qty": 0}, token=TOKEN)
        # qty=0 may succeed (depends on business logic) — just check it doesn't 500
        check("POST /api/stock/transaction qty=0 doesn't crash (no 500)",
              r.status_code != 500)

    # Very long hostname
    long_host = "A" * 300
    r = post("/api/assets", {"host": long_host, "type": "Server"}, token=TOKEN)
    check("POST /api/assets very long hostname doesn't crash (no 500)",
          r.status_code != 500)

    # Rack delete with assets (should fail)
    if "rack_id" in CREATED:
        r = delete(f"/api/racks/{CREATED['rack_id']}", token=TOKEN)
        check("DELETE rack with assets → 400", r.status_code == 400)


# ══════════════════════════════════════════════════════════════
# CLEANUP — remove all test records
# ══════════════════════════════════════════════════════════════

def cleanup():
    section("Cleanup — removing test records")

    # Delete connectivity
    if "conn_id" in CREATED:
        r = delete(f"/api/connectivity/{CREATED['conn_id']}", token=TOKEN)
        check(f"Delete test connectivity {CREATED['conn_id'][:8]}...", r.status_code == 204)

    # Delete rbac test asset
    if "rbac_asset_id" in CREATED:
        r = delete(f"/api/assets/{CREATED['rbac_asset_id']}", token=TOKEN)
        check(f"Delete rbac test asset", r.status_code == 204)

    # Delete assets
    for key in ["asset_id", "asset_id2"]:
        if key in CREATED:
            r = delete(f"/api/assets/{CREATED[key]}", token=TOKEN)
            check(f"Delete test asset ({key})", r.status_code == 204)

    # Delete stock
    if "stock_id" in CREATED:
        r = delete(f"/api/stock/{CREATED['stock_id']}", token=TOKEN)
        check(f"Delete test stock item", r.status_code == 204)

    # Delete hw field
    if "hw_field_id" in CREATED:
        r = delete(f"/api/hw-fields/{CREATED['hw_field_id']}", token=TOKEN)
        check(f"Delete test hw field", r.status_code == 204)

    # Delete users
    for key in ["user_id", "admin_user_id"]:
        if key in CREATED:
            r = delete(f"/api/users/{CREATED[key]}", token=TOKEN)
            check(f"Delete test user ({key})", r.status_code == 204)

    # Delete rack last (assets must be gone first)
    if "rack_id" in CREATED:
        r = delete(f"/api/racks/{CREATED['rack_id']}", token=TOKEN)
        check(f"Delete test rack", r.status_code == 204)


# ══════════════════════════════════════════════════════════════
# MAIN
# ══════════════════════════════════════════════════════════════

if __name__ == "__main__":
    print(f"\n{BOLD}DC Manager Pro — API Test Suite{RESET}")
    print(f"Target : {CYAN}{BASE_URL}{RESET}")
    print(f"User   : {ADMIN_USER}")
    print()

    start = time.time()

    test_health()
    test_auth()

    if TOKEN is None:
        print(f"\n{RED}FATAL: Login failed — cannot run further tests.{RESET}")
        print(f"Check BASE_URL ({BASE_URL}) and credentials in config.py\n")
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

    print(f"\n{BOLD}{'═'*55}{RESET}")
    print(f"{BOLD}  Results{RESET}")
    print(f"{'═'*55}")
    print(f"  {GREEN}Passed : {passed}{RESET}")
    print(f"  {RED}Failed : {failed}{RESET}")
    print(f"  {YELLOW}Skipped: {skipped}{RESET}")
    print(f"  Time   : {duration:.1f}s")
    print(f"{'═'*55}\n")

    sys.exit(0 if failed == 0 else 1)
