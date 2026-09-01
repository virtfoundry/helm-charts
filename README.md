# VirtFoundry Helm Charts

Official Helm charts for [VirtFoundry](https://github.com/virtfoundry/core) — private cloud IaaS on Kubernetes.

**Documentation (canonical front door):** [virtfoundry.github.io/helm-charts/docs/](https://virtfoundry.github.io/helm-charts/docs/)

## Quick install

**Install order:** **KubeVirt** + **Multus** + **CDI** on the cluster → **virtfoundry-operator** (CRDs) → **virtfoundry** (API + UI).

| Prerequisite | Required |
|--------------|----------|
| [KubeVirt](https://kubevirt.io/) | **Yes** — VMs, console, VM snapshots |
| [Multus CNI](https://github.com/k8snetworkplumbingwg/multus-cni) | **Yes** — VPCs, tenant networks, public IPs |
| [CDI](https://github.com/kubevirt/containerized-data-importer) | **Yes** for ISO/import; optional for container-disk templates |
| StorageClass | **Yes** for disks |
| Ingress or Gateway API | One of them — expose UI/API |

Laptop (kind, no VLAN): **[Kind guide](docs/guide/kind.md)** installs the platform stack. Full details: [installation guide](docs/guide/installation.md).

```bash
helm repo add virtfoundry https://virtfoundry.github.io/helm-charts
helm repo update

# After KubeVirt, Multus, CDI
helm install virtfoundry-operator virtfoundry/virtfoundry-operator \
  -n virtfoundry-system --create-namespace

helm install virtfoundry virtfoundry/virtfoundry \
  --version 0.5.0 \
  -n virtfoundry-system --create-namespace \
  --set secrets.rootPassword='change-me' \
  --set secrets.jwtSecret='change-me'
```

## Local validation

```bash
export KUBECONFIG=/path/to/kubeconfig
make lint
```

## Repository layout

```
charts/virtfoundry/           # Control plane (API, UI)
charts/virtfoundry-operator/  # CRDs + operator
docs/                         # MkDocs site (GitHub Pages)
scripts/                      # Optional setup and sideload helpers
```

## Related

| Repository | Role |
|------------|------|
| [virtfoundry/core](https://github.com/virtfoundry/core) | Application source |
| [virtfoundry/operator](https://github.com/virtfoundry/operator) | CRDs and Kubernetes operator |
| [Why VirtFoundry](https://github.com/virtfoundry/core/blob/main/docs/WHY.md) | Positioning (Proxmox / KubeVirt) |
| [CNCF checklist](https://github.com/virtfoundry/core/blob/main/docs/CNCF-CHECKLIST.md) | CNCF / community phases |

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md). [GOVERNANCE.md](GOVERNANCE.md) · [MAINTAINERS.md](MAINTAINERS.md) · [SECURITY.md](SECURITY.md) · [CODE_OF_CONDUCT.md](CODE_OF_CONDUCT.md)

## License

Apache License 2.0 — see [LICENSE](LICENSE) and [NOTICE](NOTICE).