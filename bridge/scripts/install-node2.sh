#!/usr/bin/env bash
# Story 14 — deploy the ROS 2 Humble bridge on Node 2 (nora-app1).
# RUN ON: nora-app1 (Ubuntu 24.04), as a sudo-capable user.
#
# Prereqs: Docker installed (RPi baseline / Story 2), and the Dell NFS share
# mounted at $BAG_DEST's parent (Story 9). Set ROS_DOMAIN_ID to match the robot.
set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
INSTALL_DIR=/opt/nora/bridge
ROS_DOMAIN_ID="${ROS_DOMAIN_ID:-0}"

command -v docker >/dev/null || { echo "Docker not installed (do Story 2 first)"; exit 1; }

echo "==> Installing bridge to ${INSTALL_DIR}"
sudo mkdir -p "$INSTALL_DIR"
sudo cp -r "$REPO_DIR/ros2" "$REPO_DIR/docker-compose.yml" "$REPO_DIR/scripts" "$INSTALL_DIR/"
sudo mkdir -p /var/lib/nora/bags /var/log/nora

echo "==> Building + starting bridge (ROS_DOMAIN_ID=${ROS_DOMAIN_ID})"
cd "$INSTALL_DIR"
sudo ROS_DOMAIN_ID="$ROS_DOMAIN_ID" docker compose up -d --build

echo "==> Installing bag-sync systemd timer"
sudo cp "$REPO_DIR/systemd/nora-bag-sync.service" /etc/systemd/system/
sudo cp "$REPO_DIR/systemd/nora-bag-sync.timer" /etc/systemd/system/
sudo systemctl daemon-reload
sudo systemctl enable --now nora-bag-sync.timer

echo
echo "==> Done. Verify:"
echo "  sudo docker compose -f ${INSTALL_DIR}/docker-compose.yml ps"
echo "  source /opt/ros/humble/setup.bash 2>/dev/null; ROS_DOMAIN_ID=${ROS_DOMAIN_ID} \\"
echo "    sudo docker exec -it nora-bridge-mission-state-1 bash -lc 'source /opt/ros/humble/setup.bash && ros2 node list'"
echo "  (Acceptance: nora_mission_state + nora_event_logger visible in ros2 node list from the Jetson network.)"
echo "  systemctl status nora-bag-sync.timer"
