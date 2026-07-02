#!/usr/bin/env bash
# Story 13 — end-to-end smoke test.
# RUN ON: your dev machine. Usage: ./11-smoke-test.sh [host]  (default: nora.local)
set -uo pipefail

HOST="${1:-nora.local}"
SCHEME="${SCHEME:-http}"
BASE="${SCHEME}://${HOST}"
PASS=0
FAIL=0

check() {
  local desc="$1" expected="$2" url="$3"
  local code
  code=$(curl -sk -o /dev/null -w '%{http_code}' --max-time 15 "$url")
  if [ "$code" = "$expected" ]; then
    echo "PASS  ${desc} (${code})"
    PASS=$((PASS + 1))
  else
    echo "FAIL  ${desc} — expected ${expected}, got ${code}  [${url}]"
    FAIL=$((FAIL + 1))
  fi
}

echo "== Smoke test against ${BASE} =="
check "Frontend homepage"        200 "${BASE}/"
check "Blog listing"             200 "${BASE}/blog"
check "Wagtail API"              200 "${BASE}/api/v2/pages/"
check "Wagtail admin login"      200 "${BASE}/cms/login/"
check "WAF blocks XSS probe"     403 "${BASE}/?q=<script>alert(1)</script>"

echo
echo "Manual checks remaining:"
echo "  - Create a blog post in ${BASE}/cms/ and confirm it appears at ${BASE}/blog"
echo "  - HTTPS cert valid once cloudflared/DNS is set up (Story 5)"
echo "  - Wazuh dashboard shows the requests"
echo "  - Backup file present on Dell: ls /srv/nora-backups"
echo
echo "== ${PASS} passed, ${FAIL} failed =="
[ "$FAIL" -eq 0 ]
