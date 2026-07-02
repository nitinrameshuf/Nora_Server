#!/usr/bin/env bash
# Story 5 — one-time interactive Cloudflare Tunnel setup.
# RUN ON: your dev machine (needs the `cloudflared` CLI + a Cloudflare account
#          with the target zone already added). kubectl must point at the cluster.
#
# Usage:
#   DOMAIN=nora.example.com TUNNEL_NAME=nora ./13-cloudflared-setup.sh
#
# What this does (and why it must be interactive once):
#   1. `cloudflared login` opens a browser so you authorise the specific zone.
#      This is the ONLY manual step and cannot be automated — it's your account.
#   2. Creates a named tunnel; Cloudflare returns a tunnel UUID + a credentials
#      JSON (the tunnel's private key). That JSON is the secret we mount in k8s.
#   3. Creates the public DNS records (CNAME -> <uuid>.cfargotunnel.com).
#   4. Loads the credentials into a k8s secret and renders the config with the
#      real tunnel ID + hostname, then applies deploy/k8s/cloudflared.yaml.
set -euo pipefail

DOMAIN="${DOMAIN:?set DOMAIN=your.domain}"
TUNNEL_NAME="${TUNNEL_NAME:-nora}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
K8S_DIR="${SCRIPT_DIR}/../k8s"

command -v cloudflared >/dev/null || {
  echo "cloudflared CLI not found. Install: https://developers.cloudflare.com/cloudflare-one/connections/connect-networks/downloads/"
  exit 1
}

echo "==> Step 1/5: authorise the zone (a browser window will open)"
cloudflared tunnel login

echo "==> Step 2/5: create tunnel '${TUNNEL_NAME}' (idempotent)"
cloudflared tunnel create "${TUNNEL_NAME}" 2>/dev/null || true
TUNNEL_ID=$(cloudflared tunnel list --output json | \
  /usr/bin/env python3 -c "import json,sys;print(next(t['id'] for t in json.load(sys.stdin) if t['name']=='${TUNNEL_NAME}'))")
CRED_FILE="${HOME}/.cloudflared/${TUNNEL_ID}.json"
echo "    tunnel id: ${TUNNEL_ID}"

echo "==> Step 3/5: create DNS routes"
cloudflared tunnel route dns "${TUNNEL_NAME}" "${DOMAIN}" || true
cloudflared tunnel route dns "${TUNNEL_NAME}" "*.${DOMAIN}" || true

echo "==> Step 4/5: create namespace + credentials secret in k8s"
kubectl create namespace cloudflared --dry-run=client -o yaml | kubectl apply -f -
kubectl create secret generic cloudflared-credentials \
  --namespace cloudflared \
  --from-file=credentials.json="${CRED_FILE}" \
  --dry-run=client -o yaml | kubectl apply -f -

echo "==> Step 5/5: render config with real tunnel id + hostname, then deploy"
TMP=$(mktemp)
sed -e "s/<TUNNEL_ID>/${TUNNEL_ID}/g" \
    -e "s/nora.example.com/${DOMAIN}/g" \
    "${K8S_DIR}/cloudflared.yaml" > "${TMP}"
kubectl apply -f "${TMP}"
rm -f "${TMP}"

kubectl rollout status deployment/cloudflared -n cloudflared --timeout=120s
echo
echo "==> Done. In ~1 minute https://${DOMAIN} should resolve globally through the tunnel."
echo "    Verify: curl -sI https://${DOMAIN} | head -1"
echo "    No inbound ports were opened on your network."
