#!/usr/bin/env bash
# Story 18 — run one attack scenario end to end and collect artifacts.
# RUN ON: your dev machine (kubectl). Requires the image built (00-build-image.sh)
# and the security-lab namespace present (Story 17).
#
# Usage: ./run-scenario.sh <baseline|rogue|mitm> [output-dir]
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
K8S_DIR="${SCRIPT_DIR}/../k8s"
NS=security-lab

SCENARIO="${1:?usage: $0 <baseline|rogue|mitm> [output-dir]}"
OUTDIR="${2:-${SCRIPT_DIR}/../artifacts/${SCENARIO}-$(date +%Y%m%d-%H%M%S)}"

case "$SCENARIO" in
  baseline) MANIFEST="${K8S_DIR}/00-baseline.yaml";      POD=nora-baseline;  CAPTURE=0 ;;
  rogue)    MANIFEST="${K8S_DIR}/10-scenario-rogue.yaml"; POD=scenario-rogue; CAPTURE=1 ;;
  mitm)     MANIFEST="${K8S_DIR}/11-scenario-mitm.yaml";  POD=scenario-mitm;  CAPTURE=1 ;;
  *) echo "unknown scenario: $SCENARIO" >&2; exit 2 ;;
esac

echo "==> Cleaning any previous run of ${POD}"
kubectl delete pod "$POD" -n "$NS" --ignore-not-found --wait=true

echo "==> Applying ${MANIFEST}"
kubectl apply -f "$MANIFEST"
kubectl wait --for=condition=Ready pod/"$POD" -n "$NS" --timeout=180s

echo
echo "==> Live logs (operator anomalies + attacker activity). Ctrl-C to stop tailing."
echo "    robot:"
kubectl logs "$POD" -n "$NS" -c robot --tail=5 || true

if [ "$CAPTURE" -eq 1 ]; then
  echo "==> Waiting for capture to finish (~90s)..."
  until kubectl exec "$POD" -n "$NS" -c capture -- test -f /artifacts/CAPTURE_DONE 2>/dev/null; do
    sleep 5
  done
  echo "==> Capture done. Collecting artifacts into ${OUTDIR}"
  mkdir -p "$OUTDIR"
  kubectl cp "${NS}/${POD}:artifacts" "$OUTDIR" -c capture
  # Save the human-readable logs alongside the raw capture.
  for c in robot mission-control $( [ "$SCENARIO" = rogue ] && echo attacker-rogue || echo attacker-mitm ); do
    kubectl logs "$POD" -n "$NS" -c "$c" > "${OUTDIR}/${c}.log" 2>/dev/null || true
  done
  echo "==> Artifacts:"
  ls -la "$OUTDIR"
  echo
  echo "Analyse: docs/scenarios.md explains what to look for in the bag/pcap/logs."
  echo "Tear down when finished:  kubectl delete pod ${POD} -n ${NS}"
else
  echo "Baseline running. Watch telemetry:"
  echo "  kubectl logs ${POD} -n ${NS} -c mission-control -f"
  echo "Tear down:  kubectl delete pod ${POD} -n ${NS}"
fi
