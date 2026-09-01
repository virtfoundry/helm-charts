# virtfoundry

Helm chart for the VirtFoundry control plane (**API + UI**).

Platform state is stored in **`virtfoundry.io` CRDs** (recommended) or legacy embedded MySQL.

## Prerequisites (cluster)

Install **before** this chart:

1. **KubeVirt**, **Multus**, **CDI** (for ISO/import) — cluster-scoped; not bundled here
2. **`virtfoundry-operator`** — when using `store.driver=kubernetes` (recommended)

See [Installation guide](https://virtfoundry.github.io/helm-charts/docs/guide/installation/).

## Install (CRD store — recommended)

```bash
helm repo add virtfoundry https://virtfoundry.github.io/helm-charts
helm repo update

helm install virtfoundry-operator virtfoundry/virtfoundry-operator \
  --namespace virtfoundry-system --create-namespace

helm install virtfoundry virtfoundry/virtfoundry \
  --namespace virtfoundry-system \
  --set secrets.rootPassword='change-me' \
  --set secrets.jwtSecret='change-me-long-random' \
  -f values-kubernetes.yaml
```

From a git clone: `helm install virtfoundry ./charts/virtfoundry -f ./charts/virtfoundry/values-kubernetes.yaml ...`

## Profiles

| File | Use case |
|------|----------|
| `values.yaml` | Default — legacy MySQL store (backward compatible) |
| `values-kubernetes.yaml` | **Recommended** — CRD store, no MySQL/worker |
| `values-kind.yaml` | Kind / laptop — NodePort 8080 |
| `values-gateway.yaml` | Gateway API HTTPRoute example |
| `values-homelab.yaml` | Reference homelab overlay (Gateway + public net) |

## Docs

Repository [README.md](../../README.md) and [documentation site](https://virtfoundry.github.io/helm-charts/docs/).
