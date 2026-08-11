# Features overview

What you can do in VirtFoundry after [install](../installation.md) and [first login](../quickstart.md).

VirtFoundry is a **multi-tenant IaaS control plane** on Kubernetes: tenants get isolated namespaces, VMs (KubeVirt), disks, VPCs/networks (Multus), security groups, IAM, and a CloudStack-like UI/API.

## Capability map

| Area | What you get | Guide |
|------|----------------|-------|
| Tenancy | Isolated tenants, root impersonation, delete (non-default) | [Concepts](concepts.md) |
| IAM | Users, roles, permissions, API keys (`vfd_live_...`) | [Auth & IAM](iam.md) |
| Offerings | CPU/memory catalog; shared vs dedicated CPU | [Service offerings](offerings.md) |
| Templates | Container disks + ISO (CDI) images | [Images & templates](templates.md) |
| Compute | Deploy, start/stop, attach volumes, logs, snapshots | [Virtual machines](vms.md) |
| Access | noVNC console, SSH keys, expose SSH | [Console & SSH](access.md) |
| Storage | Volumes; VM snapshots vs CSI volume snapshots | [Volumes & snapshots](storage.md) |
| Network | VPCs, private nets, CIDR planners, public profile | [VPCs & networks](networking.md) |
| Security | Security groups → NetworkPolicy | [Security groups](security-groups.md) |
| API | JWT / API keys, `X-Tenant-ID`, route map | [API quick reference](api.md) |

## Domain model

```text
Tenant
  ├── VPC ── Network (Multus NAD)
  │         └── Security group (NetworkPolicy)
  ├── Volume ── Volume snapshot (CSI)
  └── VM ── NICs ── Network
       ├── Service offering (CPU/mem)
       ├── VM template (image)
       └── VM snapshot (KubeVirt)
```

**Rule:** the tenant is the isolation unit. VMs and volumes live in the tenant namespace; each VPC has its own namespace; NICs attach via Multus.

## UI map

| Sidebar | Paths |
|---------|-------|
| Dashboard | `/dashboard` |
| Compute | `/vms`, `/templates`, `/ssh-keys`, `/vm-snapshots`, `/console` |
| Storage | `/volumes`, `/snapshots` |
| Network | `/vpcs`, `/networks`, `/networks/public`, `/security-groups` |
| Platform | `/iam`, `/offerings` (root), `/tenants` (root) |

## Next

- Day-2 ops values: [Configuration](../configuration.md)
- Cluster layouts: [Topologies](../topologies.md)
- Positioning: [Why VirtFoundry](../why.md)
