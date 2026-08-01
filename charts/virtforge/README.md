# virtforge

Helm chart for the VirtForge Cloud control plane (API, worker, UI, optional MySQL).

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
