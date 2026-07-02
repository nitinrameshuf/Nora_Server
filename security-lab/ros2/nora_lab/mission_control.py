"""Mock mission control — the legitimate OPERATOR.

Sends a benign patrol command and watches telemetry. It also runs a naive
plausibility check, which is how the MITM / falsification scenario becomes
visible: when a second (attacker) publisher injects telemetry, mission control
sees contradictory or physically impossible state.
"""
import json

import rclpy
from geometry_msgs.msg import Twist
from rclpy.node import Node
from std_msgs.msg import String

from .common import TOPIC_CMD, TOPIC_TELEMETRY, command_qos, sensor_qos


class MissionControl(Node):
    def __init__(self):
        super().__init__("mission_control")
        self.last_battery = None
        self.last_seq = None

        self.cmd_pub = self.create_publisher(Twist, TOPIC_CMD, command_qos())
        self.create_subscription(String, TOPIC_TELEMETRY, self.on_telemetry, sensor_qos())
        self.create_timer(1.0, self.send_patrol)  # 1 Hz benign command
        self.get_logger().info("mission_control online — issuing patrol commands")

    def send_patrol(self):
        cmd = Twist()
        cmd.linear.x = 0.3   # gentle forward
        cmd.angular.z = 0.1  # slow arc
        self.cmd_pub.publish(cmd)

    def on_telemetry(self, msg: String):
        try:
            data = json.loads(msg.data)
        except json.JSONDecodeError:
            self.get_logger().warn("Malformed telemetry received (possible tampering)")
            return

        battery = data.get("battery")
        seq = data.get("seq")

        # Plausibility checks — cheap anomaly signals for the detection story.
        if self.last_battery is not None and battery is not None:
            if battery > self.last_battery + 0.5:
                self.get_logger().warn(
                    "ANOMALY: battery increased %.2f -> %.2f (impossible; "
                    "telemetry likely spoofed)" % (self.last_battery, battery)
                )
        if self.last_seq is not None and seq is not None and seq <= self.last_seq:
            self.get_logger().warn(
                "ANOMALY: telemetry seq went backwards/stalled %s -> %s "
                "(duplicate publisher on %s?)" % (self.last_seq, seq, TOPIC_TELEMETRY)
            )

        self.last_battery = battery
        self.last_seq = seq


def main():
    rclpy.init()
    node = MissionControl()
    try:
        rclpy.spin(node)
    except KeyboardInterrupt:
        pass
    finally:
        node.destroy_node()
        rclpy.try_shutdown()


if __name__ == "__main__":
    main()
