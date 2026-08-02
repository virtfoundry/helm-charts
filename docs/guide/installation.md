# Installation

## Prerequisites

| Component | Version | Required for |
|-----------|---------|--------------|
| Kubernetes | 1.28+ | Always |
| Helm | 3.x | Chart install |
| KubeVirt | 1.9+ | Virtual machines |
| Multus CNI | latest stable | Multi-network VMs |
| Gateway API + controller | — | Homelab HTTPRoute profile |
| MetalLB (or equivalent) | — | LoadBalancer Services on bare metal |

Platform components (KubeVirt, Multus, CDI) can be installed via chart hooks or setup scripts — see [Homelab deploy](../homelab/deploy.md).

## Install from Helm repository

```bash
helm repo add virtforge https://virtforge-cloud.github.io/virtforge-chart
helm repo update

helm install virtforge virtforge/virtforge \
  --namespace virtforge-system \
  --create-namespace \
  --set secrets.rootPassword='change-me' \
  --set secrets.jwtSecret='change-me-long-random'
```

Pin a release:

```bash
helm install virtforge virtforge/virtforge --version 0.2.0 ...
```

Images default to `ghcr.io/virtforge-cloud/iaas-api:0.2.0` and `iaas-ui:0.2.0`.

## Install from git clone

```bash
git clone https://github.com/virtforge-cloud/virtforge-chart.git
cd virtforge-chart

helm install virtforge ./charts/virtforge \
  --namespace virtforge-system \
  --create-namespace \
  --set secrets.rootPassword='change-me' \
  --set secrets.jwtSecret='change-me'
```

Validate templates:

```bash
make lint
```

## First login

Default bootstrap credentials (override with `secrets.rootPassword`):

- **User:** `root`
- **Password:** value of `secrets.rootPassword` (default in chart values: `virtforge`)

API base path: `/api/v1` on the same hostname as the UI.

## Next steps

- [Configuration](configuration.md) — Helm values and networking
- [Homelab deploy](../homelab/deploy.md) — Gateway API + VLAN50 public network
- [Helm repository](helm-repository.md) — publishing and consuming chart releases
