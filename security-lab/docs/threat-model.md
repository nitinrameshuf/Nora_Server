# Threat Model — Mock ROS 2 Attack Surface

Artifact for the IEEE CPS-Sec submission. This document states what we assume,
what we attack, and — importantly — what this lab does **not** prove.

## System under test

A minimal cyber-physical control loop mirroring Nora's runtime:

- **Robot** (`nora_robot`) — publishes `/nora/telemetry`, executes velocity
  commands from `/nora/cmd`. Stand-in for the Jetson-hosted robot (ROS 2 Humble).
- **Mission control** (`mission_control`) — issues patrol commands, monitors
  telemetry. Stand-in for the cluster-side operator/bridge (Story 14).

Both use **default ROS 2 middleware**: RMW = FastDDS, no SROS2, no DDS-Security.
This is the configuration the vast majority of ROS 2 deployments actually run.

## Trust boundary

The trust boundary is the **DDS domain** (`ROS_DOMAIN_ID`). In the default
configuration, domain membership *is* the only access control: any participant
that can discover the domain may publish or subscribe to any topic. There is:

- no authentication of participants,
- no authorization per topic,
- no integrity or origin check on samples,
- no encryption on the wire (RTPS over UDP in cleartext).

## Adversary

**Assumed capability:** the adversary can run a ROS 2 participant on the same DDS
domain as the robot. In this lab that co-location is realised by placing the
attacker container in the same pod (see `docs/scenarios.md`, "Topology"). On real
hardware the equivalent foothold is any of: a compromised container/pod on the
robot network, a malicious node on the shared DDS segment, or an attacker who has
bypassed network segmentation to reach the robot's L2/L3 domain.

**Out of scope / explicitly NOT claimed:**

- We do not break DDS-Security/SROS2 crypto — we attack systems that don't use it.
- The falsification scenario is **not** a true in-path MITM (DDS is peer-to-peer;
  in-path interception needs ARP spoofing or traffic mirroring at the network
  layer). We demonstrate the achievable DDS-level equivalent — data injection /
  sensor spoofing — and say so plainly.
- No volumetric/DoS-at-scale claims; the rogue node demonstrates command
  override, not network flooding.

## Attacks demonstrated

| # | Scenario | Weakness (CWE) | Effect |
|---|---|---|---|
| A | Rogue node command injection | CWE-306 Missing Authentication for Critical Function | Attacker drives the robot outside its safety envelope; robot cannot distinguish attacker from operator |
| B | Telemetry falsification | CWE-345 Insufficient Verification of Data Authenticity | Operator sees forged "healthy" state; masks the real condition |

## Containment

The entire lab runs inside the `security-lab` namespace (Story 17) with a
default-deny NetworkPolicy and, per scenario, `ROS_LOCALHOST_ONLY=1` so RTPS
never leaves the pod. Isolation enforcement requires a policy-capable CNI
(Calico); see `deploy/scripts/12-verify-security-lab.sh`.
