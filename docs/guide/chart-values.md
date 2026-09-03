# Chart values (defaults)

This page is the **written default** for the Helm charts. Helm only applies values **at install or upgrade**. Flags like `--set` must sit on **the same** `helm install` / `helm upgrade` command as the chart — they are not kubectl args and they are not remembered unless you pass `--reuse-values` on the next upgrade.

Full source in git (always in sync with the chart):

- [`charts/virtfoundry/values.yaml`](https://github.com/virtfoundry/helm-charts/blob/main/charts/virtfoundry/values.yaml) — API + UI
- [`charts/virtfoundry-operator/values.yaml`](https://github.com/virtfoundry/helm-charts/blob/main/charts/virtfoundry-operator/values.yaml) — CRDs + operator

## Why `--set` goes on the Helm command

| Mechanism | When it applies | Use for |
|-----------|-----------------|--------|
| Chart `values.yaml` (below) | Every install unless overridden | Safe defaults |
| `-f my-values.yaml` | Same Helm command | Homelab / GitOps overlays |
| `--set key=value` | Same Helm command | Secrets and one-off overrides |
| `kubectl edit` / env on a pod | After install, until the next Helm sync | Emergency only — Helm will overwrite |

`--set secrets.rootPassword=…` and `--set secrets.jwtSecret=…` belong next to `helm install virtfoundry …` because those keys live in the **chart**. A later `kubectl set env` is not the source of truth.

Prefer a file for anything larger than two secrets:

```bash
helm install virtfoundry virtfoundry/virtfoundry \
  --version 0.7.0 \
  --namespace virtfoundry-system \
  -f my-values.yaml \
  --set secrets.rootPassword='change-me' \
  --set secrets.jwtSecret='change-me-long-random'
```

`helm upgrade … --reuse-values` keeps previous `--set` / `-f` unless you override them.

## Longhorn (storage)

VirtFoundry does **not** install a disk backend. VM disks are Kubernetes PVCs on whatever **StorageClass** you point at.

- Chart key `platform.storage.defaultClass: auto` (default): at **install time** Helm looks at the cluster. If a StorageClass named `longhorn` exists, it is used. Else the StorageClass marked default. Else `local-path`.
- **[Longhorn](https://longhorn.io/)** is what we recommend on a real homelab: replicated block, CSI **volume** snapshots, disks that survive losing a worker. `local-path` is a demo class — volume snapshots will fail.
- You still install Longhorn **before** VirtFoundry ([prerequisites](prerequisites.md)). The chart only *selects* the class; it does not deploy Longhorn.
- Force a class: `--set platform.storage.defaultClass=longhorn` (and usually `--set platform.storage.snapshotClass=longhorn`).

## Public IP (optional LAN / VLAN)

`platform.networking.public.enabled` defaults to **`false`**. Then VMs use the **pod** network. You do **not** need `--set` for public IPs to install the control plane.

When public is on, each VM can get a **second NIC** on a Linux bridge (`vf-pub0` by default) and a static address from `ipPool` (cloud-init). That CIDR must be **your** LAN or VLAN — not a number we invented.

**Homelab, you did not pass CIDR/gateway:**

- `autoFromCluster: true` (chart default) fills `cidr` / `gateway` / `ipPool` / `dns` from the first Kubernetes **Node InternalIP** (`/24`, gateway `.1`, pool `.20–.80`).
- That InternalIP is the **kubelet** address. If Kubernetes lives on `10.0.30.0/24` and VMs should sit on VLAN `10.0.50.0/24`, auto is **wrong** — set the VLAN explicitly and `autoFromCluster: false` (see `values-homelab.yaml`).
- Auto **never** sets `bridge.uplink`. Enslaving the Kubernetes NIC drops SSH. Public still needs a second NIC, a VLAN iface, or an existing `br0` before you flip `enabled: true`.

Generate a values snippet from this host or `kubectl`:

```bash
./scripts/detect-host-public-net.sh > public-from-host.yaml
# edit gateway / pool, then:
helm upgrade --install virtfoundry virtfoundry/virtfoundry -n virtfoundry-system \
  -f public-from-host.yaml \
  --set secrets.rootPassword='…' \
  --set secrets.jwtSecret='…'
```

Details: [Configuration — public networking](configuration.md#public-networking), [Topologies](topologies.md#public-network-underlay).

## Default values — `virtfoundry` (API + UI)

```yaml
--8<-- "charts/virtfoundry/values.yaml"
```

## Default values — `virtfoundry-operator`

```yaml
--8<-- "charts/virtfoundry-operator/values.yaml"
```
