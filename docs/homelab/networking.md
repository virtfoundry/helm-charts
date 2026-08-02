# Homelab public networking

VirtForge homelab uses **VLAN 50** (`10.0.50.0/24`) for MetalLB, the platform gateway, and VM public IPs. This page documents infrastructure requirements — not application bugs.

## Address plan (homelab)

| Range | Purpose |
|-------|---------|
| `10.0.50.1` | MikroTik gateway on VLAN50 |
| `10.0.50.2` | `virtforge-pub0` bridge IP (dnsmasq) |
| `10.0.50.10–99` | VM public IP pool (VirtForge allocation) |
| `10.0.50.100–150` | MetalLB LoadBalancer (Traefik `10.0.50.102`) |
| `10.0.50.251` | Worker `enp3s0.50` (optional host address) |

## How VM networking works (v0.2.0+)

1. Helm creates host bridge `virtforge-pub0` + VLAN uplink
2. Multus NAD uses **bridge CNI** without pod IPAM — guest gets L2 on the bridge
3. VirtForge allocates a static IP from the pool and injects **cloud-init** (MAC match)
4. Pod network (Calico) remains for the virt-launcher sandbox (`allowPodNetwork: true`)

## Common misconfiguration: missing gateway

If `public.gateway` points to **`10.0.50.254`** but only **`10.0.50.1`** exists on the router:

- Worker ↔ VM (same L2) may work
- **WiFi / other VLANs fail** — VM cannot route replies back

**Fix (homelab):** set `platform.networking.public.gateway: 10.0.50.1` in `values-homelab.yaml`, or add on MikroTik:

```routeros
/ip address add address=10.0.50.254/32 interface=VLAN50-PUBLIC comment="virtforge VM gw alias"
```

## CloudStack `cloudbr0` on workers

Hypervisors with CloudStack often have **`10.0.50.1/24` on `cloudbr0`**, causing the kernel to prefer `cloudbr0` for all `10.0.50.0/24` traffic. VM veths attach to **`virtforge-pub0`**, not `cloudbr0`.

The homelab chart sets **`routePoolViaBridge`** — more-specific routes for the VM pool via `virtforge-pub0` (metric 50). Do not remove `cloudbr0`.

## MikroTik checklist

| Item | Status |
|------|--------|
| Forward: WIFI → PUBLIC | Required |
| Forward: PUBLIC → WIFI | Required (return traffic) |
| DNS `virtforge-cloud.homelab` → `10.0.50.102` | Gateway VIP, not worker `10.0.30.x` |
| Gateway alias `10.0.50.254/32` | If legacy VMs use .254 |

Automated script (kubespray repo):

```bash
MIKROTIK_PASSWORD='***' GATEWAY_IP=10.0.50.102 \
  ./scripts/mikrotik-vlan50-access.sh
```

## Validation matrix

| From | Test | Expected |
|------|------|----------|
| MikroTik | `/ping 10.0.50.14` | OK |
| Worker (hostNetwork) | `ping 10.0.50.14` | OK |
| WiFi client (`10.0.20.x`) | `ping 10.0.50.14` | OK after router fix |
| WiFi client | `ssh ubuntu@10.0.50.14` | OK with registered key |

If only the worker succeeds, inspect **gateway and inter-VLAN routing** before KubeVirt or cloud-init.

## Do not

- Remove VLAN 50 or `virtforge-pub0` to “fix” SSH
- Point homelab DNS at a worker Node IP on VLAN 30 for the gateway hostname
- Use NodePort for SSH when public IP + SG is configured (legacy workaround)
