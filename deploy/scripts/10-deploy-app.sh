#!/usr/bin/env bash
# Stories 11 + 12 — build arm64 images, load them into k3s, deploy backend + frontend.
# RUN ON: your dev machine (docker with buildx, kubectl, ssh access to the nodes).
#
# There is no image registry in this setup: images are built locally for
# linux/arm64, streamed to each node over ssh, and imported into k3s
# containerd. Configure ssh vars below if your user/IPs differ.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "${SCRIPT_DIR}/../.." && pwd)"
K8S_DIR="${SCRIPT_DIR}/../k8s"

SSH_USER="${SSH_USER:-ubuntu}"
NODES=(${NODES:-192.168.88.10 192.168.88.11 192.168.88.12})

if ! kubectl get secret nora-backend -n nora >/dev/null 2>&1; then
  echo "ERROR: secret 'nora-backend' not found."
  echo "Copy deploy/k8s/secrets.example.yaml to secrets.yaml, edit it, then:"
  echo "  kubectl apply -f deploy/k8s/secrets.yaml"
  exit 1
fi

echo "==> Building linux/arm64 images"
docker buildx build --platform linux/arm64 -t nora/backend:latest --load "${ROOT_DIR}/backend"
docker buildx build --platform linux/arm64 -t nora/frontend:latest --load "${ROOT_DIR}/frontend"

for node in "${NODES[@]}"; do
  echo "==> Importing images into k3s on ${node}"
  docker save nora/backend:latest | ssh "${SSH_USER}@${node}" "sudo k3s ctr images import -"
  docker save nora/frontend:latest | ssh "${SSH_USER}@${node}" "sudo k3s ctr images import -"
done

echo "==> Applying manifests"
kubectl apply -f "${K8S_DIR}/backend.yaml"
kubectl apply -f "${K8S_DIR}/frontend.yaml"
kubectl rollout restart deployment/nora-backend deployment/nora-worker deployment/nora-frontend -n nora
kubectl rollout status deployment/nora-backend -n nora --timeout=300s
kubectl rollout status deployment/nora-frontend -n nora --timeout=300s

echo "==> Deployed. Add '192.168.88.10 nora.local' to /etc/hosts on your dev"
echo "    machine, then open http://nora.local (site) and http://nora.local/cms/ (admin)."
