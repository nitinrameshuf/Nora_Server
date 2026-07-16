# Story 14 — ROS 2 Humble bridge for Node 2 (nora-app1).
# ros:humble-ros-base is Ubuntu 22.04 (Jammy) based, so it runs Humble correctly
# even though the Node 2 host is Ubuntu 24.04 (Noble), which has no native Humble.
# Multi-arch (arm64 verified) for the Raspberry Pi 5.
FROM ros:humble-ros-base

WORKDIR /opt/nora_bridge
COPY nora_bridge ./nora_bridge
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

ENV PYTHONPATH=/opt/nora_bridge
ENTRYPOINT ["/entrypoint.sh"]
CMD ["mission-state"]
