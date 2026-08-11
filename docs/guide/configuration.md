# Configuration

VirtFoundry runtime configuration is YAML rendered by Helm into a ConfigMap. **Helm values are the source of truth in Kubernetes.**

## Values → ConfigMap

| Helm value | Config field | Notes |
|------------|--------------|-------|
| `config.logLevel` | `logger.level` | |
| `config.jwtExpire` | `security.jwt_expire` | |
| `config.kubevirtEnabled` | `kubevirt.enabled` | |
| `mysql.auth.*` | `database.dsn` | When MySQL enabled |
| `platform.networking.public.*` | `networking.public.*` | Shared VM network |
| `platform.networking.isolated.bridge.name` | `networking.isolated.bridge_name` | Tenant VPC bridge |
| `platform.networking.vm.*` | `networking.vm.*` | Default VM networking |
| `platform.storage.*` | `storage.*` | Default StorageClass for CDI/ISO disks |
| `secrets.jwtSecret` | — | Env `JWT_SECRET` on API (not in ConfigMap) |
| `secrets.rootPassword` | — | Env `ROOT_PASSWORD` on API |

## Public networking

Enable routable VM IPs on a host bridge + Multus NAD:

| Key | Default | Description |
|-----|---------|-------------|
| `public.enabled` | `false` | Shared public network |
| `public.cidr` | `10.0.50.0/24` | L3 CIDR — set to your environment |
| `public.gateway` | `10.0.50.254` | VM default gateway in cloud-init — **must match a reachable router IP on that CIDR** |
| `public.ipPool.start/end` | `.10`–`.99` | Allocatable addresses |
| `public.bridge.name` | `vf-pub0` | Linux bridge (≤15 chars / IFNAMSIZ) |
| `public.bridge.uplink` | `""` | Physical or VLAN interface attached to the bridge |
| `public.bridge.address` | `""` | Optional bridge IP for dnsmasq |
| `public.nad.name` | `virtfoundry-public` | Multus NAD |
| `vm.allowPodNetwork` | `true` | Pod masquerade + public secondary NIC |

!!! warning "Gateway must be reachable"
    `public.gateway` must be an IP that exists on your L3 router for the configured CIDR. VMs receive this address via cloud-init when using the static IP pool.

## Storage

VirtFoundry does **not** ship a storage backend. It uses **StorageClasses already present on your cluster** (Longhorn, Ceph RBD, NFS, OpenEBS, `local-path`, cloud provider disks, etc.).

!!! tip "Preferred: Longhorn"
    **[Longhorn](https://longhorn.io/)** is the recommended StorageClass for VirtFoundry beyond a single-node throwaway lab: replicated block volumes, CSI volume snapshots, and disks that survive a worker loss. Keep `local-path` only for quick demos; set `platform.storage.defaultClass=longhorn` (and make `longhorn` the cluster default) as soon as you have two or more workers.

### Default StorageClass (`platform.storage`)

| Key | Default | Description |
|-----|---------|-------------|
| `storage.defaultClass` | `local-path` | Chart default for easy labs; **prefer `longhorn` in real clusters** |
| `storage.windowsBootSizeGi` | `32` | Boot disk size when deploying from an ISO template |
| `storage.windowsISOSizeGi` | `8` | ISO import PVC size |

List classes on the cluster, then point VirtFoundry at Longhorn (or another replicated CSI):

```bash
kubectl get storageclass
```

```yaml
platform:
  storage:
    defaultClass: longhorn   # preferred; or ceph-rbd, nfs-client, standard, …
    windowsBootSizeGi: 32
    windowsISOSizeGi: 8
```

Helm one-liner:

```bash
helm upgrade --install virtfoundry virtfoundry/virtfoundry \
  --set platform.storage.defaultClass=longhorn \
  ...
```

### What uses which StorageClass

| Workload | Controlled by | Notes |
|----------|---------------|-------|
| ISO import / install-from-ISO (CDI) | `platform.storage.defaultClass` | Blank boot disk + HTTP ISO `DataVolume` |
| VM template (API) | `storage_class` on template **or** default above | Per-template override in `POST /vm-templates` |
| Container-disk templates | — | Image pulled as `containerDisk`; no PVC for the OS image |
| Embedded MySQL (chart) | **Cluster default** StorageClass | Chart PVC has no `storageClassName` yet — set cluster default or patch chart |
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
3. **A default `VolumeSnapshotClass`** for that driver (VirtFoundry currently defaults the class name to `csi-snapclass` unless you pass another name in code/config)

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

Never commit production secrets. Prefer:

```bash
helm upgrade --install virtfoundry ./charts/virtfoundry \
  --set secrets.jwtSecret='...' \
  --set secrets.rootPassword='...'
```
