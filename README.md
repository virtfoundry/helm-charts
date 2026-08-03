# VirtForge Cloud — Helm Chart

Official Helm chart and deployment tooling for [VirtForge Cloud](https://github.com/virtforge-cloud/virtforge).

Extended install docs: **[Documentation (GitHub Pages)](https://virtforge-cloud.github.io/virtforge-chart/docs/)** · [Wiki](https://github.com/virtforge-cloud/virtforge-chart/wiki)

## Quick start

### From Helm repository (recommended)

```bash
helm repo add virtforge https://virtforge-cloud.github.io/virtforge-chart
helm repo update
helm install virtforge virtforge/virtforge \
  --namespace virtforge-system \
  --create-namespace \
  --set secrets.rootPassword='your-root-password' \
  --set secrets.jwtSecret='your-jwt-secret'
```

### From a git clone (chart developers)

```bash
helm install virtforge ./charts/virtforge \
  --namespace virtforge-system \
  --create-namespace \
  --set secrets.rootPassword='your-root-password' \
  --set secrets.jwtSecret='your-jwt-secret'
```

Validate locally:

```bash
make lint
```

## What gets deployed

| Component | Description |
|-----------|-------------|
| **API** | REST + WebSocket control plane |
| **Worker** | Async reconciliation loop |
| **UI** | React dashboard (nginx) |
| **MySQL** | Optional embedded database (StatefulSet) |

Ingress or **Gateway API HTTPRoute** exposes the UI and API on a single hostname.

## Prerequisites

VirtForge installs the **control plane only**. The cluster must already provide:

| Component | Required | Why |
|-----------|----------|-----|
| [KubeVirt](https://kubevirt.io/) | **Yes** | Runs VMs (VirtualMachine, console, snapshots) |
| [Multus](https://github.com/k8snetworkplumbingwg/multus-cni) | **Yes** | Tenant VPCs, isolated networks, public VM NICs (NADs) |
| [CDI](https://github.com/kubevirt/containerized-data-importer) | **Yes** for ISO/import; optional for container-disk-only | `DataVolume` ISO import and blank boot disks |
| Ingress **or** Gateway API | One of them | UI/API hostname |
| StorageClass | **Yes** | MySQL PVC, VM disks |

Full explanation: **[Installation guide](https://virtforge-cloud.github.io/virtforge-chart/docs/guide/installation/#why-each-platform-component-is-needed)**.

Install helpers (idempotent): [`scripts/setup/`](scripts/setup/) — KubeVirt, Multus, CDI. Optional chart hooks: `platform.multus.install`, `platform.cdi.install` (off by default).

## Configuration

| Key | Default | Description |
|-----|---------|-------------|
| `images.api` | `ghcr.io/virtforge-cloud/iaas-api:0.1.0` | API / worker image |
| `images.ui` | `ghcr.io/virtforge-cloud/iaas-ui:0.1.0` | UI image |
| `mysql.enabled` | `true` | Embedded MySQL |
| `ingress.enabled` | `true` | Classic Ingress |
| `gateway.enabled` | `false` | Gateway API HTTPRoute |
| `platform.multus.install` | `false` | Multus via Helm hook |

Full reference: [charts/virtforge/values.yaml](charts/virtforge/values.yaml) · [docs/CONFIGURATION.md](docs/CONFIGURATION.md)

Default profile: [values.yaml](charts/virtforge/values.yaml). Additional overlays can enable Gateway API, public VM networking, and custom image tags.

## Repository layout

```
virtforge-chart/
├── charts/virtforge/          # Helm chart (templates, values, profiles)
├── docs/                      # Configuration reference + MkDocs site
├── examples/                  # Optional demo workflows
├── scripts/                   # Deploy and cluster bootstrap helpers
│   ├── lib/common.sh          # Shared paths and kubeconfig resolution
│   ├── dev/                   # Local dev helpers (render config from values)
│   ├── deploy/                # End-to-end deploy helpers
│   ├── setup/                 # One-time cluster bootstrap (KubeVirt, Multus, CDI)
│   └── sideload/              # Image import without a registry
├── Makefile                   # Primary CLI (make help)
├── docs/HELM-REPO.md          # GitHub Pages release guide
└── .github/workflows/         # CI lint + chart-releaser (GitHub Pages)
```

See [scripts/README.md](scripts/README.md) for script details.

## Makefile targets

```bash
make help       # list targets
make lint       # helm template (default values profile)
make render-local-config   # write ../virtforge/config/config.yaml from values
```

Optional targets: `setup-kubevirt`, `setup-multus`, `setup-cdi` — see [scripts/README.md](scripts/README.md).

## Contributing

English commits, [Conventional Commits](https://www.conventionalcommits.org/). See [CONTRIBUTING.md](CONTRIBUTING.md).

## Sponsorship

Financial support helps maintain VirtForge without transferring code ownership. See [Sponsorship](https://virtforge-cloud.github.io/virtforge-chart/docs/project/sponsorship/) and [SPONSORS.md](SPONSORS.md).

## License

Apache License 2.0
