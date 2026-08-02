# Configuration

VirtForge runtime config is YAML with sections: `server`, `logger`, `security`, `kubevirt`, `database`, `observability`, `networking`.

**In Kubernetes, this repo is the source of truth.** Helm renders `templates/configmap.yaml` from `values.yaml` (or a profile like `values-homelab.yaml`).

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
| `public.cidr` | `10.0.50.0/24` | L3 network CIDR |
| `public.gateway` | `10.0.50.254` | VM default gateway — **must exist on your router** (homelab: `10.0.50.1`) |
| `public.ipPool.start/end` | `10.0.50.10`–`.99` | Allocatable IP range |
| `public.bridge.name` | `virtforge-pub0` | Host bridge for Multus |
| `public.bridge.uplink` | `""` | Physical/VLAN iface (homelab: `enp3s0.50`) |
| `public.nad.name` | `virtforge-public` | Multus NAD name |
| `isolated.bridge.name` | `virtforge-br0` | Internal bridge for tenant VPCs |
| `vm.defaultNetwork` | `pod` | `pod` or `public` when no network selected |
| `vm.allowPodNetwork` | `true` | `false` = Multus-only for VM workloads |

Homelab example: [`values-homelab.yaml`](../charts/virtforge/values-homelab.yaml) enables public network on VLAN50 with MetalLB range reserved in `reservedRanges`.

## Profiles

| File | Use case |
|------|----------|
| [`values.yaml`](../charts/virtforge/values.yaml) | Generic / production defaults |
| [`values-homelab.yaml`](../charts/virtforge/values-homelab.yaml) | Homelab: Gateway API, GHCR images, platform hooks |

## Local dev parity

To generate `virtforge/config/config.yaml` from Helm values (sibling repo layout):

```bash
make render-local-config
make render-local-config VALUES=./charts/virtforge/values-homelab.yaml
```

Or set `APP_CONFIG=/path/to/config.yaml` when repos are not siblings.

## Secrets

Never commit real secrets in values files. Use:

```bash
helm upgrade --install virtforge ./charts/virtforge \
  --set secrets.jwtSecret='...' \
  --set secrets.rootPassword='...'
```

Or `--set-file` / external secret management in production.
