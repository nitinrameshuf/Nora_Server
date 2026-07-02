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

**Last Updated:** 2026-06-05
**Project Status:** Architecture decided, Story 1 Next (MikroTik DHCP reservations)

---

## Project: Nora Infrastructure

### Hardware Inventory

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

## Story Roadmap

| Story | Title | Phase | Status |
|---|---|---|---|
| 1 | MikroTik DHCP reservations | Phase 1 | TODO |
| 2 | RPi OS baseline — all 3 nodes | Phase 1 | TODO |
| 3 | k3s cluster bootstrap | Phase 1 | TODO |
| 4 | Cluster tooling — ingress-nginx, cert-manager, PVs | Phase 1 | TODO |
| 5 | cloudflared tunnel + DNS | Phase 1 | TODO |
| 6 | openappsec WAF deployment | Phase 1 | TODO |
| 7 | PostgreSQL primary + replica | Phase 1 | TODO |
| 8 | RabbitMQ deployment | Phase 1 | TODO |
| 9 | NFS backup mount — RPis to Dell | Phase 1 | TODO |
| 10 | Wazuh agents on all RPis | Phase 1 | TODO |
| 11 | Django + Wagtail deployment | Phase 1 | TODO |
| 12 | TypeScript frontend — headless Wagtail | Phase 1 | TODO |
| 13 | End-to-end smoke test — site live on domain | Phase 1 | TODO |
| 14 | ROS2 bridge node — Node 2 | Phase 2 | TODO |
| 15 | Jetson ↔ Node 2 DDS discovery | Phase 2 | TODO |
| 16 | Nora telemetry relay + ROS2 bag backup to Dell | Phase 2 | TODO |
| 17 | Security lab namespace — Node 3 | Phase 2 | TODO |
| 18 | Mock ROS2 attack surface — IEEE CPS-Sec paper artifact | Phase 2 | TODO |

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
**Status:** TODO
**Phase:** 2

**Goal:** ROS2 Jazzy running on `nora-app1`, acting as bridge and state persistence layer for Nora.

**Tasks:**
- Install ROS2 Jazzy on Node 2
- Configure DDS to match Jetson setup
- Deploy mission state and logging nodes
- ROS2 bag sync to Dell NFS on schedule

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

None active.

---

## Critical Learnings & Workarounds

None yet.

---

## Retired Ideas

None yet.
