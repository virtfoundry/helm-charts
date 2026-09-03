# virtfoundry

Helm chart for the VirtFoundry control plane (**API + UI**).

Platform state lives in **`virtfoundry.io` CRDs** (install **virtfoundry-operator** first).

## Prerequisites (cluster)

1. **KubeVirt**, **Multus**, **CDI** (for ISO/import)
2. **`virtfoundry-operator`** chart

See [Installation guide](https://virtfoundry.github.io/helm-charts/docs/guide/installation/).

## Install

**Order:** KubeVirt + Multus + CDI on the cluster → **virtfoundry-operator** → this chart (API + UI).

```bash
helm repo add virtfoundry https://virtfoundry.github.io/helm-charts
helm repo update

# After platform prerequisites (see Installation guide)
helm install virtfoundry-operator virtfoundry/virtfoundry-operator \
  --namespace virtfoundry-system --create-namespace

helm install virtfoundry virtfoundry/virtfoundry \
  --namespace virtfoundry-system \
  --set secrets.rootPassword='change-me' \
  --set secrets.jwtSecret='change-me-long-random'
```

From a git clone: `helm install virtfoundry ./charts/virtfoundry ...`

## Profiles

| File | Use case |
|------|----------|
| `values.yaml` | Default — Ingress, CRD store, GHCR image tags; storage `auto`; public CIDR can follow Node InternalIP |
| `values-kind.yaml` | Kind / laptop — NodePort 8080 |
| `values-gateway.yaml` | Gateway API HTTPRoute example |
| `values-homelab.yaml` | Reference homelab overlay (Gateway + public net) |

## Docs

Repository [README.md](../../README.md) and [documentation site](https://virtfoundry.github.io/helm-charts/docs/).
