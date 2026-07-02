"""Mock Nora robot — the VICTIM.

Publishes telemetry and blindly executes any command that arrives on /nora/cmd.
It cannot tell an operator command from an attacker command, because in default
DDS there is no notion of an authenticated publisher. That is the vulnerability
the rogue-node scenario exploits.
"""
import json
import math

import rclpy
from geometry_msgs.msg import Twist
from rclpy.node import Node
from std_msgs.msg import String

from .common import TOPIC_CMD, TOPIC_TELEMETRY, command_qos, sensor_qos

# Above this commanded speed we consider the robot to be in an unsafe state —
# used purely to make attack impact visible in logs and captures.
UNSAFE_LINEAR = 1.5  # m/s


class RobotNode(Node):
    def __init__(self):
        super().__init__("nora_robot")
        self.seq = 0
        self.x = 0.0
        self.y = 0.0
        self.heading = 0.0
        self.battery = 100.0
        self.cmd_linear = 0.0
        self.cmd_angular = 0.0
        self.unsafe = False

        self.telemetry_pub = self.create_publisher(String, TOPIC_TELEMETRY, sensor_qos())
        self.create_subscription(Twist, TOPIC_CMD, self.on_cmd, command_qos())
        self.create_timer(0.5, self.tick)  # 2 Hz
        self.get_logger().info("nora_robot online — executing commands on %s" % TOPIC_CMD)

    def on_cmd(self, msg: Twist):
        self.cmd_linear = msg.linear.x
        self.cmd_angular = msg.angular.z
        if abs(self.cmd_linear) > UNSAFE_LINEAR and not self.unsafe:
            self.unsafe = True
            self.get_logger().warn(
                "UNSAFE COMMAND EXECUTED: linear.x=%.2f m/s (limit %.2f). "
                "No publisher identity available to authorize this." %
                (self.cmd_linear, UNSAFE_LINEAR)
            )

    def tick(self):
        # Integrate the last command into a simple pose.
        dt = 0.5
        self.heading += self.cmd_angular * dt
        self.x += self.cmd_linear * math.cos(self.heading) * dt
        self.y += self.cmd_linear * math.sin(self.heading) * dt
        self.battery = max(0.0, self.battery - 0.05)
        self.seq += 1

        payload = {
            "seq": self.seq,
            "x": round(self.x, 3),
            "y": round(self.y, 3),
            "heading": round(self.heading, 3),
            "battery": round(self.battery, 2),
            "cmd_linear": round(self.cmd_linear, 3),
            "unsafe": self.unsafe,
            "source": "robot",
        }
        msg = String()
        msg.data = json.dumps(payload)
        self.telemetry_pub.publish(msg)


def main():
    rclpy.init()
    node = RobotNode()
    try:
        rclpy.spin(node)
    except KeyboardInterrupt:
        pass
    finally:
        node.destroy_node()
        rclpy.try_shutdown()


if __name__ == "__main__":
    main()
