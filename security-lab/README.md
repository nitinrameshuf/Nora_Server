# Nora Security Lab — Mock ROS 2 Attack Surface (Story 18)

Reproducible artifact for the IEEE CPS-Sec submission: a minimal ROS 2 control
loop (robot + operator) plus two attacks that exploit the lack of authentication
in default ROS 2 / DDS, all contained in the isolated `security-lab` namespace
(Story 17).

> **Scope honesty:** this demonstrates attacks against *unauthenticated* ROS 2 —
> the common default — and the SROS2 remediation. It does not break DDS-Security
> crypto, and the "MITM" scenario is DDS-level data injection, not in-path
> rewriting. See `docs/threat-model.md` and `docs/scenarios.md` for exact scope.

## Layout

```
ros2/                 ROS 2 Humble nodes + Dockerfile
  nora_lab/
    robot_node.py       victim robot (executes any /nora/cmd)
    mission_control.py  operator (patrol cmd + telemetry anomaly checks)
    rogue_node.py       attacker A — command injection (CWE-306)
    mitm_node.py        attacker B — telemetry falsification (CWE-345)
k8s/                  one pod per scenario (baseline / rogue / mitm) + capture
scripts/              00-build-image.sh, run-scenario.sh
docs/                 threat-model, scenarios, wazuh-detection, hardening-sros2
artifacts/            (gitignored) collected bags/pcaps/logs per run
```

## Quickstart (on the cluster)

```sh
# 0. namespace + isolation (Story 17), needs a policy-capable CNI to enforce
kubectl apply -f ../deploy/k8s/security-lab.yaml

# 1. build the arm64 image and load it onto nora-app2
./scripts/00-build-image.sh

# 2. sanity check, then run the attacks (artifacts auto-collected)
./scripts/run-scenario.sh baseline
./scripts/run-scenario.sh rogue
./scripts/run-scenario.sh mitm
```

## Status

CODE READY — nodes, containers, manifests, scripts, and docs are written and
Python-syntax-checked on the dev machine. Not yet run on the cluster (needs
Stories 2–4 + 17, and a policy CNI for real isolation). Base image
`ros:humble-ros-base` confirmed multi-arch (arm64).

## Maps to Story 18 acceptance criteria

| Criterion | Where |
|---|---|
| Mock ROS 2 robot endpoints | `ros2/nora_lab/robot_node.py`, `mission_control.py` |
| Rogue node injection scenario | `rogue_node.py` + `k8s/10-scenario-rogue.yaml` |
| MITM on ROS 2 topics | `mitm_node.py` + `k8s/11-scenario-mitm.yaml` (scoped: see docs) |
| Attack tooling + captured artefacts | `scripts/run-scenario.sh` → `artifacts/` (bag + pcap + logs) |
| Wazuh logging for detection demo | `docs/wazuh-detection.md` |
