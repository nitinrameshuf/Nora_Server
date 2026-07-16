# Nora ROS 2 Bridge (Story 14)

Cluster-side bridge + state-persistence layer for the Nora robot. Runs on **Node 2
(nora-app1)** and joins the robot's DDS domain to ingest telemetry, persist mission
state, log events for the SIEM, and record ROS 2 bags that sync to the Dell NFS.

## Two design decisions (both load-bearing)

1. **Containerized ROS 2 Humble, not a native install.** The robot runs ROS 2
   Humble, whose Tier-1 platform is Ubuntu **22.04 (Jammy)**. The RPi baseline
   (Story 2) is Ubuntu **24.04 (Noble)**, which has no official Humble binaries.
   `ros:humble-ros-base` carries its own Jammy userspace, so the bridge runs
   Humble correctly on a Noble host. (arm64 image confirmed.)

2. **Docker Compose with `network_mode: host`, not a k8s pod.** DDS discovers the
   Jetson over the LAN via multicast + RTPS. k3s pod networking (CNI) would block
   that cross-host discovery, so the bridge runs directly on Node 2's host network,
   in the same `ROS_DOMAIN_ID` as the robot. This is the one Phase-2 component that
   intentionally sits outside the k8s cluster.

## Components

| Service | Node | Role |
|---|---|---|
| `mission-state` | `nora_mission_state` | subscribes `/nora/telemetry`, persists to SQLite (`/var/lib/nora`), republishes aggregated `/nora/mission_state` |
| `event-logger` | `nora_event_logger` | writes JSON-lines events to `/var/log/nora/events.log` for the Wazuh agent (battery-low, stale-link, unsafe-state) |
| `bag-recorder` | — | `ros2 bag record -a`, hourly rotation, into `/var/lib/nora/bags` |
| bag-sync timer | — | systemd timer rsyncs completed bags to Dell NFS, 14-day retention |

Topic conventions match the Story 18 lab and the Jetson: `/nora/telemetry`
(`std_msgs/String`, JSON).

## Deploy (on Node 2)

```sh
# ROS_DOMAIN_ID must match the robot/Jetson
ROS_DOMAIN_ID=42 ./scripts/install-node2.sh
```

Acceptance (Story 14): `nora_mission_state` and `nora_event_logger` appear in
`ros2 node list` run from the Jetson network.

## Status

CODE READY — nodes, container, compose, bag-sync + systemd units, and installer
written; Python nodes syntax-checked and the SQLite state store functionally
tested on the dev machine. Not yet run on Node 2 (needs the RPi + robot on the
DDS domain). Bridging live state into the web PostgreSQL for display is deferred
to Story 16.
