#!/usr/bin/env bash
# Story 9 (part 1) — NFS server on the Dell.
# RUN ON: nora-siem (Dell, 192.168.88.20), as a sudo-capable user.
set -euo pipefail

EXPORT_DIR="/srv/nora-backups"
SUBNET="192.168.88.0/24"

echo "==> Installing NFS server"
sudo apt-get update
sudo apt-get install -y nfs-kernel-server

echo "==> Creating export directory ${EXPORT_DIR}"
sudo mkdir -p "${EXPORT_DIR}"
sudo chown nobody:nogroup "${EXPORT_DIR}"

if ! grep -q "${EXPORT_DIR}" /etc/exports; then
  echo "${EXPORT_DIR} ${SUBNET}(rw,sync,no_subtree_check,no_root_squash)" | sudo tee -a /etc/exports
fi

sudo exportfs -ra
sudo systemctl enable --now nfs-kernel-server

echo "==> Exported:"
sudo exportfs -v
echo "==> Next: run 08-backups.sh from the dev machine to create the backup CronJob."
