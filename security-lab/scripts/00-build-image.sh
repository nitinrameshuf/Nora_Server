#!/usr/bin/env bash
# Story 18 — build the ROS 2 lab image (arm64) and import it into k3s on nora-app2.
# RUN ON: your dev machine (docker buildx + ssh to the node). The scenario pods
# are pinned to nora-app2, so the image only needs to exist there.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CTX="${SCRIPT_DIR}/../ros2"

SSH_USER="${SSH_USER:-ubuntu}"
NODE="${NODE:-192.168.88.12}" # nora-app2

echo "==> Building nora/ros2-lab:latest (linux/arm64)"
docker buildx build --platform linux/arm64 -t nora/ros2-lab:latest --load "${CTX}"

echo "==> Importing image into k3s containerd on ${NODE}"
docker save nora/ros2-lab:latest | ssh "${SSH_USER}@${NODE}" "sudo k3s ctr images import -"

echo "==> Done. Ensure the security-lab namespace exists (Story 17):"
echo "    kubectl apply -f deploy/k8s/security-lab.yaml"
