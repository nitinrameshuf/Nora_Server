#!/usr/bin/env bash
# Story 10 — Wazuh agent install + registration.
# RUN ON: each RPi (nora-edge, nora-app1, nora-app2), as a sudo-capable user.
# Usage: ./09-wazuh-agent.sh <WAZUH_MANAGER_IP>
# (Wazuh manager itself is installed on the Dell via the official installer:
#   curl -sO https://packages.wazuh.com/4.9/wazuh-install.sh && sudo bash wazuh-install.sh -a )
set -euo pipefail

MANAGER_IP="${1:?usage: $0 <WAZUH_MANAGER_IP>}"

echo "==> Adding Wazuh apt repository"
sudo mkdir -p /usr/share/keyrings
curl -s https://packages.wazuh.com/key/GPG-KEY-WAZUH \
  | sudo gpg --dearmor --yes -o /usr/share/keyrings/wazuh.gpg
echo "deb [signed-by=/usr/share/keyrings/wazuh.gpg] https://packages.wazuh.com/4.x/apt/ stable main" \
  | sudo tee /etc/apt/sources.list.d/wazuh.list

echo "==> Installing wazuh-agent (manager: ${MANAGER_IP})"
sudo apt-get update
sudo WAZUH_MANAGER="${MANAGER_IP}" apt-get install -y wazuh-agent

sudo systemctl daemon-reload
sudo systemctl enable --now wazuh-agent

echo "==> Agent status:"
sudo systemctl status wazuh-agent --no-pager | head -5
echo "==> Verify the agent shows Active in the Wazuh dashboard on the Dell."
