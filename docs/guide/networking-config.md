# Networking configuration

Helm values for public networking and host bridges. Overview of every other value: [Configuration](configuration.md).

## Public networking

Enable routable VM IPs on a host bridge + Multus NAD. VLAN tagging is optional — laptop walkthrough: [Kind](kind.md); real nodes: [Topologies — public underlay](topologies.md#public-network-underlay). Written chart defaults: [Chart values](chart-values.md).

If you **do not** `--set` public CIDR/gateway, `autoFromCluster: true` copies a `/24` from the first Node **InternalIP** (kubelet address), gateway `.1`, pool `.20–.80`. Public stays **disabled** until you set `public.enabled: true`. Auto never sets `uplink`.

Same LAN as Kubernetes (typical small homelab): enable public only after a second NIC or existing `br0`. **Different VLAN than Node InternalIP** (example: nodes `10.0.30.0/24`, VMs `10.0.50.0/24`): set `autoFromCluster: false` and write the VLAN CIDR (`values-homelab.yaml`).

```bash
./scripts/detect-host-public-net.sh   # values snippet from kubectl/host
```

| Key | Default | Description |
|-----|---------|-------------|
| `public.enabled` | `false` | Shared public network (schedules host bridge DaemonSet when true) |
| `public.autoFromCluster` | `true` | Fill empty/default CIDR, gateway, pool, DNS from Node InternalIP |
| `public.cidr` | `10.0.50.0/24` | Fallback when auto cannot see the API; L3 CIDR — VLAN **or** house LAN |
| `public.gateway` | `10.0.50.254` | VM default gateway in cloud-init — **must match a reachable router IP on that CIDR** |
| `public.ipPool.start/end` | `.10`–`.99` | Allocatable guest addresses; exclude DHCP, nodes, MetalLB |
| `public.reservedRanges` | MetalLB example | IPs the VM pool must not use |
| `public.bridge.name` | `vf-pub0` | Linux bridge (≤15 chars / IFNAMSIZ), or an existing host `br0` |
| `public.bridge.uplink` | `""` | VLAN iface or **second** NIC enslaved into the bridge. Same name on every node. |
| `public.bridge.address` | `""` | Optional host CIDR on the public L2 (outside VM/LB pools). The last octet is **replaced per node** (2–9) so two nodes never share the IP — required for MetalLB ARP. |
| `public.nad.name` | `virtfoundry-public` | Multus NAD (always CNI `bridge`) |
| `vm.allowPodNetwork` | `true` | Pod masquerade + public secondary NIC |

!!! warning "Gateway must be reachable"
    `public.gateway` must be an IP that exists on your L3 router for the configured CIDR. VMs receive this address via cloud-init when using the static IP pool.

!!! danger "Do not enslave the Kubernetes NIC"
    `uplink` must not be the interface that holds the node IP (SSH/kubelet). Bridge-keeper runs `ip link set <uplink> master <bridge>`. Use a VLAN subinterface, a second NIC, or point `bridge.name` at an existing mgmt bridge with `uplink` empty.

## Host bridges (isolated / public)

Default chart install is **API + UI only**: both `platform.networking.isolated.enabled` and `platform.networking.public.enabled` are **`false`**, so no hostNetwork DaemonSet is rendered ([#40](https://github.com/virtfoundry/helm-charts/issues/40)).

Opting into either flag deploys `*-bridge-setup` in `platform.networking.bridge.namespace` (default `kube-system`). That DaemonSet uses **`hostNetwork`** so it can create Linux bridges on the node. It does **not** use `hostPID` or `privileged: true`.

| Capability | Containers | Why |
|------------|------------|-----|
| `NET_ADMIN` | init, bridge-keeper, dhcp | Create/enslave bridges, addresses, routes |
| `NET_RAW` | dhcp only | dnsmasq DHCP / raw sockets |

Identity: dedicated ServiceAccount with `automountServiceAccountToken: false` (no API access). Image defaults to alpine **pinned by digest** (`platform.networking.bridge.image`).

| Key | Default | Description |
|-----|---------|-------------|
| `isolated.enabled` | `false` | Tenant VPC L2 on an internal bridge (`virtfoundry-br0`) |
| `isolated.bridge.name` | `virtfoundry-br0` | Linux bridge name (≤15 chars) |
| `isolated.bridge.address` | `""` | Optional host IPv4/CIDR on the isolated bridge (e.g. `10.0.0.1/24` when Multus IPAM uses `.1` as gateway) |
| `bridge.namespace` | `kube-system` | Namespace for the DaemonSet + scripts ConfigMap |
| `bridge.image` | alpine@sha256:… | Pin / override (prefer a prebuilt image with dnsmasq) |
| `bridge.nodeSelector` | `{}` | Optional node selection |
| `bridge.tolerations` | `[]` | Empty respects control-plane `NoSchedule`; set `operator: Exists` for kind / single-node homelabs |

!!! warning "Host privileges are intentional"
    Enabling isolated or public networking is an **operator opt-in** to host networking on every selected node. Do not enable it for a control-plane-only install unless you need Multus host bridges.

!!! note "DHCP still runs `apk add dnsmasq`"
    Until a prebuilt bridge/DHCP image ships, the public `dhcp` container installs dnsmasq at start. Override `bridge.image` with an image that already includes dnsmasq to remove that step.
