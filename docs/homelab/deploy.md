# Homelab deploy

Bare-metal Kubernetes with Gateway API (Traefik), MetalLB on VLAN 50, and optional image sideload when GHCR push is unavailable.

## Prerequisites

- Kubeconfig with admin access
- Sibling clone: `virtforge` next to `virtforge-chart` (or set `APP_ROOT`)
- Worker node name for sideload (e.g. `homelab-worker-01`)
- KubeVirt + Multus installed (`make setup-kubevirt setup-multus`)

## One-command deploy

```bash
export KUBECONFIG=/path/to/admin.conf
export IMPORT_NODE=homelab-worker-01

cd virtforge-chart
make deploy-homelab
```

Environment variables:

| Variable | Default | Description |
|----------|---------|-------------|
| `PUSH_IMAGES` | `true` | Push to GHCR; `false` for sideload only |
| `USE_SIDELOAD` | `false` | Import images into worker containerd |
| `IMPORT_NODE` | required for sideload | Target node name |
| `DNS_HOST` | `virtforge-cloud.homelab` | HTTPRoute hostname |

## What gets installed

- API, worker, UI, MySQL (`virtforge-system`)
- HTTPRoute → `homelab-gateway` (Traefik)
- Platform bridge DaemonSet (`virtforge-pub0`, dnsmasq optional)
- Multus NAD `virtforge-public` (bridge CNI, L2 to host bridge)

## After deploy

1. Register DNS → MetalLB gateway IP (not worker Node IP):

   ```bash
   MIKROTIK_PASSWORD='***' ./scripts/register-dns.sh virtforge-cloud.homelab 10.0.50.102
   ```

2. Apply MikroTik VLAN50 access (gateway alias + WiFi routing) — see [Public networking](networking.md)

3. Open `http://virtforge-cloud.homelab/` — login `root` / chart `secrets.rootPassword`

## Deploy a test VM

In the UI or API:

- **Public IP:** enabled
- **Security group:** allow TCP 22
- **SSH key:** registered key

SSH from a client on a routed VLAN (e.g. WiFi `10.0.20.x`):

```bash
ssh -i ~/.ssh/id_ed25519 ubuntu@10.0.50.x
```

## Related

- [Public networking](networking.md)
- [Configuration](../guide/configuration.md)
