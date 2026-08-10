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

### Default StorageClass (`platform.storage`)

| Key | Default | Description |
|-----|---------|-------------|
| `storage.defaultClass` | `local-path` | Default class for CDI `DataVolume`s (ISO import, blank boot disks) |
| `storage.windowsBootSizeGi` | `32` | Boot disk size when deploying from an ISO template |
| `storage.windowsISOSizeGi` | `8` | ISO import PVC size |

The chart default (`local-path`) is a common lab choice — **replace it with any StorageClass that exists in your cluster**:

```bash
kubectl get storageclass
```

```yaml
platform:
  storage:
    defaultClass: longhorn   # or ceph-rbd, nfs-client, standard, etc.
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

!!! tip "Production clusters"
    Prefer a replicated block storage class (Longhorn, Ceph, cloud disk) over node-local `local-path` when VMs and volumes must survive node loss.

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
