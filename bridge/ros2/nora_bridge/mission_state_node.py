"""Mission state node — the bridge's core.

Subscribes to the robot's telemetry (same topic convention as the Jetson and the
Story 18 lab: /nora/telemetry, std_msgs/String JSON), persists it via StateStore,
and republishes an aggregated /nora/mission_state that other cluster-side
consumers (dashboards, Story 16 relay) can read without touching the raw feed.

Runs containerized on Node 2 with host networking so it shares the LAN DDS domain
with the Jetson (see bridge/README.md for why not k8s).
"""
import json
import time

import rclpy
from rclpy.node import Node
from std_msgs.msg import String

from .state_store import StateStore

TOPIC_TELEMETRY = "/nora/telemetry"
TOPIC_MISSION_STATE = "/nora/mission_state"
PRUNE_EVERY_S = 300.0
RETAIN_S = 7 * 24 * 3600.0  # keep a week of telemetry rows


class MissionStateNode(Node):
    def __init__(self):
        super().__init__("nora_mission_state")
        self.store = StateStore()
        self.started = time.time()
        self.last_seq = None
        self.last_rx = None
        self.msgs = 0
        self._last_prune = time.time()

        self.create_subscription(String, TOPIC_TELEMETRY, self.on_telemetry, 10)
        self.pub = self.create_publisher(String, TOPIC_MISSION_STATE, 10)
        self.create_timer(1.0, self.publish_state)
        self.get_logger().info(
            "mission_state bridging %s -> %s (persisting to SQLite)"
            % (TOPIC_TELEMETRY, TOPIC_MISSION_STATE)
        )

    def on_telemetry(self, msg: String):
        try:
            data = json.loads(msg.data)
        except json.JSONDecodeError:
            self.get_logger().warn("dropping malformed telemetry")
            return
        # Ignore forged samples from a Story-18-style falsifier if present.
        if data.get("source") not in (None, "robot"):
            return
        self.store.record_telemetry(data)
        self.last_seq = data.get("seq")
        self.last_rx = time.time()
        self.msgs += 1

        now = time.time()
        if now - self._last_prune > PRUNE_EVERY_S:
            self.store.prune(RETAIN_S)
            self._last_prune = now

    def publish_state(self):
        latest = self.store.latest_state()
        link = "up" if (self.last_rx and time.time() - self.last_rx < 5) else "stale"
        summary = {
            "bridge_uptime_s": round(time.time() - self.started, 1),
            "telemetry_msgs": self.msgs,
            "last_seq": self.last_seq,
            "link": link,
            "robot": latest,
        }
        out = String()
        out.data = json.dumps(summary)
        self.pub.publish(out)


def main():
    rclpy.init()
    node = MissionStateNode()
    try:
        rclpy.spin(node)
    except KeyboardInterrupt:
        pass
    finally:
        node.store.close()
        node.destroy_node()
        rclpy.try_shutdown()


if __name__ == "__main__":
    main()
