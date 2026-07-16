"""Event logger node.

Turns the telemetry/mission-state streams into structured JSON-lines on disk that
the Node 2 Wazuh agent (Story 10) can ingest. Emits routine samples at low volume
plus explicit WARN events (battery low, link stale, unsafe flag) that map cleanly
to Wazuh rules — the same detection pattern used by the Story 18 lab.
"""
import json
import os
import time

import rclpy
from rclpy.node import Node
from std_msgs.msg import String

TOPIC_MISSION_STATE = "/nora/mission_state"
LOG_PATH = os.environ.get("NORA_EVENT_LOG", "/var/log/nora/events.log")
BATTERY_WARN = 20.0
SAMPLE_EVERY_S = 10.0


class EventLogger(Node):
    def __init__(self):
        super().__init__("nora_event_logger")
        os.makedirs(os.path.dirname(LOG_PATH), exist_ok=True)
        self._fh = open(LOG_PATH, "a", buffering=1)  # line-buffered
        self._last_sample = 0.0
        self._battery_warned = False
        self._link_warned = False

        self.create_subscription(String, TOPIC_MISSION_STATE, self.on_state, 10)
        self.get_logger().info("event_logger writing JSON-lines to %s" % LOG_PATH)

    def emit(self, level: str, event: str, **fields):
        record = {"ts": time.time(), "level": level, "event": event, **fields}
        self._fh.write(json.dumps(record) + "\n")
        if level != "INFO":
            self.get_logger().warn("%s: %s" % (event, fields))

    def on_state(self, msg: String):
        try:
            state = json.loads(msg.data)
        except json.JSONDecodeError:
            return
        robot = state.get("robot") or {}
        battery = robot.get("battery")
        link = state.get("link")

        # Threshold events (edge-triggered so we don't spam).
        if battery is not None:
            if battery <= BATTERY_WARN and not self._battery_warned:
                self.emit("WARN", "battery_low", battery=battery)
                self._battery_warned = True
            elif battery > BATTERY_WARN + 5:
                self._battery_warned = False

        if link == "stale" and not self._link_warned:
            self.emit("WARN", "telemetry_link_stale", last_seq=state.get("last_seq"))
            self._link_warned = True
        elif link == "up" and self._link_warned:
            self.emit("INFO", "telemetry_link_restored", last_seq=state.get("last_seq"))
            self._link_warned = False

        if robot.get("unsafe"):
            self.emit("WARN", "robot_unsafe_state", cmd_linear=robot.get("cmd_linear"))

        # Periodic heartbeat sample.
        now = time.time()
        if now - self._last_sample >= SAMPLE_EVERY_S:
            self._last_sample = now
            self.emit("INFO", "sample", battery=battery, link=link,
                      last_seq=state.get("last_seq"))


def main():
    rclpy.init()
    node = EventLogger()
    try:
        rclpy.spin(node)
    except KeyboardInterrupt:
        pass
    finally:
        node._fh.close()
        node.destroy_node()
        rclpy.try_shutdown()


if __name__ == "__main__":
    main()
