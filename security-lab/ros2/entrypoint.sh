#!/usr/bin/env bash
# Sources the ROS 2 Humble environment, then runs the requested lab node.
# Usage: entrypoint.sh <robot|mission-control|rogue|mitm>
set -e

source /opt/ros/humble/setup.bash

case "${1:-robot}" in
  robot)            exec python3 -m nora_lab.robot_node ;;
  mission-control)  exec python3 -m nora_lab.mission_control ;;
  rogue)            exec python3 -m nora_lab.rogue_node ;;
  mitm)             exec python3 -m nora_lab.mitm_node ;;
  shell)            exec bash ;;
  *)                echo "unknown role: $1" >&2; exit 2 ;;
esac
