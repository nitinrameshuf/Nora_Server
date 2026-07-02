# Detection — Wiring the Attacks into Wazuh

Goal (Story 18 acceptance): show the attacks producing signals that Wazuh, on
the Dell (Story 10), can alert on. Detection has two layers.

## Layer 1 — Application-level anomaly logs (available now)

The mock nodes already emit structured warnings that are strong detection
signals:

| Log line | Emitted by | Indicates |
|---|---|---|
| `UNSAFE COMMAND EXECUTED: linear.x=...` | robot | out-of-envelope command accepted (Scenario A) |
| `ANOMALY: battery increased ...` | mission_control | physically impossible telemetry (Scenario B) |
| `ANOMALY: telemetry seq went backwards/stalled ...` | mission_control | duplicate publisher on a topic (Scenario B) |

**Pipeline:** ship the pod logs to Wazuh. Two options:
- k3s writes container stdout to `/var/log/pods/...` on nora-app2 — point the
  node's Wazuh agent `<localfile>` at that path, or
- run a lightweight forwarder (e.g. the Wazuh agent already on the node ingests
  the container log files).

**Custom Wazuh rules** (place in `/var/ossec/etc/rules/local_rules.xml` on the
manager): match `UNSAFE COMMAND EXECUTED` and `ANOMALY:` substrings, assign a
rule id in the local range (100000+), severity level 10–12. Example intent:

```
<rule id="100210" level="12">
  <match>UNSAFE COMMAND EXECUTED</match>
  <description>ROS2: robot executed an out-of-envelope command (possible injection)</description>
</rule>
<rule id="100211" level="10">
  <match>ANOMALY: battery increased</match>
  <description>ROS2: implausible telemetry (possible falsification)</description>
</rule>
```

This satisfies the acceptance criterion ("Wazuh logging attack traffic for
detection demo") with signals that are meaningful rather than raw packet noise.

## Layer 2 — Network / RTPS detection (stretch, needs the multi-pod variant)

With `ROS_LOCALHOST_ONLY=1` traffic stays on loopback and isn't visible to a
network sensor. In the multi-pod discovery-server variant, RTPS crosses the pod
network and can be inspected:

- **Suricata** on mirrored traffic with RTPS-aware rules, forwarded to Wazuh via
  the Suricata→Wazuh integration; alert on RTPS DATA on the command topic from an
  unexpected source IP, or on a new participant GUID.
- **Participant-inventory approach:** a monitor node records the set of known DDS
  participant GUIDs; a new/unknown GUID publishing to `/nora/cmd` is the rogue.
  Emit that as a log line and reuse the Layer 1 rule pattern.

Layer 2 is documented for completeness; the paper's reproducible detection result
rests on Layer 1.

## What to capture for the paper

For each scenario keep: the triggering `*.log`, the matching Wazuh alert JSON
(`/var/ossec/logs/alerts/alerts.json`), and the rosbag/pcap from
`collect-artifacts`. Together they show attack → host signal → SIEM alert.
