# VirtForge Cloud — Helm Chart

Official Helm chart and deployment tooling for [VirtForge Cloud](https://github.com/virtforge-cloud/virtforge).

Extended install docs: **[Wiki](https://github.com/virtforge-cloud/virtforge-chart/wiki)**

## Quick start

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

| Requirement | When |
|-------------|------|
| Kubernetes 1.28+ | Always |
| [KubeVirt](https://kubevirt.io/) | VM workloads |
| [Multus](https://github.com/k8snetworkplumbingwg/multus-cni) | VPC / multi-network |
| Ingress controller | `ingress.enabled=true` |
| Gateway API + controller | `gateway.enabled=true` (homelab profile) |

Platform bootstrap (KubeVirt, Multus, CDI) lives in [`scripts/`](scripts/) — outside the chart, by design.

## Configuration

| Key | Default | Description |
|-----|---------|-------------|
| `images.api` | `ghcr.io/virtforge-cloud/iaas-api:0.1.0` | API / worker image |
| `images.ui` | `ghcr.io/virtforge-cloud/iaas-ui:0.1.0` | UI image |
| `mysql.enabled` | `true` | Embedded MySQL |
| `ingress.enabled` | `true` | Classic Ingress |
| `gateway.enabled` | `false` | Gateway API HTTPRoute |
| `platform.multus.install` | `false` | Multus via Helm hook |

Full reference: [charts/virtforge/values.yaml](charts/virtforge/values.yaml)

Profiles:

- **Production / generic:** `values.yaml`
- **Homelab (Gateway API + GHCR):** [values-homelab.yaml](charts/virtforge/values-homelab.yaml)

## Homelab workflow

Clone [virtforge](https://github.com/virtforge-cloud/virtforge) as a sibling directory, then:

```bash
export KUBECONFIG=/path/to/kubeconfig   # required unless auto-detected

make setup-kubevirt    # one-time
make deploy-homelab      # build images, helm upgrade, optional sideload
```

Environment variables (common):

| Variable | Purpose |
|----------|---------|
| `KUBECONFIG` | Cluster credentials |
| `APP_ROOT` | Path to virtforge app repo (default: `../virtforge`) |
| `BUILD_IMAGES` | `true` / `false` — skip local docker build |
| `PUSH_IMAGES` | Push to GHCR; falls back to sideload on failure |
| `IMPORT_NODE` / `IMPORT_NODE_IP` | Target node for SSH sideload (no registry) |
| `INSTALL_MULTUS` | Run Multus setup before helm when `true` |

Helm only (images already in a registry):

```bash
helm upgrade --install virtforge ./charts/virtforge \
  -n virtforge-system --create-namespace \
  -f ./charts/virtforge/values-homelab.yaml
```

## Repository layout

```
virtforge-chart/
├── charts/virtforge/          # Helm chart (templates, values, profiles)
├── scripts/
│   ├── lib/common.sh          # Shared paths and kubeconfig resolution
│   ├── deploy/                # End-to-end deploy helpers
│   ├── setup/                 # One-time cluster bootstrap (KubeVirt, Multus, CDI)
│   └── sideload/              # Image import without a registry
├── Makefile                   # Primary CLI (make help)
└── .github/workflows/         # CI: helm template lint
```

See [scripts/README.md](scripts/README.md) for script details.

## Makefile targets

```bash
make help                  # list targets
make lint                  # helm template (default + homelab)
make deploy-homelab        # full homelab deploy
make setup-kubevirt       # install KubeVirt
make setup-multus         # install / verify Multus
make setup-cdi            # install CDI
make deploy-windows-test-vm   # optional Windows IOPS test VM
```

## Contributing

English commits, [Conventional Commits](https://www.conventionalcommits.org/). See [CONTRIBUTING.md](CONTRIBUTING.md).

## License

Apache License 2.0
