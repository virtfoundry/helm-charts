# Features overview

What you can do in VirtFoundry after [install](../installation.md) and [first login](../quickstart.md).

VirtFoundry is a **multi-tenant IaaS control plane** on Kubernetes: tenants get isolated namespaces, VMs (KubeVirt), disks, VPCs/networks (Multus), security groups, IAM, and a CloudStack-like UI/API.

## Capability map

<div class="grid cards" markdown>

-   :material-domain:{ .lg .middle } **Tenancy**

    ---

    Isolated tenants, root impersonation, delete (non-default).

    [:octicons-arrow-right-24: Read](concepts.md)

-   :material-shield-account:{ .lg .middle } **Auth & IAM**

    ---

    Users, roles, permissions, API keys (`vfd_live_...`).

    [:octicons-arrow-right-24: Read](iam.md)

-   :material-tag-multiple:{ .lg .middle } **Service offerings**

    ---

    CPU/memory catalog; shared vs dedicated CPU.

    [:octicons-arrow-right-24: Read](offerings.md)

-   :material-disc:{ .lg .middle } **Images & templates**

    ---

    Container disks and ISO (CDI) images.

    [:octicons-arrow-right-24: Read](templates.md)

-   :material-server:{ .lg .middle } **Virtual machines**

    ---

    Deploy, start/stop, attach volumes, logs, snapshots.

    [:octicons-arrow-right-24: Read](vms.md)

-   :material-console:{ .lg .middle } **Console & SSH**

    ---

    noVNC console, SSH keys, expose SSH.

    [:octicons-arrow-right-24: Read](access.md)

-   :material-harddisk:{ .lg .middle } **Volumes & snapshots**

    ---

    Volumes; VM snapshots vs CSI volume snapshots.

    [:octicons-arrow-right-24: Read](storage.md)

-   :material-lan:{ .lg .middle } **VPCs & networks**

    ---

    VPCs, private nets, CIDR planners, public profile.

    [:octicons-arrow-right-24: Read](networking.md)

-   :material-shield-lock:{ .lg .middle } **Security groups**

    ---

    Security groups become NetworkPolicy.

    [:octicons-arrow-right-24: Read](security-groups.md)

-   :material-kubernetes:{ .lg .middle } **Kubernetes clusters (VKS)**

    ---

    Managed Kubernetes: Kamaji control plane, VM workers.

    [:octicons-arrow-right-24: Read](vks.md)

-   :material-api:{ .lg .middle } **API quick reference**

    ---

    JWT / API keys, `X-Tenant-ID`, route map.

    [:octicons-arrow-right-24: Read](api.md)

</div>

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
- Laptop lab: [Kind](../kind.md)
- Cluster layouts: [Topologies](../topologies.md)
- Positioning: [Why VirtFoundry](../why.md)
