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

## Homelab (optional)

For bare-metal clusters without a private registry, see [`scripts/deploy/homelab.sh`](scripts/deploy/homelab.sh).

```bash
export KUBECONFIG=/path/to/kubeconfig
make deploy-homelab
```

Most users only need:

```bash
helm upgrade --install virtforge ./charts/virtforge \
  -n virtforge-system --create-namespace \
  -f ./charts/virtforge/values-homelab.yaml   # optional profile
```

## Repository layout

```
virtforge-chart/
├── charts/virtforge/          # Helm chart (templates, values, profiles)
├── examples/homelab/          # Optional one-off demos (not core tooling)
├── scripts/                   # Optional homelab deploy helpers
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
make help       # list targets
make lint       # helm template (default + homelab profile)
```

Optional homelab targets: `deploy-homelab`, `setup-kubevirt`, `setup-multus`, `setup-cdi` — see [scripts/README.md](scripts/README.md).

## Contributing

English commits, [Conventional Commits](https://www.conventionalcommits.org/). See [CONTRIBUTING.md](CONTRIBUTING.md).

## License

Apache License 2.0
