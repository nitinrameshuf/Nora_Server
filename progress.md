## Document Maintenance Protocol

> Instructions for keeping this file current. Follow these every time a story completes or a significant decision is made.

### When to Update

Update this file at the end of every story, and immediately when any of the following happen:
- An architecture decision is made or reversed
- A critical learning or workaround is discovered
- A story is completed, blocked, or reprioritized
- A new issue is found or an existing one is resolved
- The story roadmap changes

### Rules

**Never delete content.** If something is superseded, move it to the [Retired Ideas](#retired-ideas) section at the bottom with a `[RETIRED]` prefix and a brief explanation of why it was retired. Preserve the original content in full — do not summarize it.

**Story completions:** Change the story status to COMPLETE. Fill in:
- Git commit message
- Actual time taken
- What was actually built (may differ from the plan)
- Blockers encountered and how they were resolved
- Key files created

**New learnings:** Add a numbered entry to Critical Learnings & Workarounds. Include problem, root cause, fix, and a one-line lesson. Never overwrite an existing learning — if a previous approach was wrong, keep it and add a correction note below it.

**Roadmap changes:** Update the Story Roadmap table. Move displaced stories or descriptions to Retired Ideas in full — do not summarize.

**Current Issues:** Remove resolved issues. Add new ones with severity labels (ACTIVE BLOCKER / LOW PRIORITY).

**File Structure:** Keep in sync with the actual repo. Add or remove files as they change.

### What to Tell Claude When Updating

Upload progress.md, describe what changed, then say:
> "Update progress.md, patch only: [story N complete / new learning / roadmap change]"

Always include:
> "Do not remove any content. Move anything superseded to the Retired Ideas section at the bottom, preserved in full."

**Patch only** means Claude makes targeted edits to changed sections only — no full file rewrite. Claude will present the updated file once at the end for download. Drop it in the repo and commit.

### Header Fields — Always Update

```
**Last Updated:** YYYY-MM-DD
**Project Status:** Story N Complete, Story N+1 Next (description)
```

---

**Last Updated:** 2026-07-02
**Project Status:** All software-buildable stories are CODE READY. Web app (11, 12) locally verified end-to-end; deploy scripts (3–4, 6–10, 13) written; cloudflared config (5) ready; security lab (17) + ROS 2 attack surface (18) + ROS 2 bridge (14) scaffolded and statically validated. Remaining work is hardware-gated: physical setup (1, 2), Cloudflare account (5), and on-cluster/robot runs for the Phase 2 ROS 2 stories (14–18). Stories 15, 16 need the Jetson. **Hardware now available (2026-07-02):** 3× RPi 5 on Ubuntu 24.04, Dell with Wazuh working, MikroTik with static IPs (IPs not yet read). Next unblocked steps: read the IPs, then Story 2 hardening + Story 3 k3s bootstrap.

---

## Project: Nora Infrastructure

### Hardware Inventory

> **Current physical state (2026-07-02):** 3× RPi 5 running Ubuntu 24.04 Server, 1× Dell with Wazuh installed and working, all on a MikroTik router with static IPs assigned. **The IPs below are the *planned* scheme — actual reserved IPs are not yet confirmed.** Deploy scripts hardcode this scheme (e.g. `192.168.88.10` control plane, `192.168.88.12` app2, `192.168.88.20` Dell NFS); reconcile them with the real reservations once the MikroTik leases are read. See Current Issues.


| Device | Specs | Hostname | IP | Role |
|---|---|---|---|---|
| RPi 5 — Node 1 | 8GB RAM, 128GB SSD | nora-edge | 192.168.88.10 | k3s control plane, cloudflared, openappsec WAF, ingress |
| RPi 5 — Node 2 | 8GB RAM, 128GB SSD | nora-app1 | 192.168.88.11 | k3s worker, Django/Wagtail app, PostgreSQL primary |
| RPi 5 — Node 3 | 8GB RAM, 128GB SSD | nora-app2 | 192.168.88.12 | k3s worker, app replica, PostgreSQL replica, RabbitMQ |
| Dell Laptop | 32GB RAM, 1TB SSD | nora-siem | 192.168.88.20 / 192.168.1.x | Wazuh SIEM, NFS backup, jumphost (dual-homed) |
| MikroTik Router | — | — | 192.168.88.1 | Gateway, DHCP, future VLAN segmentation |
| Jetson Orin Nano Super | 8GB | — | TBD | Nora perception + inference (Phase 2) |

### Locked Stack

| Layer | Technology |
|---|---|
| Backend | Django + Wagtail |
| Frontend | TypeScript + Node (headless Wagtail) |
| Database | PostgreSQL — primary Node 2, replica Node 3 |
| Queue | RabbitMQ — Node 3 |
| Orchestration | k3s — 3 node cluster |
| Ingress | ingress-nginx |
| WAF | openappsec (ingress-nginx plugin) |
| Tunnel | cloudflared — Node 1 |
| SIEM | Wazuh — Dell, agents on all RPis |
| Backup | NFS — RPis to Dell |
| Video | Self-hosted 720p (< 5 concurrent viewers expected) |

---

## File Structure

```
backend/                  Django + Wagtail headless CMS (Story 11)
  nora/                   settings, urls, wsgi, celery, API router
  cms/                    page models (Home, BlogIndex/Blog, DesignPlanIndex/DesignPlan),
                          migrations (incl. homepage bootstrap), admin-preview templates
  Dockerfile, entrypoint.sh, requirements.txt
frontend/                 Next.js 15 + TypeScript frontend (Story 12)
  app/                    home, /blog, /blog/[slug], /design-plans, /design-plans/[slug]
  lib/wagtail.ts          Wagtail API client
  components/VideoEmbed.tsx  YouTube embed support
  Dockerfile (standalone output)
deploy/
  k8s/                    namespace, secrets.example, postgres-cluster (CNPG),
                          rabbitmq, backend, frontend, backup-nfs,
                          security-lab (Story 17), cloudflared (Story 5) manifests
  scripts/                01–13 numbered setup scripts, mapped to stories (see README):
                          01/02 k3s, 03 tooling, 04 WAF, 05 postgres, 06 rabbitmq,
                          07/08 NFS+backups, 09 wazuh, 10 deploy app, 11 smoke test,
                          12 security-lab verify, 13 cloudflared setup
bridge/                   Story 14 — ROS 2 Humble bridge on Node 2 (containerized, host-net)
  ros2/nora_bridge/       mission_state_node, event_logger_node, state_store (SQLite)
  docker-compose.yml      host-network compose: mission-state + event-logger + bag-recorder
  scripts/                install-node2.sh, bag-sync.sh
  systemd/                nora-bag-sync .service + .timer (15 min → Dell NFS)
security-lab/             Story 18 — mock ROS 2 attack surface (paper artifact)
  ros2/nora_lab/          robot, mission_control, rogue, mitm nodes (ROS 2 Humble)
  ros2/Dockerfile         ros:humble-ros-base + nodes + tcpdump
  k8s/                    baseline + rogue + mitm scenario pods (co-located, loopback DDS)
  scripts/                00-build-image.sh, run-scenario.sh
  docs/                   threat-model, scenarios, wazuh-detection, hardening-sros2
  artifacts/              (gitignored) collected bags/pcaps/logs
docker-compose.yml        local dev: postgres + rabbitmq + backend + worker + frontend
README.md                 run order and quickstart
progress.md               this file
```

---

## Story Roadmap

| Story | Title | Phase | Status |
|---|---|---|---|
| 1 | MikroTik DHCP reservations | Phase 1 | LIKELY DONE — static IPs configured on MikroTik; actual IPs not yet documented / reboot-verified |
| 2 | RPi OS baseline — all 3 nodes | Phase 1 | PARTIAL — Ubuntu 24.04 Server confirmed on all 3; hostnames / SSH hardening / ufw / updates / Wazuh agent unconfirmed |
| 3 | k3s cluster bootstrap | Phase 1 | CODE READY — `deploy/scripts/01`, `02` |
| 4 | Cluster tooling — ingress-nginx, cert-manager, PVs | Phase 1 | CODE READY — `deploy/scripts/03` |
| 5 | cloudflared tunnel + DNS | Phase 1 | CONFIG READY — `deploy/k8s/cloudflared.yaml` + `deploy/scripts/13`; one manual browser login remains |
| 6 | openappsec WAF deployment | Phase 1 | DECIDED: open-appsec (not ModSecurity). Target = amd64 on the Xeon blade where images are current; arm64 Pi = stale beta only. See Architecture Decisions. |
| 7 | PostgreSQL primary + replica | Phase 1 | CODE READY — `deploy/scripts/05` + `deploy/k8s/postgres-cluster.yaml` |
| 8 | RabbitMQ deployment | Phase 1 | CODE READY — `deploy/scripts/06` + `deploy/k8s/rabbitmq.yaml` |
| 9 | NFS backup mount — RPis to Dell | Phase 1 | CODE READY — `deploy/scripts/07`, `08` |
| 10 | Wazuh agents on all RPis | Phase 1 | PARTIAL — Wazuh manager installed + working on Dell; RPi agent registration pending (`deploy/scripts/09`) |
| 11 | Django + Wagtail deployment | Phase 1 | CODE READY + LOCALLY VERIFIED — full stack in docker compose |
| 12 | TypeScript frontend — headless Wagtail | Phase 1 | CODE READY + LOCALLY VERIFIED — builds, renders CMS content end-to-end |
| 13 | End-to-end smoke test — site live on domain | Phase 1 | CODE READY — `deploy/scripts/11-smoke-test.sh` (LAN/domain run pending cluster) |
| 14 | ROS2 bridge node — Node 2 | Phase 2 | CODE READY — `bridge/` (ROS 2 Humble, containerized, host-net); on-cluster run pending |
| 15 | Jetson ↔ Node 2 DDS discovery | Phase 2 | TODO |
| 16 | Nora telemetry relay + ROS2 bag backup to Dell | Phase 2 | TODO |
| 17 | Security lab namespace — Node 3 | Phase 2 | CODE READY — `deploy/k8s/security-lab.yaml` + `deploy/scripts/12` (needs Calico, see Current Issues) |
| 18 | Mock ROS2 attack surface — IEEE CPS-Sec paper artifact | Phase 2 | CODE READY — `security-lab/` (nodes, scenarios, capture, docs) |

**CODE READY** = code/scripts written and validated where possible on the dev machine; story completes only after it runs successfully on the cluster and acceptance criteria pass.

---

## Story Detail

---

### Story 1 — MikroTik DHCP Reservations
**Status:** TODO
**Phase:** 1

**Goal:** Assign fixed IPs to all 3 RPis and Dell before any other configuration. Prevent IP shifts mid-setup.

**Tasks:**
- Obtain MAC addresses from all 3 RPis (`ip link show eth0`)
- Obtain MAC address from Dell (88.x NIC)
- Create static DHCP leases in MikroTik for all 4 devices
- Verify assigned IPs resolve correctly

**Acceptance criteria:** All 4 devices consistently receive their reserved IPs after reboot.

---

### Story 2 — RPi OS Baseline (All 3 Nodes)
**Status:** TODO
**Phase:** 1

**Goal:** Consistent, hardened Ubuntu 24.04 Server baseline on all 3 RPis before cluster work begins.

**Tasks:**
- Confirm Ubuntu 24.04 Server (64-bit, headless) on all 3 nodes
- Set hostnames: `nora-edge`, `nora-app1`, `nora-app2`
- SSH hardening: key auth only, password auth disabled, non-default port
- `ufw` firewall baseline
- System updates applied
- Wazuh agent installed and reporting to Dell (coordinate with Story 10)

**Acceptance criteria:** All 3 nodes reachable via SSH key only, hostnames resolving, ufw active, Wazuh agent connected.

---

### Story 3 — k3s Cluster Bootstrap
**Status:** TODO
**Phase:** 1

**Goal:** 3-node k3s cluster operational. Node 1 as control plane, Nodes 2/3 as workers.

**Tasks:**
- Install k3s on `nora-edge` (control plane)
- Join `nora-app1` and `nora-app2` as worker nodes
- Copy kubeconfig to dev machine (via Dell jumphost)
- Verify all nodes show Ready in `kubectl get nodes`

**Acceptance criteria:** `kubectl get nodes` shows 3 nodes Ready from dev machine.

---

### Story 4 — Cluster Tooling
**Status:** TODO
**Phase:** 1

**Goal:** ingress-nginx, cert-manager, and persistent volume config deployed and operational.

**Tasks:**
- Deploy ingress-nginx via Helm
- Deploy cert-manager via Helm
- Configure StorageClass for local-path persistent volumes
- Verify ingress controller pod running on `nora-edge`

**Acceptance criteria:** Ingress controller running, cert-manager running, PV provisioner available.

---

### Story 5 — cloudflared Tunnel + DNS
**Status:** TODO
**Phase:** 1

**Goal:** Nora domain resolves globally and routes through Cloudflare Tunnel to cluster ingress. No open inbound ports on home network.

**Tasks:**
- Install `cloudflared` on `nora-edge`
- Authenticate to Cloudflare account
- Create tunnel pointing to ingress-nginx service
- Configure DNS CNAME in Cloudflare zone
- Verify HTTPS end-to-end

**Acceptance criteria:** Domain resolves publicly, HTTPS works, home IP not exposed.

---

### Story 6 — openappsec WAF Deployment
**Status:** TODO
**Phase:** 1

**Goal:** openappsec deployed as ingress-nginx plugin, WAF rules active in front of all traffic.

**Tasks:**
- Deploy openappsec Helm chart
- Configure as ingress-nginx plugin
- Enable default OWASP ruleset
- Verify WAF intercepting test traffic

**Acceptance criteria:** openappsec pods running, test malicious request blocked at WAF layer.

---

### Story 7 — PostgreSQL Primary + Replica
**Status:** TODO
**Phase:** 1

**Goal:** PostgreSQL primary on `nora-app1`, streaming replica on `nora-app2`. Automated backup to Dell NFS.

**Tasks:**
- Deploy PostgreSQL primary on Node 2 (persistent volume)
- Deploy PostgreSQL replica on Node 3 with streaming replication
- Configure NFS backup job to Dell
- Verify replication lag and failover behaviour

**Acceptance criteria:** Replication healthy, backup job running, data survives Node 2 pod restart.

---

### Story 8 — RabbitMQ Deployment
**Status:** TODO
**Phase:** 1

**Goal:** RabbitMQ operational on `nora-app2` for async task queuing.

**Tasks:**
- Deploy RabbitMQ via Helm on Node 3
- Configure management UI
- Verify Django can connect and publish/consume

**Acceptance criteria:** RabbitMQ running, management UI accessible internally, Django connection verified.

---

### Story 9 — NFS Backup Mount
**Status:** TODO
**Phase:** 1

**Goal:** All RPi nodes can write backups to Dell NFS share. Automated retention policy in place.

**Tasks:**
- Enable NFS server role on Dell (or Samba if preferred)
- Mount NFS share on all 3 RPis
- Configure automated backup jobs: PostgreSQL dumps, k3s PV snapshots, ROS2 bags (Phase 2)
- Define retention policy

**Acceptance criteria:** Backup jobs running on schedule, files visible on Dell, retention enforced.

---

### Story 10 — Wazuh Agents on All RPis
**Status:** TODO
**Phase:** 1

**Goal:** All 3 RPis reporting logs and FIM alerts to Wazuh on Dell. OpenSearch dashboards operational.

**Tasks:**
- Install Wazuh agent on `nora-edge`, `nora-app1`, `nora-app2`
- Register each agent with Wazuh manager on Dell
- Verify logs flowing to OpenSearch
- Configure basic alerting rules (auth failures, file changes)

**Acceptance criteria:** All 3 agents active in Wazuh dashboard, logs visible in OpenSearch, test alert fires correctly.

---

### Story 11 — Django + Wagtail Deployment
**Status:** TODO
**Phase:** 1

**Goal:** Django + Wagtail CMS running in k3s, connected to PostgreSQL, accessible via ingress. Content manageable via Wagtail admin.

**Tasks (Claude Code):**
- Django project scaffold
- Wagtail CMS installed and configured
- Headless API enabled
- PostgreSQL connection configured
- Containerised (Docker image)
- Deployed to k3s as Deployment + Service
- Ingress rule configured
- Wagtail admin accessible at `/cms/`

**Acceptance criteria:** Wagtail admin login works, blog post creatable, headless API returns content as JSON.

---

### Story 12 — TypeScript Frontend (Headless Wagtail)
**Status:** TODO
**Phase:** 1

**Goal:** TypeScript/Node frontend consuming Wagtail headless API. Serves blog posts, design plans, media.

**Tasks (Claude Code):**
- Next.js or equivalent TypeScript frontend
- Wagtail API integration
- Blog post listing and detail pages
- Design plans section
- Video embed support (YouTube)
- Containerised and deployed to k3s
- Ingress rule configured

**Acceptance criteria:** Site renders content from Wagtail CMS, video embeds work, mobile-responsive.

---

### Story 13 — End-to-End Smoke Test
**Status:** TODO
**Phase:** 1

**Goal:** Full stack verified live on domain. Phase 1 complete.

**Tasks:**
- Create test blog post in Wagtail admin
- Verify it appears on public site via domain
- Verify HTTPS certificate valid
- Verify WAF blocking test payload
- Verify Wazuh logging the request
- Verify backup job has run successfully

**Acceptance criteria:** All verification steps pass. Site live. Phase 1 signed off.

---

### Story 14 — ROS2 Bridge Node
**Status:** CODE READY (on-cluster run pending)
**Phase:** 2
**Key files:** `bridge/` (nodes, container, compose, bag-sync + systemd, installer)

**Decision (2026-07-02):** standardised on **ROS 2 Humble** to match the robot (Jetson runs Humble). Original plan specified Jazzy — preserved in full under Retired Ideas. Rationale: same-distro across the DDS domain avoids message-definition drift and default-RMW mismatches, and de-risks Story 15 (Jetson↔Node 2 discovery). Humble is LTS (EOL May 2027); revisit at the next robot-side distro upgrade.

**Two design decisions taken during scaffolding (see Architecture Decisions #6/#7):**
- **Containerized Humble, not native.** Node 2 baseline is Ubuntu 24.04 (Noble); Humble's Tier-1 platform is Ubuntu 22.04 (Jammy) with no official Noble binaries. `ros:humble-ros-base` (Jammy userspace, arm64 confirmed) runs Humble correctly on the Noble host.
- **Docker Compose `network_mode: host`, not a k8s pod.** DDS discovers the Jetson over the LAN (multicast + RTPS); k3s CNI networking would block cross-host discovery. The bridge is the one Phase-2 component deliberately outside the cluster.

**Goal:** ROS2 Humble running on `nora-app1`, acting as bridge and state persistence layer for Nora.

**Tasks:**
- Install ROS2 Humble on Node 2 (match the Jetson/robot distro) — via container (`bridge/scripts/install-node2.sh`)
- Configure DDS to match Jetson setup (same RMW — default FastDDS — and `ROS_DOMAIN_ID`)
- Deploy mission state and logging nodes — `nora_mission_state` (persists to SQLite, republishes `/nora/mission_state`), `nora_event_logger` (JSON-lines for Wazuh)
- ROS2 bag sync to Dell NFS on schedule — `bag-recorder` service + `nora-bag-sync.timer` (15 min, 14-day retention)

**What was built vs plan:** mission-state persistence uses a local SQLite store, intentionally decoupled from the web PostgreSQL; bridging live state into PostgreSQL for the website is deferred to Story 16. Everything statically validated on the dev machine (nodes `py_compile`, scripts `bash -n`, `docker compose config` valid) plus a functional SQLite `StateStore` test (insert/latest/prune/persistence). Not yet run on Node 2 — needs the RPi + robot on the DDS domain.

**Acceptance criteria:** Node 2 ROS2 nodes visible in `ros2 node list` from Jetson network.

---

### Story 15 — Jetson ↔ Node 2 DDS Discovery
**Status:** TODO
**Phase:** 2

**Goal:** Jetson Orin Nano Super and `nora-app1` discover each other over the network via DDS.

**Tasks:**
- Configure DDS multicast/unicast settings on both sides
- Verify topic pub/sub across network boundary
- Tune QoS settings for reliability

**Acceptance criteria:** Jetson publishes topic visible on Node 2 and vice versa.

---

### Story 16 — Nora Telemetry Relay + Bag Backup
**Status:** TODO
**Phase:** 2

**Goal:** Nora telemetry flowing to RPi cluster for persistence and later analysis. Bags backed up to Dell.

**Tasks:**
- Telemetry relay node on Node 2
- ROS2 bag recording configured
- Automated bag sync to Dell NFS

**Acceptance criteria:** Bags accumulating on Dell, telemetry accessible from cluster.

---

### Story 17 — Security Lab Namespace
**Status:** TODO
**Phase:** 2

**Goal:** Isolated security research environment in k3s on Node 3. Network-isolated from all other namespaces.

**Tasks:**
- Create `security-lab` namespace in k3s
- Apply Kubernetes NetworkPolicy — no ingress/egress to other namespaces
- Verify isolation with test traffic

**Acceptance criteria:** Pods in `security-lab` cannot reach pods in other namespaces.

---

### Story 18 — Mock ROS2 Attack Surface (IEEE CPS-Sec Paper Artifact)
**Status:** TODO
**Phase:** 2

**Goal:** Full-stack attack demonstration environment on Node 3. Paper artifact for IEEE CPS-Sec submission.

**Tasks:**
- Mock ROS2 robot endpoints in security-lab namespace
- Rogue node injection scenario
- Man-in-the-middle on ROS2 topics
- Attack tooling and capture artefacts documented
- Wazuh logging attack traffic for detection demo

**Acceptance criteria:** Attack scenarios reproducible, captured, documented for paper.

---

## Current Issues

- **ACTION NEEDED — confirm actual reserved IPs and reconcile with the hardcoded scheme.** Static IPs are set on the MikroTik but not yet read. Deploy scripts and manifests assume `192.168.88.10/.11/.12` (RPis) and `192.168.88.20` (Dell). Once the real leases are known, either update the scripts or re-reserve to match. Affected: `deploy/scripts/01,02,10`, `deploy/k8s/backup-nfs.yaml`, `bridge/scripts/*`.
- **DECIDED (2026-07-02) — WAF = open-appsec, not ModSecurity.** ModSecurity/CRS is static-regex, high-FP, no ML; open-appsec's preventive ML engine is the intended tool. Constraint (verified via registry manifests): open-appsec ships current images for **amd64 only** — the sole arm64 build is `1.1.20-arm64-beta` (Dec 2024, ~18 months stale). So on the arm64 Pis, open-appsec = stale beta; on an x86 Xeon blade it is first-class. Plan is to run the WAF on the blade. `deploy/scripts/04-openappsec.sh modsecurity` remains only as an emergency fallback, not the design. See Architecture Decisions for the security-tier plan.
- **RESOLVED (2026-07-02) — frontend build verified.** Full stack brought up with `docker compose up --build`: all 5 services healthy, frontend compiled, and a blog post created in the CMS flowed backend → API → rendered frontend (listing, detail, homepage, YouTube embed). See Verification Log below.
- **LOW PRIORITY — Story 17 needs a policy-capable CNI.** k3s ships Flannel, which ignores NetworkPolicy, so the security-lab isolation manifests apply cleanly but don't actually enforce until Calico (or Cilium) is installed. `deploy/scripts/12-verify-security-lab.sh` detects this and fails loudly rather than giving false assurance.

---

## Open Questions

- **[RESOLVED 2026-07-02] ROS 2 distro mismatch: robot runs Humble, Story 14 planned Jazzy on Node 2.** Confirmed the Nora robot (Jetson) runs **ROS 2 Humble**. Decision: standardise Node 2 on **Humble** to match the robot — same-distro across the DDS domain avoids message-definition drift and default-RMW differences (de-risks Story 15). Story 14 detail updated; original Jazzy plan preserved under Retired Ideas. Story 18 lab already built on Humble.

---

## Verification Log

### 2026-07-02 — Local stack end-to-end (Stories 11, 12; Story 8 broker path)
Ran `docker compose up --build` on the dev machine (Docker Desktop). Results:
- All services up: db (healthy), rabbitmq, backend, worker, frontend.
- Backend: `/api/v2/pages/` 200 JSON, `/cms/login/` 200, migrations applied cleanly on PostgreSQL 16.
- Created BlogIndexPage + BlogPage "Hello Nora" via `manage.py shell`; API returned it with `body_html` expanded and the YouTube URL intact.
- Frontend: `/`, `/blog`, `/blog/hello-nora`, `/design-plans` all 200; detail page rendered the title, bold body HTML, and a `youtube-nocookie.com/embed/…` iframe.
- Celery→RabbitMQ: `cms.tasks.ping` dispatched; worker log shows `Connected to amqp`, task received and `succeeded … 'pong'`. (Confirms Story 8 broker wiring works locally.)

### 2026-07-02 — Story 18 scaffold authored + statically checked
- Base image `ros:humble-ros-base` confirmed multi-arch (amd64 + **arm64**) via registry manifest inspection; matches the robot's ROS 2 Humble.
- All 4 ROS 2 nodes (`robot`, `mission_control`, `rogue`, `mitm`) pass `py_compile`; 2 shell scripts + entrypoint pass `bash -n`; 3 scenario manifests parse as valid `Pod` YAML.
- NOT yet run on-cluster: needs the k3s cluster + Story 17 namespace (and a policy CNI for enforced isolation). DDS-in-k8s handled by co-locating scenario nodes in one pod with `ROS_LOCALHOST_ONLY=1` (loopback discovery); multi-pod discovery-server variant documented but not default.

### 2026-07-02 — Story 14 bridge scaffold authored + statically checked
- Reuses `ros:humble-ros-base` (arm64) to run Humble on the Noble host (see Architecture Decision #6).
- Nodes `nora_mission_state` + `nora_event_logger` pass `py_compile`; `bag-sync.sh`, `install-node2.sh`, entrypoint pass `bash -n`; `docker compose config` valid (3 services: mission-state, event-logger, bag-recorder).
- Functional test of the SQLite `StateStore` (pure Python, no ROS): insert → latest → prune → persistence-across-reopen all pass.
- NOT yet run on Node 2: needs the RPi + robot sharing the DDS domain. Acceptance is `ros2 node list` from the Jetson network showing both bridge nodes.

## Under Consideration — Xeon Blade + Security/Edge Tier (2026-07-02)

**Status: NOT YET DECIDED — hardware not confirmed.** User may acquire a datacenter server (Intel Xeon, ~192GB RAM, x86_64). Emerging direction:

- **Hybrid, not replacement.** Xeon as workhorse (heavy/stateful workloads); keep the 3 Pis for a real multi-node cluster and, notably, a *physically separate* security-lab node (stronger isolation for Stories 17/18 than a NetworkPolicy on shared hardware). Trade-off: a single Xeon loses hardware HA (PostgreSQL replica + pod anti-affinity become theater on one box) and stops being a distributed cluster. Mixed arm64+amd64 k3s works but every image then needs both arches or per-node scheduling.
- **Security/edge tier on the blade.** open-appsec WAF (runs first-class on amd64, unlike the stale arm64 beta) + honeypots (e.g. T-Pot — x86, 16GB+, unsuited to a Pi) + optionally the ROS2 security lab, all feeding the existing Wazuh SIEM on the Dell. Coherent design and strong CPS-Sec paper material (real honeypot attacker telemetry alongside the ROS2 attack lab).
- **Hard requirement if honeypots go on:** isolate them on a dedicated VLAN, firewalled from the production cluster and the Wazuh manager (log egress only). MikroTik supports this; "future VLAN segmentation" already noted in the inventory. Never put a honeypot on the flat production L2.
- **Open sequencing question:** if the Xeon arrives soon, stand open-appsec up fresh on it and skip the arm64 beta entirely; if not, the arm64 beta is a known-stale interim.
- **Impact on existing work is small:** backend/frontend/bridge/security-lab are arch-agnostic source (rebuild for amd64 — easier, no cross-compile); Jetson DDS discovery (Stories 14–16) unaffected. Main changes would be the DB-HA design and node-pinning in manifests.

---

## Architecture Decisions (2026-07-01, scaffolding session)

1. **CloudNativePG operator for Story 7** instead of hand-rolled primary/replica StatefulSets. The operator manages streaming replication, failover, and promotion automatically; official images are multi-arch (arm64 OK). Services: `nora-db-rw` (primary) / `nora-db-ro` (replicas); app credentials auto-generated in secret `nora-db-app`.
2. **Plain manifests with the official `rabbitmq:3.13-management` image for Story 8** rather than the Bitnami Helm chart — avoids Bitnami's uncertain arm64/catalog situation; single node pinned to `nora-app2`.
3. **Registry-less image distribution.** No container registry is deployed: `10-deploy-app.sh` builds linux/arm64 images with buildx and streams them into k3s containerd on each node over ssh (`k3s ctr images import`). Revisit if image churn gets annoying (a in-cluster registry or ttl.sh would be the upgrade path).
4. **Traefik disabled in k3s** (`--disable traefik`) since the locked stack uses ingress-nginx.
5. **Headless-first Wagtail.** Content is served to the Next.js frontend via `/api/v2/` with a `body_html` API field (rich text pre-expanded server-side with `expand_db_html`). Minimal Django templates exist only so admin previews don't 500.
6. **(2026-07-02, Story 14) ROS 2 Humble runs in a container on Node 2, not natively.** Node 2 is Ubuntu 24.04 (Noble); Humble's Tier-1 platform is Ubuntu 22.04 (Jammy) and there are no official Humble binaries for Noble. `ros:humble-ros-base` supplies a Jammy userspace, so Humble runs correctly on the Noble host without a source build or an OS downgrade. Same pattern used by the Story 18 lab.
7. **(2026-07-02, Story 14) The bridge uses Docker `network_mode: host`, deliberately outside k3s.** Cross-host DDS discovery with the Jetson relies on LAN multicast + RTPS, which k3s CNI pod networking blocks. Host networking places the bridge directly on Node 2's LAN in the robot's `ROS_DOMAIN_ID`. This is the one Phase-2 workload intentionally not orchestrated by Kubernetes.

---

## Critical Learnings & Workarounds

1. **Wagtail homepage data migrations must set `locale`.** Problem: `cms/migrations/0002_create_homepage` failed with `NOT NULL constraint failed: wagtailcore_page.locale_id`, masked by SQLite's atomic-block handling as a `TransactionManagementError`. Root cause: since Wagtail 2.11 (`wagtailcore.0054+`), `Page.locale` is a non-null FK, and historical models in data migrations don't run Wagtail's save logic that would populate it. Fix: fetch-or-create the default `Locale` in the migration and pass it to `HomePage.objects.create()`. Lesson: when hand-writing Wagtail page data migrations, always set `locale` explicitly; to find the real error behind a `TransactionManagementError`, walk `__cause__`/`__context__` to the root exception.
2. **Newly published posts 404 on the frontend for up to ~60s (ISR + stale-while-revalidate).** Problem: after publishing "Hello Nora", the `/blog/hello-nora` detail page kept returning 404 well after the API served the post, while the listing/homepage picked it up. Root cause: `lib/wagtail.ts` fetches with `next: { revalidate: 60 }`; the detail route was first requested *before* the post existed, so Next cached a `notFound()` result. On expiry Next serves the STALE 404 on the first request and regenerates in the background — so it takes a revalidation window *plus* a throwaway request before the page turns 200. Not a bug (expected App Router behaviour), but a publishing-UX wrinkle. Lesson: for a headless CMS the clean fix is on-demand revalidation — add a Wagtail `page_published` signal that calls a Next revalidate webhook (`revalidatePath`/`revalidateTag`) — deferred as a Phase 1 polish item. Lowering `revalidate` only shortens, doesn't remove, the window.
3. **Celery has no result backend by design; use `.delay()`, not `.delay().get()`.** Problem: `ping.delay().get()` raised `NotImplementedError: No result backend is configured` even though the task ran fine. Root cause: only `CELERY_BROKER_URL` (RabbitMQ) is set — RabbitMQ is a fire-and-forget broker here, with no result store (Redis/db). The task executed and succeeded on the worker; only result retrieval is unavailable. Lesson: this is intentional for async side-effect tasks; verify success via worker logs, not `.get()`. If a future task genuinely needs return values, add a result backend (Redis) rather than abusing RabbitMQ for it.

---

## Retired Ideas

### [RETIRED 2026-07-02] Story 14 — ROS2 Bridge Node on ROS 2 Jazzy
Superseded by the decision to standardise Node 2 on ROS 2 Humble to match the robot (Jetson runs Humble). Original plan preserved in full:

> **Story 14 — ROS2 Bridge Node**
> **Status:** TODO
> **Phase:** 2
>
> **Goal:** ROS2 Jazzy running on `nora-app1`, acting as bridge and state persistence layer for Nora.
>
> **Tasks:**
> - Install ROS2 Jazzy on Node 2
> - Configure DDS to match Jetson setup
> - Deploy mission state and logging nodes
> - ROS2 bag sync to Dell NFS on schedule
>
> **Acceptance criteria:** Node 2 ROS2 nodes visible in `ros2 node list` from Jetson network.
