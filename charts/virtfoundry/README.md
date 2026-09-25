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
  --set secrets.rootPassword='choose-a-strong-password' \
  --set secrets.jwtSecret="$(openssl rand -hex 32)"
```

From a git clone: `helm install virtfoundry ./charts/virtfoundry ...`

## Secrets

The chart ships no credential defaults. Rendering **fails** until you provide real
values, and the published sentinels `virtfoundry` / `change-me-in-production` are
rejected outright.

| Key | Default | Notes |
|-----|---------|-------|
| `secrets.rootPassword` | `""` | Required unless `existingSecret`; min 12 chars |
| `secrets.jwtSecret` | `""` | Required unless `existingSecret`; min 32 chars (`openssl rand -hex 32`) |
| `secrets.existingSecret` | `""` | Use a Secret you manage (Sealed Secrets, External Secrets, SOPS) |
| `secrets.rootPasswordKey` / `secrets.jwtSecretKey` | `ROOT_PASSWORD` / `JWT_SECRET` | Key names inside the Secret |
| `secrets.autoGenerateJwtSecret` | `false` | Generate a 48-char JWT secret on first install, kept on upgrade via `lookup` |
| `secrets.allowInsecureDefaults` | `false` | Local development only — skips the checks and sets `VF_ALLOW_INSECURE_DEFAULTS=1` |

An upgrade that omits the credentials reuses whatever is already stored in the live
Secret, so `helm upgrade` does not reset the root password or invalidate issued tokens.
For GitOps (Argo CD) prefer `existingSecret`: `lookup` is empty during client-side
dry-runs, so generation cannot be relied on there.

Details: [Configuration — Secrets](https://virtfoundry.github.io/helm-charts/docs/guide/configuration/#secrets).

## Profiles

| File | Use case |
|------|----------|
| `values.yaml` | Default — Ingress, CRD store, GHCR image tags; storage `auto`; public CIDR can follow Node InternalIP |
| `values-kind.yaml` | Kind / laptop — NodePort 8080 |
| `values-gateway.yaml` | Gateway API HTTPRoute example |
| `values-homelab.yaml` | Reference homelab overlay (Gateway + public net) |

## Docs

Repository [README.md](../../README.md) and [documentation site](https://virtfoundry.github.io/helm-charts/docs/).
