# Scenarios — Running and Interpreting the Attacks

## Topology (and why it's a single pod)

DDS discovery is multicast by default, and common k8s CNIs (k3s's Flannel) do
not forward multicast between pods. Rather than depend on a fragile multi-pod
discovery setup, each scenario runs all nodes as **containers in one pod**, which
share a network namespace. With `ROS_LOCALHOST_ONLY=1`, discovery and RTPS happen
over loopback and never leave the pod.

This is a deliberate simplification. It faithfully preserves the property under
test — *any participant on the domain has full pub/sub access with no auth* —
because the attacker is still a separate, independent ROS 2 participant. It does
**not** exercise cross-host network reachability.

**Multi-pod variant (documented, not default):** deploy a FastDDS Discovery
Server (unicast) as its own Deployment+Service, set
`ROS_DISCOVERY_SERVER=<svc>:11811` on every node, and drop `ROS_LOCALHOST_ONLY`.
This models an attacker reaching the discovery infrastructure across the network.
Left out of the default artifact because it cannot be verified without the
cluster and adds moving parts that distract from the core finding.

## Prerequisites

1. Story 17 applied: `kubectl apply -f deploy/k8s/security-lab.yaml`
2. Image built + loaded: `security-lab/scripts/00-build-image.sh`

## Baseline (known-good)

```
security-lab/scripts/run-scenario.sh baseline
kubectl logs nora-baseline -n security-lab -c mission-control -f
```

Expect: monotonic `seq`, battery decreasing slowly, no anomaly warnings.

## Scenario A — Rogue command injection

```
security-lab/scripts/run-scenario.sh rogue
```

What happens: `attacker-rogue` publishes `/nora/cmd` at 20 Hz with
`linear.x = 3.0 m/s`, out-publishing the operator's 1 Hz patrol command. The
robot executes it and logs `UNSAFE COMMAND EXECUTED`.

Evidence to cite in the paper (collected to `artifacts/rogue-*/`):
- `robot.log` — `UNSAFE COMMAND EXECUTED` entries.
- `attacker-rogue.log` — injection count, "no credentials used".
- `bag/` — replay `/nora/cmd` to show two publishers, attacker dominating.
- `rtps.pcap` — RTPS DATA submessages on the command topic from the extra writer.

## Scenario B — Telemetry falsification

```
security-lab/scripts/run-scenario.sh mitm
```

What happens: `attacker-mitm` subscribes to `/nora/telemetry`, then republishes a
forged copy (battery pinned to 99, pose frozen, `unsafe=false`) on the same
topic. `mission_control` receives both real and forged samples and logs
`ANOMALY: battery increased ...` / `seq went backwards`.

Evidence:
- `mission-control.log` — anomaly warnings triggered by the forged stream.
- `bag/` — two writers on `/nora/telemetry`; interleaved real vs forged battery.
- `attacker-mitm.log` — confirmation of what was forged.

### Honest scoping note
Scenario B is sensor **spoofing via a second publisher**, not in-path rewriting
of the operator's specific samples. A true in-path MITM would require redirecting
the victim's traffic (ARP spoofing / SPAN) at the network layer; in a CNI pod
network that is constrained and out of scope here. State this in the paper.

## Cleanup

```
kubectl delete pod nora-baseline scenario-rogue scenario-mitm -n security-lab --ignore-not-found
```
