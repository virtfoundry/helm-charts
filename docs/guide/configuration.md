# Configuration

VirtForge runtime configuration is YAML rendered by Helm into a ConfigMap. **Helm values are the source of truth in Kubernetes.**

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
| `public.bridge.name` | `virtforge-pub0` | Linux bridge |
| `public.bridge.uplink` | `""` | Physical or VLAN interface attached to the bridge |
| `public.bridge.address` | `""` | Optional bridge IP for dnsmasq |
| `public.nad.name` | `virtforge-public` | Multus NAD |
| `vm.allowPodNetwork` | `true` | Pod masquerade + public secondary NIC |

!!! warning "Gateway must be reachable"
    `public.gateway` must be an IP that exists on your L3 router for the configured CIDR. VMs receive this address via cloud-init when using the static IP pool.

## Profiles

| File | Use case |
|------|----------|
| `values.yaml` | Generic / production defaults |

Additional value overlays can set Gateway API hostnames, image tags, and platform networking for your cluster.

## Local dev

Generate `virtforge/config/config.yaml` from Helm values:

```bash
make render-local-config
make render-local-config VALUES=./charts/virtforge/values.yaml
```

## Secrets

Never commit production secrets. Prefer:

```bash
helm upgrade --install virtforge ./charts/virtforge \
  --set secrets.jwtSecret='...' \
  --set secrets.rootPassword='...'
```
