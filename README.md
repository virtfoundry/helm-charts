# VirtForge Cloud — Helm Charts

Official Helm charts for deploying [VirtForge Cloud](https://github.com/virtforge-cloud/virtforge).

Extended install docs: **[Wiki](https://github.com/virtforge-cloud/charts/wiki)**

## Charts

| Chart | Description |
|-------|-------------|
| [virtforge](charts/virtforge) | Control plane: API, worker, UI, optional MySQL, ingress |

The umbrella chart deploys **frontend and backend together** — they share the same release version.

## Prerequisites

- Kubernetes 1.28+
- [KubeVirt](https://kubevirt.io/) installed
- [Multus](https://github.com/k8snetworkplumbingwg/multus-cni) (for VPC networks)
- Ingress controller (when `ingress.enabled=true`)

## Install

```bash
helm install virtforge ./charts/virtforge \
  --namespace nimbus-system \
  --create-namespace \
  --set secrets.rootPassword='your-root-password' \
  --set secrets.jwtSecret='your-jwt-secret'
```

## Upgrade

```bash
helm upgrade virtforge ./charts/virtforge -n nimbus-system
```

## Values (highlights)

| Key | Default | Description |
|-----|---------|-------------|
| `images.api` | `ghcr.io/virtforge-cloud/iaas-api:0.1.0` | API image |
| `images.ui` | `ghcr.io/virtforge-cloud/iaas-ui:0.1.0` | UI image |
| `mysql.enabled` | `true` | Embedded MySQL StatefulSet |
| `ingress.host` | `iaas.local` | Ingress hostname |

See [charts/virtforge/values.yaml](charts/virtforge/values.yaml) for all options.

## Contributing

Commits in **English**, [Conventional Commits](https://www.conventionalcommits.org/). See [CONTRIBUTING.md](CONTRIBUTING.md).

## License

Apache License 2.0
