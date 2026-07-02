# Mock Nora ROS 2 nodes for the security lab (Story 18).
# ros-base is multi-arch (arm64 verified) and matches the robot's ROS 2 Humble.
FROM ros:humble-ros-base

# tcpdump for RTPS/DDS packet capture in the capture scenario; rest is in the base.
RUN apt-get update && apt-get install -y --no-install-recommends \
        tcpdump \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /opt/nora_lab
COPY nora_lab ./nora_lab
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

# Python can import nora_lab as a top-level package.
ENV PYTHONPATH=/opt/nora_lab

ENTRYPOINT ["/entrypoint.sh"]
CMD ["robot"]
