# Configuration

VirtFoundry runtime configuration is YAML rendered by Helm into a ConfigMap. **Helm values are the source of truth in Kubernetes.**

## Values → ConfigMap

| Helm value | Config field | Notes |
|------------|--------------|-------|
| `store.driver` | `database.driver` | Default `kubernetes` (`virtfoundry.io` CRDs) |
| `config.logLevel` | `logger.level` | |
| `config.jwtExpire` | `security.jwt_expire` | |
| `config.kubevirtEnabled` | `kubevirt.enabled` | |
| `platform.networking.public.*` | `networking.public.*` | Shared VM network |
| `platform.networking.isolated.bridge.name` | `networking.isolated.bridge_name` | Tenant VPC bridge |
| `platform.networking.vm.*` | `networking.vm.*` | Default VM networking |
| `platform.storage.*` | `storage.*` | Default StorageClass for CDI/ISO disks |
| `secrets.jwtSecret` | — | Env `JWT_SECRET` on API (not in ConfigMap) — see [Secrets](#secrets) |
| `secrets.rootPassword` | — | Env `ROOT_PASSWORD` on API — see [Secrets](#secrets) |

## Secrets

The chart ships **no** credential defaults. A root password or HMAC key published in a
public repository is a cluster-compromise path, so the chart refuses to render instead
of installing one. `helm install` / `helm template` with plain defaults fails with an
explicit error, and the sentinels `virtfoundry` and `change-me-in-production` are
rejected even if you pass them by hand.

| Key | Default | Description |
|-----|---------|-------------|
| `secrets.rootPassword` | `""` | Bootstrap `root` password. Required unless `existingSecret`. Min **12** chars |
| `secrets.jwtSecret` | `""` | HMAC key for API tokens. Required unless `existingSecret`. Min **32** chars |
| `secrets.existingSecret` | `""` | Name of a Secret you manage; the chart then renders no Secret of its own |
| `secrets.rootPasswordKey` | `ROOT_PASSWORD` | Key read from that Secret |
| `secrets.jwtSecretKey` | `JWT_SECRET` | Key read from that Secret |
| `secrets.autoGenerateJwtSecret` | `false` | Generate a random 48-char JWT secret on first install |
| `secrets.allowInsecureDefaults` | `false` | Local development only — skips every check and sets `VF_ALLOW_INSECURE_DEFAULTS=1` on the API |

The thresholds match the API, which exits non-zero on an empty, short, or known-default
credential ([core#93](https://github.com/virtfoundry/core/issues/93)). A chart that
rendered such a value would only move the failure to the first pod start.

### Option A — pass the values (simplest)

```bash
helm upgrade --install virtfoundry virtfoundry/virtfoundry \
  --namespace virtfoundry-system \
  --set secrets.rootPassword='choose-a-strong-password' \
  --set secrets.jwtSecret="$(openssl rand -hex 32)"
```

### Option B — `existingSecret` (recommended for GitOps)

Create the Secret with whatever tool owns your secrets (Sealed Secrets, External
Secrets, SOPS, `kubectl` for a one-off), then reference it:

```bash
kubectl -n virtfoundry-system create secret generic virtfoundry-credentials \
  --from-literal=ROOT_PASSWORD='choose-a-strong-password' \
  --from-literal=JWT_SECRET="$(openssl rand -hex 32)"

helm upgrade --install virtfoundry virtfoundry/virtfoundry \
  --namespace virtfoundry-system \
  --set secrets.existingSecret=virtfoundry-credentials
```

The API reads `ROOT_PASSWORD` and `JWT_SECRET` from that Secret. Rename the keys with
`secrets.rootPasswordKey` / `secrets.jwtSecretKey`. When the chart can read the Secret
(a real install or `--dry-run=server`), it also verifies the stored values are present
and not sentinels — a Secret missing `JWT_SECRET` fails the install instead of producing
a crash-looping API.

### Upgrades do not reset credentials

`helm upgrade` without `--set secrets.*` reads the current values back from the live
Secret, so the root password stays valid and issued tokens keep verifying. Credentials
change only when you pass a new value explicitly.

`secrets.autoGenerateJwtSecret: true` extends that to the first install: the chart
generates a 48-char secret, and later upgrades reuse the stored one. If the live Secret
cannot be read during an upgrade, the render **fails** rather than silently rotating the
key.

### GitOps / Argo CD

`lookup` needs an API connection. It returns nothing during `helm template` and
client-side dry-runs, which is why `autoGenerateJwtSecret` is off by default:

- **Argo CD and similar:** use `secrets.existingSecret` and let your secrets operator own
  the value. Do not rely on generation — a dry-run that cannot see the Secret would
  otherwise produce a different key on each render.
- **Overlay values files must carry real credentials.** An overlay still holding
  `rootPassword: virtfoundry` or `jwtSecret: change-me-in-production` now fails to sync,
  which is the intended outcome.
- CI that only renders templates should pass throwaway values that satisfy the length
  rules (see `.github/workflows/chart-lint.yaml`).

## Platform store

Platform state lives in **`virtfoundry.io` CRDs**. Install **`virtfoundry-operator`** before the API chart.

```yaml
store:
  driver: kubernetes   # default in values.yaml
```

Verify:

```bash
kubectl get crd | grep virtfoundry.io
kubectl get vf-tenant
kubectl get vf-instance -A
```

## RBAC (API permissions)

The API ClusterRole grants only the verbs the API calls: `nodes` and `pods` are read
only, `secrets` never gets `list`, `watch` or `delete`, and `virtfoundry.io` resources
are enumerated one by one instead of `*`.

Tenant workloads live in namespaces the API creates at runtime
(`virtfoundry-tenant-{slug}`), and RBAC matches neither name prefixes nor labels, so
those rules stay cluster scoped. Two settings narrow what is left:

| Key | Default | Effect |
|-----|---------|--------|
| `rbac.api.secretNamespaces` | `[]` | List your tenant namespaces to replace the cluster-scoped Secret rule with a `Role` per namespace |
| `namespaceGuard.enabled` | `true` | `ValidatingAdmissionPolicy` denying the API ServiceAccount any Namespace `DELETE` outside `virtfoundry-tenant-*` / `virtfoundry-vpc-*` (Kubernetes 1.30+) |

```bash
helm upgrade virtfoundry virtfoundry/virtfoundry \
  --reuse-values \
  --set 'rbac.api.secretNamespaces={virtfoundry-tenant-acme,virtfoundry-tenant-globex}'
```

A tenant namespace missing from that list cannot store API-key Secrets, so
tenant-scoped API keys created there fail to authenticate. Full rule-by-rule
rationale: [chart README — API permissions](https://github.com/virtfoundry/helm-charts/blob/main/charts/virtfoundry/README.md#api-permissions).

## Public networking

Enable routable VM IPs on a host bridge + Multus NAD. VLAN tagging is optional — laptop walkthrough: [Kind](kind.md); real nodes: [Topologies — public underlay](topologies.md#public-network-underlay). Written chart defaults: [Chart values](chart-values.md).

If you **do not** `--set` public CIDR/gateway, `autoFromCluster: true` copies a `/24` from the first Node **InternalIP** (kubelet address), gateway `.1`, pool `.20–.80`. Public stays **disabled** until you set `public.enabled: true`. Auto never sets `uplink`.

Same LAN as Kubernetes (typical small homelab): enable public only after a second NIC or existing `br0`. **Different VLAN than Node InternalIP** (example: nodes `10.0.30.0/24`, VMs `10.0.50.0/24`): set `autoFromCluster: false` and write the VLAN CIDR (`values-homelab.yaml`).

```bash
./scripts/detect-host-public-net.sh   # values snippet from kubectl/host
```

| Key | Default | Description |
|-----|---------|-------------|
| `public.enabled` | `false` | Shared public network |
| `public.autoFromCluster` | `true` | Fill empty/default CIDR, gateway, pool, DNS from Node InternalIP |
| `public.cidr` | `10.0.50.0/24` | Fallback when auto cannot see the API; L3 CIDR — VLAN **or** house LAN |
| `public.gateway` | `10.0.50.254` | VM default gateway in cloud-init — **must match a reachable router IP on that CIDR** |
| `public.ipPool.start/end` | `.10`–`.99` | Allocatable guest addresses; exclude DHCP, nodes, MetalLB |
| `public.reservedRanges` | MetalLB example | IPs the VM pool must not use |
| `public.bridge.name` | `vf-pub0` | Linux bridge (≤15 chars / IFNAMSIZ), or an existing host `br0` |
| `public.bridge.uplink` | `""` | VLAN iface or **second** NIC enslaved into the bridge. Same name on every node. |
| `public.bridge.address` | `""` | Optional host IP on the public L2 (outside VM/LB pools) |
| `public.nad.name` | `virtfoundry-public` | Multus NAD (always CNI `bridge`) |
| `vm.allowPodNetwork` | `true` | Pod masquerade + public secondary NIC |

!!! warning "Gateway must be reachable"
    `public.gateway` must be an IP that exists on your L3 router for the configured CIDR. VMs receive this address via cloud-init when using the static IP pool.

!!! danger "Do not enslave the Kubernetes NIC"
    `uplink` must not be the interface that holds the node IP (SSH/kubelet). Bridge-keeper runs `ip link set <uplink> master <bridge>`. Use a VLAN subinterface, a second NIC, or point `bridge.name` at an existing mgmt bridge with `uplink` empty.

## Storage

VirtFoundry does **not** ship a storage backend. It uses **StorageClasses already present on your cluster** (Longhorn, Ceph RBD, NFS, OpenEBS, `local-path`, cloud provider disks, etc.).

!!! tip "Preferred: Longhorn"
    **[Longhorn](https://longhorn.io/)** is the recommended StorageClass for VirtFoundry beyond a single-node throwaway lab: replicated block volumes, CSI volume snapshots, and disks that survive a worker loss. Keep `local-path` only for quick demos; set `platform.storage.defaultClass=longhorn` (and make `longhorn` the cluster default) as soon as you have two or more workers.

### Default StorageClass (`platform.storage`)

| Key | Default | Description |
|-----|---------|-------------|
| `storage.defaultClass` | `auto` | Longhorn if present, else cluster default, else `local-path` |
| `storage.snapshotClass` | `""` | CSI `VolumeSnapshotClass` for volume snapshots; empty uses cluster default |
| `storage.windowsBootSizeGi` | `32` | Boot disk size when deploying from an ISO template |
| `storage.windowsISOSizeGi` | `8` | ISO import PVC size |

List classes on the cluster, then point VirtFoundry at Longhorn (or another replicated CSI):

```bash
kubectl get storageclass
kubectl get volumesnapshotclass
```

```yaml
platform:
  storage:
    defaultClass: auto       # or longhorn / ceph-rbd / local-path
    snapshotClass: ""        # empty → longhorn when default resolves to longhorn
    windowsBootSizeGi: 32
    windowsISOSizeGi: 8
```

Helm one-liner:

```bash
helm upgrade --install virtfoundry virtfoundry/virtfoundry \
  --set platform.storage.defaultClass=longhorn \
  --set platform.storage.snapshotClass=longhorn \
  ...
```

### What uses which StorageClass

| Workload | Controlled by | Notes |
|----------|---------------|-------|
| ISO import / install-from-ISO (CDI) | `platform.storage.defaultClass` | Blank boot disk + HTTP ISO `DataVolume` |
| VM template (API) | `storage_class` on template **or** default above | Per-template override in `POST /vm-templates` |
| Container-disk templates | — | Image pulled as `containerDisk`; no PVC for the OS image |
| Tenant volumes (`/volumes` UI) | Cluster / app default | Uses Kubernetes PVC creation; wire to `defaultClass` in a future release |

### Snapshots: VM vs volume

VirtFoundry exposes **two different** snapshot features. They use different Kubernetes APIs and have different cluster prerequisites.

| Feature | UI / API | Kubernetes API | Requires |
|---------|----------|----------------|----------|
| **VM snapshot** | `/vm-snapshots`, VM detail → Snapshots | `VirtualMachineSnapshot` (`snapshot.kubevirt.io`) | KubeVirt (already required) |
| **Volume snapshot** | `/snapshots` | `VolumeSnapshot` (`snapshot.storage.k8s.io`) | CSI snapshot stack + a StorageClass whose CSI driver supports snapshots |

**Volume snapshots do not work with `local-path`.**  
`rancher.io/local-path` is not a CSI driver with snapshot support. Creating a volume snapshot on a lab cluster that only has `local-path` fails with:

```text
create volumesnapshot: the server could not find the requested resource
```

That error means the cluster is missing the VolumeSnapshot CRDs (`snapshot.storage.k8s.io`), and even after installing them you still need a CSI backend that can actually take snapshots.

**To enable volume snapshots**, install all of the following on the cluster (VirtFoundry does not bundle them):

1. **CSI external-snapshotter** — CRDs + snapshot-controller  
   ([kubernetes-csi/external-snapshotter](https://github.com/kubernetes-csi/external-snapshotter))
2. **A CSI StorageClass with snapshot support** — for example [Longhorn](https://longhorn.io/) (CNCF, Apache 2.0), Rook/Ceph RBD, or a cloud-provider CSI
3. **A `VolumeSnapshotClass`** for that driver — either a cluster default (`snapshot.storage.kubernetes.io/is-default-class: "true"`) or set `platform.storage.snapshotClass` (e.g. `longhorn`). Empty config omits `volumeSnapshotClassName` so Kubernetes uses the default class.

Verify before using the UI:

```bash
kubectl api-resources | grep volumesnapshot
kubectl get volumesnapshotclass
kubectl get storageclass
```

For point-in-time backup of a whole guest on a `local-path` / lab cluster, use **VM snapshots** instead of volume snapshots.

### Per-template override (API)

When registering a template, set `storage_class` to use a different class for that image only:

```json
{
  "name": "win2022-eval",
  "source_type": "iso",
  "image": "https://example.com/win.iso",
  "storage_class": "ceph-rbd"
}
```

If omitted, the API falls back to `platform.storage.defaultClass` from Helm.

## Profiles

| File | Use case |
|------|----------|
| `values.yaml` | Generic / production defaults |

Additional value overlays can set Gateway API hostnames, image tags, and platform networking for your cluster.

## Local dev

Generate `virtfoundry/config/config.yaml` from Helm values:

```bash
make render-local-config
make render-local-config VALUES=./charts/virtfoundry/values.yaml
```

## Secrets

Never commit production secrets. Pass them on the **same** Helm command as the chart (`--set` or `-f`). See [Chart values](chart-values.md).

```bash
helm upgrade --install virtfoundry ./charts/virtfoundry \
  --set secrets.jwtSecret='...' \
  --set secrets.rootPassword='...'
```
