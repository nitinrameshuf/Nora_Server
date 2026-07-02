"""Shared helpers for the mock Nora ROS2 nodes.

The whole point of this lab is that *default* ROS2 / DDS has no authentication or
encryption: every participant that shares a ROS_DOMAIN_ID can publish and
subscribe to any topic. These helpers deliberately use that default,
unauthenticated configuration so the attack scenarios are meaningful. The
hardened counterpart (SROS2 / DDS-Security) is described in
docs/hardening-sros2.md.
"""
import os

from rclpy.qos import QoSDurabilityPolicy, QoSHistoryPolicy, QoSProfile, QoSReliabilityPolicy

# Topics used across the lab.
TOPIC_TELEMETRY = "/nora/telemetry"  # std_msgs/String, JSON payload
TOPIC_CMD = "/nora/cmd"              # geometry_msgs/Twist, velocity command


def sensor_qos() -> QoSProfile:
    """Best-effort, keep-last: typical for high-rate sensor/telemetry streams."""
    return QoSProfile(
        reliability=QoSReliabilityPolicy.BEST_EFFORT,
        durability=QoSDurabilityPolicy.VOLATILE,
        history=QoSHistoryPolicy.KEEP_LAST,
        depth=10,
    )


def command_qos() -> QoSProfile:
    """Reliable, keep-last: commands should not be silently dropped."""
    return QoSProfile(
        reliability=QoSReliabilityPolicy.RELIABLE,
        durability=QoSDurabilityPolicy.VOLATILE,
        history=QoSHistoryPolicy.KEEP_LAST,
        depth=10,
    )


def domain_id() -> int:
    return int(os.environ.get("ROS_DOMAIN_ID", "0"))
