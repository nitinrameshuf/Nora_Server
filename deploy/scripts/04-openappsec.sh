#!/usr/bin/env bash
# Story 6 — open-appsec WAF integrated with ingress-nginx.
# RUN ON: your dev machine (kubectl + helm).
#
# CAUTION: open-appsec's agent images may not publish linux/arm64 builds.
# Verify before running on the RPi cluster:
#   docker manifest inspect ghcr.io/openappsec/agent:latest | grep -i arm64
# If arm64 is unsupported, alternatives: ModSecurity (built into
# ingress-nginx, enable via controller config) — see fallback below.
set -euo pipefail

MODE="${1:-openappsec}"

if [ "$MODE" = "openappsec" ]; then
  echo "==> Installing open-appsec managed ingress-nginx integration"
  # Per https://docs.openappsec.io — the open-appsec chart replaces the
  # stock ingress-nginx controller with an attachment-enabled build.
  helm repo add openappsec https://charts.openappsec.io 2>/dev/null || true
  helm repo update
  helm upgrade --install open-appsec openappsec/open-appsec-k8s-nginx-ingress \
    --namespace ingress-nginx \
    --set appsec.mode=standalone \
    --set appsec.defaultPolicy.mode=prevent-learn \
    --wait
  echo "==> Done. Test with: curl 'http://nora.local/?q=<script>alert(1)</script>' (expect 403)"
else
  echo "==> Fallback: enabling ModSecurity + OWASP CRS in stock ingress-nginx"
  helm upgrade --install ingress-nginx ingress-nginx/ingress-nginx \
    --namespace ingress-nginx \
    --reuse-values \
    --set controller.config.enable-modsecurity="true" \
    --set controller.config.enable-owasp-modsecurity-crs="true" \
    --set controller.config.modsecurity-snippet="SecRuleEngine On" \
    --wait
  echo "==> Done. ModSecurity CRS active on all ingress traffic."
fi
