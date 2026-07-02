#!/usr/bin/env bash
# Story 17 — deploy the security-lab namespace and PROVE isolation.
# RUN ON: your dev machine (kubectl).
#
# IMPORTANT — k3s default CNI (Flannel) does NOT enforce NetworkPolicy.
# The manifests will apply without error but traffic will NOT be blocked.
# To get real enforcement, either:
#   a) install a policy-capable CNI such as Calico, or
#   b) bootstrap k3s with --flannel-backend=none and install Calico.
# This script detects whether a policy controller is present and FAILS LOUDLY
# if the acceptance criterion ("pods cannot reach other namespaces") can't hold.
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
K8S_DIR="${SCRIPT_DIR}/../k8s"

echo "==> Applying security-lab namespace + NetworkPolicies"
kubectl apply -f "${K8S_DIR}/security-lab.yaml"

echo "==> Checking for a NetworkPolicy-capable CNI"
if kubectl get pods -n kube-system 2>/dev/null | grep -qiE 'calico|cilium|kube-router|weave'; then
  echo "    OK: a policy-capable CNI is present."
  POLICY_ENFORCED=1
else
  echo "    WARNING: only Flannel detected. NetworkPolicy will NOT be enforced."
  echo "    Isolation test below is expected to FAIL until Calico/Cilium is installed."
  POLICY_ENFORCED=0
fi

echo "==> Launching test pods"
# victim in the default namespace, attacker inside security-lab
kubectl run iso-victim --image=nginx:alpine -n default \
  --labels=app=iso-victim --restart=Never --overwrite >/dev/null 2>&1 || true
kubectl run iso-attacker --image=nicolaka/netshoot -n security-lab \
  --restart=Never --overwrite --command -- sleep 3600 >/dev/null 2>&1 || true

kubectl wait --for=condition=Ready pod/iso-victim -n default --timeout=120s
kubectl wait --for=condition=Ready pod/iso-attacker -n security-lab --timeout=120s

VICTIM_IP=$(kubectl get pod iso-victim -n default -o jsonpath='{.status.podIP}')
echo "==> Victim pod IP (default ns): ${VICTIM_IP}"

echo "==> TEST 1: security-lab pod -> default-namespace pod (expect BLOCKED)"
if kubectl exec -n security-lab iso-attacker -- \
     curl -s --max-time 5 "http://${VICTIM_IP}" >/dev/null 2>&1; then
  echo "    REACHABLE — isolation NOT enforced."
  T1_BLOCKED=0
else
  echo "    blocked (connection timed out) — good."
  T1_BLOCKED=1
fi

echo "==> TEST 2: security-lab pod -> internet (expect BLOCKED)"
if kubectl exec -n security-lab iso-attacker -- \
     curl -s --max-time 5 "http://1.1.1.1" >/dev/null 2>&1; then
  echo "    REACHABLE — egress NOT blocked."
  T2_BLOCKED=0
else
  echo "    blocked — good."
  T2_BLOCKED=1
fi

echo "==> TEST 3: intra-namespace DNS resolution (expect WORKS)"
if kubectl exec -n security-lab iso-attacker -- \
     nslookup kubernetes.default.svc.cluster.local >/dev/null 2>&1; then
  echo "    DNS works — good."
  T3_OK=1
else
  echo "    DNS failed — allow-dns policy may be misconfigured."
  T3_OK=0
fi

echo "==> Cleaning up test pods"
kubectl delete pod iso-victim -n default --ignore-not-found >/dev/null 2>&1 &
kubectl delete pod iso-attacker -n security-lab --ignore-not-found >/dev/null 2>&1 &
wait

echo
echo "===================== RESULT ====================="
if [ "$POLICY_ENFORCED" -eq 1 ] && [ "$T1_BLOCKED" -eq 1 ] && [ "$T2_BLOCKED" -eq 1 ] && [ "$T3_OK" -eq 1 ]; then
  echo "PASS — security-lab is isolated (cross-ns + egress blocked, DNS intact)."
  exit 0
else
  echo "NOT ISOLATED YET."
  [ "$POLICY_ENFORCED" -eq 0 ] && echo "  - Install a policy-capable CNI (Calico) first; Flannel ignores NetworkPolicy."
  [ "$T1_BLOCKED" -eq 0 ] && echo "  - Cross-namespace traffic reached the victim."
  [ "$T2_BLOCKED" -eq 0 ] && echo "  - Egress to the internet was not blocked."
  [ "$T3_OK" -eq 0 ] && echo "  - DNS broke; loosen allow-dns, don't drop it."
  exit 1
fi
