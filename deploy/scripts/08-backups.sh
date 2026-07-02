#!/usr/bin/env bash
# Story 9 (part 2) — NFS-backed PostgreSQL backup CronJob (nightly, 14-day retention).
# RUN ON: your dev machine (kubectl). Requires 07-nfs-dell-server.sh done on the Dell.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
K8S_DIR="${SCRIPT_DIR}/../k8s"

kubectl apply -f "${K8S_DIR}/backup-nfs.yaml"

echo "==> Backup CronJob created (03:00 daily). Trigger a test run now:"
echo "  kubectl create job -n nora --from=cronjob/nora-db-backup nora-db-backup-manual"
echo "  kubectl logs -n nora job/nora-db-backup-manual -f"
echo "Then check the file exists on the Dell in /srv/nora-backups."
