# VPCs and networks

Networking is Multus-based: each tenant gets a **default VPC**, optional extra VPCs, and **private networks** (NADs) plus an optional **public network** profile from Helm.

## Default VPC

On tenant create, VirtFoundry bootstraps a default VPC (typically `10.0.0.0/16`) with its own Kubernetes namespace for Multus resources.

**UI:** Network → **VPCs** (`/vpcs`)

| Action | API |
|--------|-----|
| List / create | `GET`/`POST /api/v1/vpcs` |
| Update / delete | `PATCH`/`DELETE /api/v1/vpcs/{id}` |
| Suggest CIDR | `GET /api/v1/vpcs/cidr-plan` |

The CIDR planner helps pick a non-overlapping VPC CIDR.

## Private networks

Isolated L2 networks attached to a VPC; VMs join via Multus NICs.

**UI:** Network → **Networks** (`/networks`)

| Action | API |
|--------|-----|
| List / create | `GET`/`POST /api/v1/networks` |
| Update / delete | `PATCH`/`DELETE /api/v1/networks/{id}` |
| Subnet CIDR plan | `GET /api/v1/networks/cidr-plan?vpc_id=…&prefix=24` |

## Public network profile

When Helm enables `platform.networking.public`, the cluster exposes a shared public pool (bridge, IP range, DNS). The UI **Public** page (`/networks/public`) is largely **read-only** — operators configure the pool in values.

See [Configuration](../configuration.md) and [Topologies](../topologies.md) for bridge/uplink and MetalLB reserved ranges.

!!! note "Lab without Multus bridges"
    You can still deploy container-disk VMs on the pod network to validate the control plane. Full L2 demos need host bridges as described in topologies.

## Related

- [Security groups](security-groups.md)
- [Virtual machines](vms.md) — attach `network_ids` at deploy
- [Concepts](concepts.md) — tenant namespaces
