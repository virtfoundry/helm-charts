# virtfoundry

Helm chart for the VirtFoundry control plane (API, worker, UI, optional MySQL).

## Prerequisites (cluster)

Install **before** this chart:

- **KubeVirt** — VM hypervisor (required)
- **Multus** — multi-network / VPC / public NICs (required)
- **CDI** — ISO and `DataVolume` imports (required for ISO templates; optional for container-disk-only)

See [Installation guide](https://virtfoundry.github.io/helm-charts/docs/guide/installation/#why-each-platform-component-is-needed).

## Install

```bash
helm repo add virtfoundry https://virtfoundry.github.io/helm-charts
helm repo update
helm install virtfoundry virtfoundry/virtfoundry \
  --namespace virtfoundry-system \
  --create-namespace
```

From a git clone: `helm install virtfoundry ./charts/virtfoundry ...`

## Profiles

| File | Use case |
|------|----------|
| `values.yaml` | Default — Ingress, GHCR image tags |
| `values-gateway.yaml` | Gateway API HTTPRoute example |

## Docs

Repository root [README.md](../../README.md) and [Wiki](https://github.com/virtfoundry/helm-charts/wiki).
