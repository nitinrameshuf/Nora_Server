#!/usr/bin/env bash
# Story 8 — RabbitMQ on nora-app2.
# RUN ON: your dev machine (kubectl).
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
K8S_DIR="${SCRIPT_DIR}/../k8s"

if ! kubectl get secret nora-rabbitmq -n nora >/dev/null 2>&1; then
  echo "ERROR: secret 'nora-rabbitmq' not found."
  echo "Copy deploy/k8s/secrets.example.yaml to secrets.yaml, edit it, then:"
  echo "  kubectl apply -f deploy/k8s/secrets.yaml"
  exit 1
fi

kubectl apply -f "${K8S_DIR}/rabbitmq.yaml"
kubectl rollout status statefulset/rabbitmq -n nora --timeout=300s

echo "==> RabbitMQ running. Management UI (from dev machine):"
echo "  kubectl port-forward -n nora svc/rabbitmq 15672:15672"
echo "  open http://localhost:15672"
