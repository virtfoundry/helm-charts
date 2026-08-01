# virtforge

Helm chart for the VirtForge Cloud control plane (API, worker, UI, optional MySQL).

## Install

```bash
helm install virtforge . \
  --namespace virtforge-system \
  --create-namespace
```

## Profiles

| File | Use case |
|------|----------|
| `values.yaml` | Default — Ingress, GHCR image tags |
| `values-homelab.yaml` | Gateway API HTTPRoute, homelab hostnames |

## Docs

Repository root [README.md](../../README.md) and [Wiki](https://github.com/virtforge-cloud/virtforge-chart/wiki).
