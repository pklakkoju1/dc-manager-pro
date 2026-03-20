"""
DC Manager Pro — Load Test (Locust)
=====================================
Simulates realistic user behaviour:
  - ReadUser  : browse assets, racks, stock (60% of traffic)
  - WriteUser : create, update, delete assets (30% of traffic)
  - HeavyUser : export, search, import (10% of traffic)

Run — interactive web UI:
    locust -f locustfile.py --host https://192.168.86.130

Run — headless, 20 users, 2 min:
    locust -f locustfile.py --host https://192.168.86.130 \
      --users 20 --spawn-rate 2 --run-time 2m --headless

Run — headless, ramp to 50 users:
    locust -f locustfile.py --host https://192.168.86.130 \
      --users 50 --spawn-rate 5 --run-time 5m --headless \
      --html load-test-report.html

Environment overrides:
    DCM_USER=admin DCM_PASS=Admin@123 locust -f locustfile.py ...
"""

import os
import json
import random
import string
import urllib3
from locust import HttpUser, task, between, events

urllib3.disable_warnings(urllib3.exceptions.InsecureRequestWarning)

ADMIN_USER = os.getenv("DCM_USER", "admin")
ADMIN_PASS = os.getenv("DCM_PASS", "Admin@123")
TEST_PREFIX = "LOAD-"


def rand_str(n=6):
    return "".join(random.choices(string.ascii_uppercase + string.digits, k=n))


# ── Base class: handles login + auth header ────────────────────

class DCMUser(HttpUser):
    abstract = True
    token    = None

    def on_start(self):
        """Login once per simulated user at startup."""
        with self.client.post(
            "/api/auth/login",
            json={"username": ADMIN_USER, "password": ADMIN_PASS},
            verify=False,
            catch_response=True,
            name="auth/login"
        ) as r:
            if r.status_code == 200:
                self.token = r.json().get("token")
                r.success()
            else:
                r.failure(f"Login failed: {r.status_code} {r.text[:100]}")

    def auth_headers(self):
        return {"Authorization": f"Bearer {self.token}"}

    def get(self, path, name=None, **kwargs):
        return self.client.get(path,
            headers=self.auth_headers(),
            verify=False,
            name=name or path,
            **kwargs)

    def post(self, path, data, name=None, **kwargs):
        return self.client.post(path,
            json=data,
            headers=self.auth_headers(),
            verify=False,
            name=name or path,
            **kwargs)

    def put(self, path, data, name=None, **kwargs):
        return self.client.put(path,
            json=data,
            headers=self.auth_headers(),
            verify=False,
            name=name or path,
            **kwargs)

    def delete(self, path, name=None, **kwargs):
        return self.client.delete(path,
            headers=self.auth_headers(),
            verify=False,
            name=name or path,
            **kwargs)


# ══════════════════════════════════════════════════════════════
# ReadUser — simulates a viewer browsing the app
# Weight: 3 (most common user type)
# ══════════════════════════════════════════════════════════════

class ReadUser(DCMUser):
    weight      = 3
    wait_time   = between(1, 4)   # realistic think time

    @task(5)
    def browse_assets(self):
        """List all assets — most common operation."""
        self.get("/api/assets", name="GET /api/assets")

    @task(3)
    def search_assets(self):
        """Search assets by hostname prefix."""
        terms = ["srv", "db", "web", "app", "bm", "vm"]
        q = random.choice(terms)
        self.get(f"/api/assets?q={q}", name="GET /api/assets?q=")

    @task(3)
    def filter_assets_by_type(self):
        types = ["Server", "Switch", "VM", "Router"]
        t = random.choice(types)
        self.get(f"/api/assets?type={t}", name="GET /api/assets?type=")

    @task(2)
    def browse_racks(self):
        self.get("/api/racks", name="GET /api/racks")

    @task(2)
    def browse_stock(self):
        self.get("/api/stock", name="GET /api/stock")

    @task(2)
    def browse_connectivity(self):
        self.get("/api/connectivity", name="GET /api/connectivity")

    @task(3)
    def dashboard_stats(self):
        self.get("/api/stats", name="GET /api/stats")

    @task(1)
    def health_check(self):
        self.get("/api/health", name="GET /api/health")

    @task(2)
    def get_random_asset(self):
        """Get asset list then fetch a random one by ID."""
        r = self.get("/api/assets", name="GET /api/assets")
        if r.status_code == 200:
            assets = r.json()
            if assets:
                asset = random.choice(assets)
                aid = asset.get("id")
                if aid:
                    self.get(f"/api/assets/{aid}", name="GET /api/assets/{id}")

    @task(1)
    def get_asset_history(self):
        """Get audit history for a random asset."""
        r = self.get("/api/assets", name="GET /api/assets")
        if r.status_code == 200:
            assets = r.json()
            if assets:
                aid = random.choice(assets).get("id")
                if aid:
                    self.get(f"/api/assets/{aid}/history",
                             name="GET /api/assets/{id}/history")

    @task(1)
    def check_slot(self):
        """Simulate rack view slot availability check."""
        r = self.get("/api/racks", name="GET /api/racks")
        if r.status_code == 200:
            racks = r.json()
            if racks:
                rack = random.choice(racks)
                rid = rack.get("rack_id")
                u   = random.randint(1, 42)
                self.get(f"/api/assets/check-slot?rack={rid}&ustart={u}&uheight=1",
                         name="GET /api/assets/check-slot")

    @task(1)
    def hw_fields(self):
        self.get("/api/hw-fields", name="GET /api/hw-fields")

    @task(1)
    def whoami(self):
        self.get("/api/auth/me", name="GET /api/auth/me")


# ══════════════════════════════════════════════════════════════
# WriteUser — simulates admin creating/updating/deleting data
# Weight: 2
# ══════════════════════════════════════════════════════════════

class WriteUser(DCMUser):
    weight    = 2
    wait_time = between(2, 6)

    def __init__(self, *args, **kwargs):
        super().__init__(*args, **kwargs)
        self._created_assets  = []
        self._created_racks   = []
        self._created_stock   = []
        self._created_conns   = []

    @task(4)
    def create_and_delete_asset(self):
        """Create an asset then delete it — simulates full write cycle."""
        hostname = f"{TEST_PREFIX}SRV-{rand_str()}"
        r = self.post("/api/assets", {
            "host":    hostname,
            "type":    random.choice(["Server", "VM", "Switch"]),
            "status":  "Online",
            "dc":      f"DC-{rand_str(3)}",
            "rack":    f"R-{rand_str(4)}",
            "ustart":  random.randint(1, 38),
            "uheight": 1,
            "ip":      f"10.{random.randint(0,255)}.{random.randint(0,255)}.{random.randint(1,254)}",
            "sn":      f"SN-{rand_str(8)}",
            "hw_data": {"make": "Dell", "model": f"R{random.randint(6,9)}50"}
        }, name="POST /api/assets")

        if r.status_code == 201:
            aid = r.json().get("id")
            if aid:
                self._created_assets.append(aid)

                # Update status
                self.put(f"/api/assets/{aid}", {
                    "host":    hostname,
                    "type":    "Server",
                    "status":  "Maintenance",
                    "hw_data": {}
                }, name="PUT /api/assets/{id}")

                # Delete
                self.delete(f"/api/assets/{aid}",
                            name="DELETE /api/assets/{id}")
                self._created_assets.remove(aid)

    @task(2)
    def create_rack(self):
        """Create a rack, then clean it up."""
        rid = f"{TEST_PREFIX}RACK-{rand_str()}"
        r = self.post("/api/racks", {
            "rack_id":   rid,
            "dc":        f"DC-{rand_str(3)}",
            "zone":      f"Zone-{random.randint(1,5)}",
            "row_label": f"Row-{random.randint(1,20)}",
            "total_u":   42
        }, name="POST /api/racks")

        if r.status_code == 201:
            self._created_racks.append(rid)
            # Delete empty rack
            self.delete(f"/api/racks/{rid}", name="DELETE /api/racks/{id}")
            self._created_racks.remove(rid)

    @task(2)
    def stock_transactions(self):
        """Create stock item, do transactions, delete."""
        r = self.post("/api/stock", {
            "cat":   "RAM",
            "brand": "Kingston",
            "model": f"{TEST_PREFIX}DDR5-{rand_str(4)}",
            "spec":  "32GB DDR5-4800",
            "total": 10,
            "avail": 10,
            "cost":  89.99
        }, name="POST /api/stock")

        if r.status_code == 201:
            sid = r.json().get("id")
            if sid:
                self._created_stock.append(sid)

                # IN
                self.post("/api/stock/transaction",
                          {"stock_id": sid, "tx_type": "IN", "qty": 5},
                          name="POST /api/stock/transaction")

                # ALLOCATE
                self.post("/api/stock/transaction",
                          {"stock_id": sid, "tx_type": "ALLOCATE", "qty": 2},
                          name="POST /api/stock/transaction")

                # RETURN
                self.post("/api/stock/transaction",
                          {"stock_id": sid, "tx_type": "RETURN", "qty": 1},
                          name="POST /api/stock/transaction")

                # Delete
                self.delete(f"/api/stock/{sid}", name="DELETE /api/stock/{id}")
                self._created_stock.remove(sid)

    @task(1)
    def create_and_delete_connectivity(self):
        r = self.post("/api/connectivity", {
            "src_host": f"{TEST_PREFIX}SRV-{rand_str()}",
            "src_port": f"eth{random.randint(0,3)}",
            "dst_host": f"{TEST_PREFIX}SW-{rand_str()}",
            "dst_port": f"Gi1/0/{random.randint(1,48)}",
            "cable":    random.choice(["Fiber SM", "DAC", "Copper"]),
            "speed":    random.choice(["1G", "10G", "25G"]),
            "vlan":     str(random.randint(1, 4094))
        }, name="POST /api/connectivity")

        if r.status_code == 201:
            cid = r.json().get("id")
            if cid:
                self.delete(f"/api/connectivity/{cid}",
                            name="DELETE /api/connectivity/{id}")

    def on_stop(self):
        """Clean up any leftover test records."""
        for aid in self._created_assets:
            self.delete(f"/api/assets/{aid}", name="DELETE /api/assets/{id} [cleanup]")
        for rid in self._created_racks:
            self.delete(f"/api/racks/{rid}", name="DELETE /api/racks/{id} [cleanup]")
        for sid in self._created_stock:
            self.delete(f"/api/stock/{sid}", name="DELETE /api/stock/{id} [cleanup]")
        for cid in self._created_conns:
            self.delete(f"/api/connectivity/{cid}", name="DELETE /api/connectivity/{id} [cleanup]")


# ══════════════════════════════════════════════════════════════
# HeavyUser — export-heavy, search-heavy operations
# Weight: 1 (less frequent but more expensive)
# ══════════════════════════════════════════════════════════════

class HeavyUser(DCMUser):
    weight    = 1
    wait_time = between(5, 15)   # heavier ops need more think time

    @task(3)
    def export_excel(self):
        """Download full Excel export — tests DB aggregation under load."""
        with self.client.get(
            "/api/export/excel",
            headers=self.auth_headers(),
            verify=False,
            name="GET /api/export/excel",
            stream=True,
            catch_response=True
        ) as r:
            content = r.content
            if r.status_code == 200 and len(content) > 1000:
                r.success()
            else:
                r.failure(f"Export failed: {r.status_code}, size={len(content)}")

    @task(2)
    def full_text_search(self):
        """Search across all data types."""
        terms = ["srv", "rack", "dell", "hp", "switch", "10g", "zone"]
        q = random.choice(terms)
        self.get(f"/api/assets?q={q}", name="GET /api/assets?q= [heavy]")
        self.get(f"/api/stock?q={q}",  name="GET /api/stock?q= [heavy]")
        self.get(f"/api/connectivity?q={q}", name="GET /api/connectivity?q= [heavy]")

    @task(1)
    def audit_log(self):
        """Fetch audit log — join-heavy DB query."""
        self.get("/api/audit?limit=100", name="GET /api/audit")

    @task(1)
    def dashboard_refresh(self):
        """Simulate a user repeatedly refreshing dashboard."""
        for _ in range(3):
            self.get("/api/stats", name="GET /api/stats [heavy]")

    @task(1)
    def check_multiple_slots(self):
        """Simulate rack view loading — multiple slot checks."""
        r = self.get("/api/racks", name="GET /api/racks [heavy]")
        if r.status_code == 200:
            racks = r.json()
            if racks:
                rack = random.choice(racks)
                rid = rack.get("rack_id")
                for u in random.sample(range(1, 43), min(5, 42)):
                    self.get(
                        f"/api/assets/check-slot?rack={rid}&ustart={u}&uheight=1",
                        name="GET /api/assets/check-slot [heavy]"
                    )
