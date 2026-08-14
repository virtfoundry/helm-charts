# Configuration

VirtFoundry runtime config is YAML with sections: `server`, `logger`, `security`, `kubevirt`, `database`, `observability`, `networking`.

**In Kubernetes, this repo is the source of truth.** Helm renders `templates/configmap.yaml` from `values.yaml` or additional `-f` overlays.

## Values → ConfigMap

| Helm value | Config field | Notes |
|------------|--------------|-------|
| `config.logLevel` | `logger.level` | |
| `config.jwtExpire` | `security.jwt_expire` | |
| `config.kubevirtEnabled` | `kubevirt.enabled` | |
| `mysql.auth.*` | `database.dsn` | Built in template when MySQL enabled |
| `platform.networking.public.*` | `networking.public.*` | Shared/routable VM network |
| `platform.networking.isolated.bridge.name` | `networking.isolated.bridge_name` | Private tenant VPC bridge |
| `platform.networking.vm.*` | `networking.vm.*` | Default VM network behavior |
| `secrets.jwtSecret` | — | **Not** in ConfigMap; injected as `JWT_SECRET` env on API |
| `secrets.rootPassword` | — | **Not** in ConfigMap; injected as `ROOT_PASSWORD` env on API |

## Platform networking (`platform.networking`)

Configure public VM networking per site — no app code changes required.

| Key | Default | Description |
|-----|---------|-------------|
| `public.enabled` | `false` | Enable shared public network for VMs |
| `public.cidr` | `10.0.50.0/24` | L3 CIDR — VLAN subnet or the house LAN |
| `public.gateway` | `10.0.50.254` | VM default gateway — **must be reachable on your router for that CIDR** |
| `public.ipPool.start/end` | `10.0.50.10`–`.99` | Guest pool; exclude DHCP, nodes, MetalLB |
| `public.bridge.name` | `vf-pub0` | Host bridge (≤15 chars) or existing `br0` |
| `public.bridge.uplink` | `""` | VLAN iface or **second** NIC — never the kubelet/SSH NIC |
| `public.nad.name` | `virtfoundry-public` | Multus NAD (CNI `bridge`) |
| `isolated.bridge.name` | `virtfoundry-br0` | Internal bridge for tenant VPCs |
| `vm.defaultNetwork` | `pod` | `pod` or `public` when no network selected |
| `vm.allowPodNetwork` | `true` | `false` = Multus-only for VM workloads |

## Storage (`platform.storage`)

VirtFoundry uses **existing cluster StorageClasses** — not bundled storage. Chart default is `local-path` for easy labs; **prefer [Longhorn](https://longhorn.io/)** (or another replicated CSI) for anything beyond a throwaway single-node demo.

| Key | Default | Description |
|-----|---------|-------------|
| `storage.defaultClass` | `local-path` | CDI `DataVolume`s; set to `longhorn` when available |
| `storage.snapshotClass` | `""` (cluster default) | CSI `VolumeSnapshotClass` for `/snapshots`; empty omits the field |
| `storage.windowsBootSizeGi` | `32` | Boot disk for ISO-based deploys |
| `storage.windowsISOSizeGi` | `8` | ISO import PVC size |

```yaml
platform:
  storage:
    defaultClass: longhorn   # preferred
    snapshotClass: longhorn  # VolumeSnapshotClass name (or leave empty for cluster default)
```

MySQL PVC (embedded chart) uses the **cluster default** StorageClass unless the chart is extended. Per-template `storage_class` in the API overrides the global default for that template.

**Volume snapshots** (`/snapshots` UI) need CSI `VolumeSnapshot` APIs + a snapshot-capable StorageClass (Longhorn provides this). They do **not** work with `local-path`. **VM snapshots** use KubeVirt and work independently. See [Configuration guide — Snapshots](https://virtfoundry.github.io/helm-charts/docs/guide/configuration/#snapshots-vm-vs-volume).

See [Configuration guide](https://virtfoundry.github.io/helm-charts/docs/guide/configuration/#storage) for full details.

## Profiles

| File | Use case |
|------|----------|
| [`values.yaml`](../charts/virtfoundry/values.yaml) | Generic / production defaults |

Use `-f` overlays for Gateway API hostnames, public networking, and image tags specific to your cluster.

## Local dev parity

To generate `virtfoundry/config/config.yaml` from Helm values (sibling repo layout):

```bash
make render-local-config
make render-local-config VALUES=./charts/virtfoundry/values.yaml
```

Or set `APP_CONFIG=/path/to/config.yaml` when repos are not siblings.

## Secrets

Never commit real secrets in values files. Use:

```bash
helm upgrade --install virtfoundry ./charts/virtfoundry \
  --set secrets.jwtSecret='...' \
  --set secrets.rootPassword='...'
```

Or `--set-file` / external secret management in production.
