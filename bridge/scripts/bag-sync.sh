#!/usr/bin/env bash
# Story 14 — sync completed ROS 2 bags from Node 2 to the Dell NFS share.
# Driven by the systemd timer (bridge/systemd/). Only syncs bags that are no
# longer being written to (mtime > 5 min) so we never copy a half-written bag.
set -euo pipefail

SRC="${BAG_SRC:-/var/lib/nora/bags}"
DEST="${BAG_DEST:-/mnt/nora-nfs/ros2-bags}"   # Dell NFS mount on Node 2
RETAIN_DAYS="${RETAIN_DAYS:-14}"

mkdir -p "$DEST"

# rsync each bag directory that hasn't changed in the last 5 minutes.
find "$SRC" -maxdepth 1 -mindepth 1 -type d -mmin +5 -print0 |
while IFS= read -r -d '' bag; do
    name="$(basename "$bag")"
    echo "syncing ${name}"
    rsync -a --ignore-existing "$bag/" "${DEST}/${name}/"
    # Once safely on NFS, drop the local copy to save Node 2 SSD.
    rm -rf "$bag"
done

# Retention on the NFS side.
find "$DEST" -maxdepth 1 -mindepth 1 -type d -mtime +"$RETAIN_DAYS" -exec rm -rf {} +
echo "bag-sync complete -> ${DEST}"
