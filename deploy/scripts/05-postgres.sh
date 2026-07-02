#!/usr/bin/env bash
# Story 7 — CloudNativePG operator + 2-instance cluster (primary + replica).
# RUN ON: your dev machine (kubectl + helm).
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
K8S_DIR="${SCRIPT_DIR}/../k8s"

echo "==> Installing CloudNativePG operator"
helm repo add cnpg https://cloudnative-pg.github.io/charts
helm repo update
helm upgrade --install cnpg cnpg/cloudnative-pg \
  --namespace cnpg-system --create-namespace --wait

echo "==> Creating namespace + PostgreSQL cluster"
kubectl apply -f "${K8S_DIR}/namespace.yaml"
kubectl apply -f "${K8S_DIR}/postgres-cluster.yaml"

echo "==> Waiting for cluster to become ready (this can take a few minutes)"
kubectl wait --for=condition=Ready cluster/nora-db -n nora --timeout=600s

echo "==> Cluster status:"
kubectl get cluster,pods -n nora
echo
echo "App credentials are in secret 'nora-db-app' (namespace nora)."
echo "Primary service: nora-db-rw   Read replicas: nora-db-ro"
