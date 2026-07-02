#!/usr/bin/env bash
# Story 3 (part 2) — join a worker node to the cluster.
# RUN ON: nora-app1 and nora-app2, as a sudo-capable user.
# Usage: ./02-k3s-agent.sh <SERVER_IP> <TOKEN>
set -euo pipefail

SERVER_IP="${1:?usage: $0 <SERVER_IP> <TOKEN>}"
TOKEN="${2:?usage: $0 <SERVER_IP> <TOKEN>}"

echo "==> Joining k3s cluster at ${SERVER_IP}"
curl -sfL https://get.k3s.io | K3S_URL="https://${SERVER_IP}:6443" K3S_TOKEN="${TOKEN}" sh -

echo "==> Done. Verify from the control plane / dev machine: kubectl get nodes"
