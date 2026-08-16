# VirtFoundry Helm Charts

Official Helm charts for [VirtFoundry](https://github.com/virtfoundry/core) — private cloud IaaS on Kubernetes.

**Documentation (canonical front door):** [virtfoundry.github.io/helm-charts/docs/](https://virtfoundry.github.io/helm-charts/docs/)

## Quick install

Laptop (kind, no VLAN): **[Kind guide](docs/guide/kind.md)**. Any cluster:

```bash
helm repo add virtfoundry https://virtfoundry.github.io/helm-charts
helm repo update
helm install virtfoundry virtfoundry/virtfoundry \
  --version 0.5.0 \
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
| [Why VirtFoundry](https://github.com/virtfoundry/core/blob/main/docs/WHY.md) | Positioning (Proxmox / KubeVirt) |
| [Traction checklist](https://github.com/virtfoundry/core/blob/main/docs/CNCF-CHECKLIST.md) | CNCF / community phases |

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md). [GOVERNANCE.md](GOVERNANCE.md) · [SECURITY.md](SECURITY.md) · [CODE_OF_CONDUCT.md](CODE_OF_CONDUCT.md)

## License

Apache License 2.0 — see [LICENSE](LICENSE) and [NOTICE](NOTICE).