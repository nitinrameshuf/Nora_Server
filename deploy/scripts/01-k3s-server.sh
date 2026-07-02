#!/usr/bin/env bash
# Story 3 (part 1) — install the k3s control plane.
# RUN ON: nora-edge (192.168.88.10), as a sudo-capable user.
set -euo pipefail

echo "==> Installing k3s server (traefik disabled — we use ingress-nginx)"
curl -sfL https://get.k3s.io | INSTALL_K3S_EXEC="server --disable traefik" sh -

echo
echo "==> Node token (needed by 02-k3s-agent.sh on the worker nodes):"
sudo cat /var/lib/rancher/k3s/server/node-token

cat <<'EOF'

Next steps:
  1. On nora-app1 and nora-app2, run:
       ./02-k3s-agent.sh 192.168.88.10 <TOKEN>
  2. Copy the kubeconfig to your dev machine:
       sudo cat /etc/rancher/k3s/k3s.yaml
     Save it as ~/.kube/config on the dev machine and replace
     127.0.0.1 with 192.168.88.10 in the server: line.
  3. Verify: kubectl get nodes
EOF
