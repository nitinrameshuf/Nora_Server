# Nora Server

Self-hosted platform for the Nora project: a headless Django + Wagtail CMS with a
TypeScript (Next.js) frontend, deployed to a 3-node Raspberry Pi k3s cluster.
Full architecture, hardware inventory, and story roadmap live in [progress.md](progress.md).

## Layout

```
backend/          Django + Wagtail (headless CMS, API at /api/v2/, admin at /cms/)
frontend/         Next.js frontend consuming the Wagtail API
deploy/k8s/       Kubernetes manifests (namespace, db, rabbitmq, apps, backups)
deploy/scripts/   Numbered setup scripts, in execution order
docker-compose.yml  Local development environment
```

## Local development (no hardware needed)

```sh
docker compose up --build
```

- Site: http://localhost:3000
- Wagtail admin: http://localhost:8000/cms/ (admin / admin)
- API: http://localhost:8000/api/v2/pages/
- RabbitMQ UI: http://localhost:15672 (guest / guest)

Create content in the admin under Home → add a **Blog Index Page** (slug `blog`),
then Blog Pages beneath it; same pattern for **Design Plan Index Page**. Posts
appear on the frontend within ~60s (ISR revalidation).

## Cluster deployment

Prereqs done by hand first: Story 1 (MikroTik DHCP reservations) and Story 2
(RPi OS baseline). Then, in order:

| Script | Story | Run on |
|---|---|---|
| `01-k3s-server.sh` | 3 | nora-edge |
| `02-k3s-agent.sh <ip> <token>` | 3 | nora-app1, nora-app2 |
| `03-cluster-tooling.sh` | 4 | dev machine |
| `04-openappsec.sh` | 6 | dev machine |
| `05-postgres.sh` | 7 | dev machine |
| *apply secrets* (see below) | — | dev machine |
| `06-rabbitmq.sh` | 8 | dev machine |
| `07-nfs-dell-server.sh` | 9 | Dell (nora-siem) |
| `08-backups.sh` | 9 | dev machine |
| `09-wazuh-agent.sh <manager-ip>` | 10 | each RPi |
| `10-deploy-app.sh` | 11+12 | dev machine |
| `11-smoke-test.sh` | 13 | dev machine |

Secrets:

```sh
cp deploy/k8s/secrets.example.yaml deploy/k8s/secrets.yaml
# edit secrets.yaml with real values (it is gitignored)
kubectl apply -f deploy/k8s/namespace.yaml -f deploy/k8s/secrets.yaml
```

Story 5 (cloudflared + DNS) is deliberately manual — until then the site is
reachable inside the LAN at `http://nora.local` (point it at 192.168.88.10 in
`/etc/hosts` or MikroTik DNS).

## Notes

- No image registry: `10-deploy-app.sh` builds arm64 images with buildx and
  imports them into k3s containerd over ssh.
- PostgreSQL primary/replica is managed by CloudNativePG (`nora-db-rw` /
  `nora-db-ro` services); app credentials auto-generated in secret `nora-db-app`.
- open-appsec arm64 support is unverified — `04-openappsec.sh modsecurity`
  enables the ModSecurity + OWASP CRS fallback built into ingress-nginx.
