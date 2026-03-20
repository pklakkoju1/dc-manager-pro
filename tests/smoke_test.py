"""
DC Manager Pro — Smoke Test
============================
Fast sanity check (~30 seconds). Run after every deployment
to confirm the app is alive and core functions work.

Run:
    python smoke_test.py
    python smoke_test.py https://10.0.0.50   # different server
"""

import sys
import time
import requests
import urllib3
from config import BASE_URL, ADMIN_USER, ADMIN_PASS, VERIFY_SSL

urllib3.disable_warnings(urllib3.exceptions.InsecureRequestWarning)

url = sys.argv[1] if len(sys.argv) > 1 else BASE_URL
GREEN = "\033[92m"; RED = "\033[91m"; RESET = "\033[0m"; BOLD = "\033[1m"

passed = failed = 0

def check(name, ok, detail=""):
    global passed, failed
    if ok:
        passed += 1
        print(f"  {GREEN}✓{RESET}  {name}")
    else:
        failed += 1
        print(f"  {RED}✗{RESET}  {name}" + (f"  →  {RED}{detail}{RESET}" if detail else ""))

def r_get(path, token=None):
    h = {"Authorization": f"Bearer {token}"} if token else {}
    return requests.get(f"{url}{path}", headers=h, verify=VERIFY_SSL, timeout=15)

def r_post(path, data, token=None):
    h = {"Content-Type": "application/json"}
    if token:
        h["Authorization"] = f"Bearer {token}"
    return requests.post(f"{url}{path}", json=data, headers=h, verify=VERIFY_SSL, timeout=15)


print(f"\n{BOLD}DC Manager Pro — Smoke Test{RESET}")
print(f"Target: {url}\n")
start = time.time()

# 1. Health
r = r_get("/api/health")
check("App is reachable", r.status_code == 200,
      f"HTTP {r.status_code} — is the server running?")

r = r_get("/api/health/db")
check("Database is connected", r.status_code == 200 and r.json().get("db") == "connected",
      "Check dcm_postgres container logs")

# 2. HTTPS redirect
r = requests.get(f"http://{url.replace('https://','').replace('http://','')}",
                 verify=False, timeout=10, allow_redirects=False)
check("HTTP redirects to HTTPS", r.status_code in [301, 302],
      f"Got {r.status_code} — check nginx config")

# 3. Auth
r = r_post("/api/auth/login", {"username": ADMIN_USER, "password": ADMIN_PASS})
check("Admin login succeeds", r.status_code == 200,
      f"HTTP {r.status_code} — check credentials in config.py")
token = r.json().get("token") if r.status_code == 200 else None

if not token:
    print(f"\n{RED}FATAL: Cannot get token. Remaining tests skipped.{RESET}\n")
    sys.exit(1)

r = r_post("/api/auth/login", {"username": "admin", "password": "wrongpass"})
check("Bad password rejected (401)", r.status_code == 401)

# 4. Core data endpoints
r = r_get("/api/stats", token=token)
check("Stats endpoint OK", r.status_code == 200)

r = r_get("/api/assets", token=token)
check("Assets endpoint OK", r.status_code == 200)

r = r_get("/api/racks", token=token)
check("Racks endpoint OK", r.status_code == 200)

r = r_get("/api/stock", token=token)
check("Stock endpoint OK", r.status_code == 200)

r = r_get("/api/connectivity", token=token)
check("Connectivity endpoint OK", r.status_code == 200)

# 5. Auth enforcement
r = r_get("/api/assets")
check("Unauthenticated request blocked (401)", r.status_code == 401)

# 6. Export
r = r_get("/api/export/excel", token=token)
check("Excel export works", r.status_code == 200 and len(r.content) > 500,
      f"HTTP {r.status_code}, size={len(r.content)}")

# 7. Frontend
r = requests.get(url, verify=VERIFY_SSL, timeout=15)
check("Frontend loads (200)", r.status_code == 200)
check("Frontend has DC Manager content",
      "DC Manager" in r.text or "dcmanager" in r.text.lower(),
      "Unexpected frontend content")

duration = time.time() - start

print(f"\n{'─'*40}")
print(f"  {GREEN}Passed: {passed}{RESET}   {RED}Failed: {failed}{RESET}   Time: {duration:.1f}s")
print(f"{'─'*40}\n")

sys.exit(0 if failed == 0 else 1)
