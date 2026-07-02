#!/usr/bin/env bash
# Story 4 — ingress-nginx, cert-manager, node labels, storage check.
# RUN ON: your dev machine (needs kubectl + helm pointed at the cluster).
set -euo pipefail

echo "==> Labelling app nodes (used by the PostgreSQL cluster affinity)"
kubectl label node nora-app1 nora.role=app --overwrite
kubectl label node nora-app2 nora.role=app --overwrite

echo "==> Installing ingress-nginx (pinned to nora-edge)"
helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
helm repo update
helm upgrade --install ingress-nginx ingress-nginx/ingress-nginx \
  --namespace ingress-nginx --create-namespace \
  --set controller.nodeSelector."kubernetes\.io/hostname"=nora-edge \
  --wait

echo "==> Installing cert-manager"
helm repo add jetstack https://charts.jetstack.io
helm repo update
helm upgrade --install cert-manager jetstack/cert-manager \
  --namespace cert-manager --create-namespace \
  --set crds.enabled=true \
  --wait

echo "==> Verifying k3s local-path StorageClass"
kubectl get storageclass local-path

echo "==> Done. Ingress controller:"
kubectl get pods -n ingress-nginx -o wide
