# VirtForge Cloud — Helm Chart

Official Helm chart and homelab tooling for deploying [VirtForge Cloud](https://github.com/virtforge-cloud/virtforge).

Extended install docs: **[Wiki](https://github.com/virtforge-cloud/virtforge-chart/wiki)**

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

## Homelab (Kustomize)

Clone [virtforge](https://github.com/virtforge-cloud/virtforge) next to this repo, then:

```bash
./setup-kubevirt.sh
./deploy-homelab.sh
```

`deploy-homelab.sh` builds images from the sibling `virtforge` repo, applies the kustomize overlay, and imports images into node containerd (NodePort UI on `:30880`).

Manual apply only:

```bash
kubectl apply -k kustomize/overlays/homelab
```

## Layout

| Path | Purpose |
|------|---------|
| `charts/virtforge/` | Helm chart (production install) |
| `kustomize/base/` | Kustomize base manifests |
| `kustomize/overlays/homelab/` | Homelab overlay (NodePort, local images) |
| `deploy-homelab.sh` | Full homelab rebuild + deploy |
| `setup-kubevirt.sh` | Install KubeVirt on cluster |
| `setup-multus.sh` | Install Multus + bridge |
| `setup-cdi.sh` | Install CDI for DataVolumes |

## Contributing

Commits in **English**, [Conventional Commits](https://www.conventionalcommits.org/). See [CONTRIBUTING.md](CONTRIBUTING.md).

## License

Apache License 2.0
