# virtforge

Helm chart for the VirtForge Cloud control plane (API, worker, UI, optional MySQL).

## Prerequisites (cluster)

Install **before** this chart:

- **KubeVirt** — VM hypervisor (required)
- **Multus** — multi-network / VPC / public NICs (required)
- **CDI** — ISO and `DataVolume` imports (required for ISO templates; optional for container-disk-only)

See [Installation guide](https://virtforge-cloud.github.io/virtforge-chart/docs/guide/installation/#why-each-platform-component-is-needed).

## Install

```bash
helm repo add virtforge https://virtforge-cloud.github.io/virtforge-chart
helm repo update
helm install virtforge virtforge/virtforge \
  --namespace virtforge-system \
  --create-namespace
```

From a git clone: `helm install virtforge ./charts/virtforge ...`

## Profiles

| File | Use case |
|------|----------|
| `values.yaml` | Default — Ingress, GHCR image tags |
| `values-homelab.yaml` | Gateway API HTTPRoute, homelab hostnames |

## Docs

Repository root [README.md](../../README.md) and [Wiki](https://github.com/virtforge-cloud/virtforge-chart/wiki).
