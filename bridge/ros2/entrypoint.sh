#!/usr/bin/env bash
# Sources ROS 2 Humble, then runs the requested bridge node.
# Usage: entrypoint.sh <mission-state|event-logger|shell>
set -e

source /opt/ros/humble/setup.bash

case "${1:-mission-state}" in
  mission-state) exec python3 -m nora_bridge.mission_state_node ;;
  event-logger)  exec python3 -m nora_bridge.event_logger_node ;;
  shell)         exec bash ;;
  *)             echo "unknown role: $1" >&2; exit 2 ;;
esac
