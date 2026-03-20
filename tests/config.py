"""
DC Manager Pro — Test Configuration
====================================
Edit BASE_URL and credentials to match your deployment.
All tests use this config.
"""

import os

# ── Target server ──────────────────────────────────────────────
BASE_URL  = os.getenv("DCM_URL",      "https://192.168.86.130")
ADMIN_USER = os.getenv("DCM_USER",    "admin")
ADMIN_PASS = os.getenv("DCM_PASS",    "Admin@123")

# ── Test data prefix — keeps test records identifiable ─────────
TEST_PREFIX = "TEST-AUTO-"

# ── SSL — set False for self-signed cert ───────────────────────
VERIFY_SSL = False

# ── Timeouts ───────────────────────────────────────────────────
TIMEOUT = 30   # seconds per request
