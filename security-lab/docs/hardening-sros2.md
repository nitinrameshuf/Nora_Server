# Hardening — What Stops These Attacks (SROS2 / DDS-Security)

The lab attacks succeed because default ROS 2 has no participant authentication,
no per-topic authorization, and no sample integrity. **SROS2** (the tooling around
the DDS-Security spec) closes exactly these gaps. This document is the "mitigation"
half of the paper — the contrast that makes the attack results meaningful.

## The three DDS-Security plugins and which attack each stops

| Plugin | Provides | Stops |
|---|---|---|
| Authentication (PKI, per-participant certs) | only certified participants join the domain | the rogue node cannot join at all |
| Access Control (governance + permissions XML) | per-topic allow/deny for publish/subscribe | even a joined node can't publish `/nora/cmd` unless permitted |
| Cryptographic | encryption + authenticated tags on samples | forged/tampered telemetry is rejected; RTPS no longer cleartext |

## Minimal SROS2 workflow (for the mitigated run)

1. `ros2 security create_keystore <keystore>` — establishes the CA.
2. `ros2 security create_enclave <keystore> /nora/robot robot` (and one per node)
   — issues each node an identity cert + key.
3. Author `governance.xml` (domain-wide rules: authenticated, encrypted) and
   per-enclave `permissions.xml` (e.g. only `mission_control` may publish
   `/nora/cmd`; only `nora_robot` may publish `/nora/telemetry`).
4. Run with `ROS_SECURITY_ENABLE=true`,
   `ROS_SECURITY_STRATEGY=Enforce`, and `ROS_SECURITY_KEYSTORE=<keystore>`.

## Expected result under hardening

- Scenario A: the rogue enclave has no publish permission on `/nora/cmd` →
  its samples are dropped; `UNSAFE COMMAND EXECUTED` never fires.
- Scenario B: the attacker cannot publish authenticated `/nora/telemetry`
  samples → mission control rejects the forgeries; no `ANOMALY` warnings.

## Cost / caveats worth noting in the paper

- Certificate lifecycle and key distribution across nodes (and to the Jetson) is
  the real operational burden.
- DDS-Security adds per-sample crypto overhead — relevant on the Pi 5 / Jetson
  under high-rate telemetry; measure it if the paper claims practicality.
- A hardened counterpart deployment is left as future work here; the artifact's
  primary contribution is the reproducible *unmitigated* attack surface plus this
  concrete remediation path.
