# VirtFoundry Helm Charts

Official Helm charts for [VirtFoundry](https://github.com/virtfoundry/core) — private cloud IaaS on Kubernetes.

**Documentation:** [virtfoundry.github.io/helm-charts/docs/](https://virtfoundry.github.io/helm-charts/docs/)

## Quick install

```bash
helm repo add virtfoundry https://virtfoundry.github.io/helm-charts
helm repo update
helm install virtfoundry virtfoundry/virtfoundry \
  --version 1.0.0 \
  -n virtfoundry-system --create-namespace \
  --set secrets.rootPassword='change-me' \
  --set secrets.jwtSecret='change-me'
```

## Prerequisites

KubeVirt, Multus, and CDI must be present on the cluster. The chart installs the **control plane only**. See the [installation guide](docs/guide/installation.md).

## Local validation

```bash
export KUBECONFIG=/path/to/kubeconfig
make lint
```

## Repository layout

```
charts/virtfoundry/     # Main application chart
docs/                    # MkDocs site (GitHub Pages)
scripts/                 # Optional setup and sideload helpers
```

## Related

| Repository | Role |
|------------|------|
| [virtfoundry/core](https://github.com/virtfoundry/core) | Application source |
| [virtfoundry/helm-charts](https://github.com/virtfoundry/helm-charts) | This repo |

## License

Apache License 2.0 — see [LICENSE](LICENSE) and [NOTICE](NOTICE).

## Migration from virtforge-chart

Formerly [virtforge-cloud/virtforge-chart](https://github.com/virtforge-cloud/virtforge-chart). The old repo remains as a mirror until deprecated.
