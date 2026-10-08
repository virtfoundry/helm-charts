# Configuration

VirtFoundry runtime configuration is YAML rendered by Helm into a ConfigMap. **Helm values are the source of truth in Kubernetes.**

## Values → ConfigMap

| Helm value | Config field | Notes |
|------------|--------------|-------|
| `store.driver` | `database.driver` | Default `kubernetes` (`virtfoundry.io` CRDs) |
| `config.logLevel` | `logger.level` | |
| `config.jwtExpire` | `security.jwt_expire` | |
| `config.kubevirtEnabled` | `kubevirt.enabled` | |
| `api.security.allowedOrigins` | `security.allowed_origins` | CORS / WS Origin allowlist — see [Allowed origins](#allowed-origins-cors-websockets) |
| `platform.networking.public.*` | `networking.public.*` | Shared VM network (off by default) |
| `platform.networking.isolated.enabled` | — | Host bridge DaemonSet for tenant VPCs (off by default; see [Host bridges](networking-config.md#host-bridges-isolated-public)) |
| `platform.networking.isolated.bridge.name` | `networking.isolated.bridge_name` | Tenant VPC bridge |
| `platform.networking.vm.*` | `networking.vm.*` | Default VM networking |
| `platform.storage.*` | `storage.*` | Default StorageClass for CDI/ISO disks |
| `secrets.jwtSecret` | — | Env `JWT_SECRET` on API (not in ConfigMap) — see [Secrets](#secrets) |
| `secrets.rootPassword` | — | Env `ROOT_PASSWORD` on API — see [Secrets](#secrets) |

## Pod hardening (API / UI)

API and UI Deployments match the operator chart pattern: `runAsNonRoot`, drop `ALL` capabilities, `seccompProfile: RuntimeDefault`, `readOnlyRootFilesystem` with emptyDir mounts, and resource requests/limits ([#42](https://github.com/virtfoundry/helm-charts/issues/42)).

| Key | Default | Notes |
|-----|---------|-------|
| `ui.containerPort` | `8080` | Non-root listen; Service stays `port: 80` → targetPort 8080 |
| `ui` / `api` `resources` | set | Override per environment |
| `ui` SA | dedicated | `automountServiceAccountToken: false` |
| `api` SA | `-api` | Token mounted (kube-apiserver client) |
| `networkPolicy.enabled` | `true` | Control-plane NetworkPolicy; set `false` if the CNI does not enforce NP |
| `networkPolicy.allowedIngressNamespaces` | `[]` | Empty = any namespace may hit UI/API HTTP ports; list Ingress/Gateway namespaces to restrict |

The chart mounts an nginx ConfigMap so the UI works as UID 101 even when the image still ships a port-80 default. Prefer UI images that listen on 8080 (core `docker/Dockerfile.ui`). Residual: bootstrap secrets remain env vars (`ROOT_PASSWORD` / `JWT_SECRET`); file mounts need an API change.

## Allowed origins (CORS / WebSockets)

After [core#98](https://github.com/virtfoundry/core/issues/98) / [PR #113](https://github.com/virtfoundry/core/pull/113), the API never emits `Access-Control-Allow-Origin: *`. CORS and the `/ws/events` / `/ws/console` Origin checks accept:

1. The **request host** itself (same-origin), and
2. Any origin listed in `security.allowed_origins`

| Deploy layout | Set `api.security.allowedOrigins`? |
|---------------|------------------------------------|
| **Default chart** — Ingress or Gateway fronts the UI; UI nginx proxies `/api/` and `/ws/` on the same host | **No** — leave `[]`. Same-origin proxy needs nothing. |
| **Split UI/API** — browser loads the UI from a different origin than the API (e.g. `https://console.example.com` calling `https://api.example.com`) | **Yes** — list every UI origin the browser will send |

```yaml
api:
  security:
    allowedOrigins:
      - "https://console.example.com"
```

Empty means fail closed for cross-origin traffic (no `*`). Operators can also override via env `VIRTFOUNDRY_ALLOWED_ORIGINS` (comma-separated) on the API pod; the chart writes the YAML list into the ConfigMap.

## Secrets

The chart ships **no** credential defaults. A root password or HMAC key published in a
public repository is a cluster-compromise path, so the chart refuses to render instead
of installing one. `helm install` / `helm template` with plain defaults fails with an
explicit error, and the sentinels `virtfoundry` and `change-me-in-production` are
rejected even if you pass them by hand.

| Key | Default | Description |
|-----|---------|-------------|
| `secrets.rootPassword` | `""` | Bootstrap `root` password. Required unless `existingSecret`. Min **12** chars |
| `secrets.jwtSecret` | `""` | HMAC key for API tokens. Required unless `existingSecret`. Min **32** chars |
| `secrets.existingSecret` | `""` | Name of a Secret you manage; the chart then renders no Secret of its own |
| `secrets.rootPasswordKey` | `ROOT_PASSWORD` | Key read from that Secret |
| `secrets.jwtSecretKey` | `JWT_SECRET` | Key read from that Secret |
| `secrets.autoGenerateJwtSecret` | `false` | Generate a random 48-char JWT secret on first install |
| `secrets.allowInsecureDefaults` | `false` | Local development only — skips every check and sets `VF_ALLOW_INSECURE_DEFAULTS=1` on the API |

The thresholds match the API, which exits non-zero on an empty, short, or known-default
credential ([core#93](https://github.com/virtfoundry/core/issues/93)). A chart that
rendered such a value would only move the failure to the first pod start.

### Option A — pass the values (simplest)

```bash
helm upgrade --install virtfoundry virtfoundry/virtfoundry \
  --namespace virtfoundry-system \
  --set secrets.rootPassword='choose-a-strong-password' \
  --set secrets.jwtSecret="$(openssl rand -hex 32)"
```

### Option B — `existingSecret` (recommended for GitOps)

Create the Secret with whatever tool owns your secrets (Sealed Secrets, External
Secrets, SOPS, `kubectl` for a one-off), then reference it:

```bash
kubectl -n virtfoundry-system create secret generic virtfoundry-credentials \
  --from-literal=ROOT_PASSWORD='choose-a-strong-password' \
  --from-literal=JWT_SECRET="$(openssl rand -hex 32)"

helm upgrade --install virtfoundry virtfoundry/virtfoundry \
  --namespace virtfoundry-system \
  --set secrets.existingSecret=virtfoundry-credentials
```

The API reads `ROOT_PASSWORD` and `JWT_SECRET` from that Secret. Rename the keys with
`secrets.rootPasswordKey` / `secrets.jwtSecretKey`. When the chart can read the Secret
(a real install or `--dry-run=server`), it also verifies the stored values are present
and not sentinels — a Secret missing `JWT_SECRET` fails the install instead of producing
a crash-looping API.

### Upgrades do not reset credentials

`helm upgrade` without `--set secrets.*` reads the current values back from the live
Secret, so the root password stays valid and issued tokens keep verifying.

Passing a new `secrets.jwtSecret` changes the signing key (after the API restarts). Passing a
new `secrets.rootPassword` does **not** change the password you log in with: the API uses it
only to create `root` on the first start. To change it, see
[Security and credentials](security.md#change-the-root-password).

`secrets.autoGenerateJwtSecret: true` extends that to the first install: the chart
generates a 48-char secret, and later upgrades reuse the stored one. If the live Secret
cannot be read during an upgrade, the render **fails** rather than silently rotating the
key.

### GitOps / Argo CD

`lookup` needs an API connection. It returns nothing during `helm template` and
client-side dry-runs, which is why `autoGenerateJwtSecret` is off by default:

- **Argo CD and similar:** use `secrets.existingSecret` and let your secrets operator own
  the value. Do not rely on generation — a dry-run that cannot see the Secret would
  otherwise produce a different key on each render.
- **Overlay values files must carry real credentials.** An overlay still holding
  `rootPassword: virtfoundry` or `jwtSecret: change-me-in-production` now fails to sync,
  which is the intended outcome.
- CI that only renders templates should pass throwaway values that satisfy the length
  rules (see `.github/workflows/chart-lint.yaml`).

## Ingress and TLS

The chart does **not** expose a cleartext HTTP control plane by default.

| Key | Default | Notes |
|-----|---------|-------|
| `ingress.enabled` | `false` | Opt in. When `true`, you must set `ingress.tls` **or** `ingress.allowCleartext: true` |
| `ingress.tls` | `[]` | Standard Ingress `spec.tls` entries (`secretName` + `hosts`) |
| `ingress.allowCleartext` | `false` | Lab-only escape hatch for HTTP without TLS |
| `ingress.annotations` | nginx timeouts | Add cert-manager keys here (`cert-manager.io/cluster-issuer`, `ssl-redirect`, …) |
| `gateway.enabled` | `false` | Mutually exclusive with Ingress |
| `gateway.parentRefs[].sectionName` | `websecure` | Bind the HTTPS Gateway listener; use `web` only for redirect |

Example with cert-manager (also shipped as `charts/virtfoundry/values-ingress-tls.yaml`):

```yaml
ingress:
  enabled: true
  host: iaas.example.com
  annotations:
    cert-manager.io/cluster-issuer: letsencrypt-prod
    nginx.ingress.kubernetes.io/ssl-redirect: "true"
  tls:
    - secretName: virtfoundry-tls
      hosts:
        - iaas.example.com
```

### Gateway API HTTPS

`values-gateway.yaml` binds `sectionName: websecure`. Your Gateway must expose an HTTPS listener with that name (TLS cert on the Gateway/Listener, not in the chart).

For HTTP→HTTPS redirect, apply a second HTTPRoute on the cleartext listener (`sectionName: web`) with a `RequestRedirect` filter — see [httproute-https-redirect.yaml](../examples/httproute-https-redirect.yaml).

Homelab overlays that still use `sectionName: web` alone keep cleartext HTTP until the Gateway gains `websecure` and a redirect route.

## Platform store

Platform state lives in **`virtfoundry.io` CRDs**. Install **`virtfoundry-operator`** before the API chart.

```yaml
store:
  driver: kubernetes   # default in values.yaml
```

Verify:

```bash
kubectl get crd | grep virtfoundry.io
kubectl get vf-tenant
kubectl get vf-instance -A
```

## RBAC (API permissions)

The API ClusterRole grants only the verbs the API calls: `nodes` and `pods` are read
only, `secrets` never gets `list`, `watch` or `delete`, and `virtfoundry.io` resources
are enumerated one by one instead of `*`.

Tenant workloads live in namespaces the API creates at runtime
(`virtfoundry-tenant-{slug}`), and RBAC matches neither name prefixes nor labels, so
those rules stay cluster scoped. Two settings narrow what is left:

| Key | Default | Effect |
|-----|---------|--------|
| `rbac.api.secretNamespaces` | `[]` | List your tenant namespaces to replace the cluster-scoped Secret rule with a `Role` per namespace |
| `namespaceGuard.enabled` | `true` | `ValidatingAdmissionPolicy` denying the API ServiceAccount any Namespace `DELETE` outside `virtfoundry-tenant-*` / `virtfoundry-vpc-*` (Kubernetes 1.30+) |

```bash
helm upgrade virtfoundry virtfoundry/virtfoundry \
  --reuse-values \
  --set 'rbac.api.secretNamespaces={virtfoundry-tenant-acme,virtfoundry-tenant-globex}'
```

A tenant namespace missing from that list cannot store API-key Secrets, so
tenant-scoped API keys created there fail to authenticate. Full rule-by-rule
rationale: [chart README — API permissions](https://github.com/virtfoundry/helm-charts/blob/main/charts/virtfoundry/README.md#api-permissions).

## Networking and storage

- [Networking configuration](networking-config.md) — public networking, host bridges
- [Storage configuration](storage-config.md) — StorageClasses, snapshots, per-template override

## Profiles

| File | Use case |
|------|----------|
| `values.yaml` | Generic defaults (Ingress off) |
| `values-ingress-tls.yaml` | Ingress + TLS / cert-manager |
| `values-gateway.yaml` | Gateway API HTTPS (`websecure`) |
| `values-kind.yaml` | Kind / NodePort |

Additional value overlays can set Gateway API hostnames, image tags, and platform networking for your cluster. Homelab GitOps values live in the Argo CD values repo (not published with the chart).

## Local dev

Generate `virtfoundry/config/config.yaml` from Helm values:

```bash
make render-local-config
make render-local-config VALUES=./charts/virtfoundry/values.yaml
```
