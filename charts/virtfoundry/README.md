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

## Allowed origins (CORS / WebSockets)

Default installs expose the UI behind Ingress/Gateway and proxy `/api` + `/ws` same-origin — leave `api.security.allowedOrigins` empty (`[]`).

Set the list only when the browser talks to the API from a **different origin** than the UI hostname (split UI/API). That maps to core `security.allowed_origins` / `VIRTFOUNDRY_ALLOWED_ORIGINS` ([core#98](https://github.com/virtfoundry/core/issues/98)).

```yaml
api:
  security:
    allowedOrigins:
      - "https://console.example.com"
```

Details: [Configuration — Allowed origins](https://virtfoundry.github.io/helm-charts/docs/guide/configuration/#allowed-origins-cors--websockets).

## API permissions

The API ClusterRole grants only the verbs the API calls, so a compromised API pod
cannot enumerate Secrets, mutate Nodes, or schedule pods of its own:

| Resource | Verbs | Why |
|----------|-------|-----|
| `nodes` | `get`, `list` | Hypervisor capacity view. No `delete`/`patch` — nothing in the API mutates Nodes |
| `pods`, `pods/log` | `get`, `list` | Console and log endpoints; virt-launcher pods are created by KubeVirt |
| `namespaces` | `get`, `list`, `create`, `delete` | Tenant and VPC namespaces, created at runtime |
| `resourcequotas` | `get`, `list`, `create` | Written once per tenant namespace |
| `secrets` | `get`, `create`, `update` | Cluster-scoped fallback only — never `list`, `watch` or `delete` |
| `virtfoundry.io` CRDs | full CRUD | Enumerated resource by resource instead of `*`, so a new CRD is granted deliberately |

### Remaining cluster scope

Tenant workloads live in namespaces the API creates at runtime
(`virtfoundry-tenant-{slug}`, `virtfoundry-vpc-{slug}-{id}`). RBAC matches neither
name prefixes nor labels, so the namespaced rules above stay in a ClusterRole; they
are kept narrow by verb instead. Namespace `delete` is additionally fenced by the
guard below.

`secrets` is the one rule you can remove outright. API-key Secrets are written next
to their APIKey CR, so a tenant-scoped key lands in that tenant's namespace, and the
Secret name is derived from the key (RBAC has no prefix matching, and it ignores
`resourceNames` on `create`). List the namespaces explicitly to trade a values change
per tenant for zero cluster-wide Secret access:

```bash
helm upgrade virtfoundry virtfoundry/virtfoundry \
  --set 'rbac.api.secretNamespaces={virtfoundry-tenant-acme,virtfoundry-tenant-globex}'
```

The release namespace is always included, and each listed namespace gets a `Role` +
`RoleBinding` with `get`/`create`/`update`/`delete` on Secrets. A tenant namespace
that is missing from the list cannot store API-key Secrets, so tenant-scoped API keys
created there will fail to authenticate.

### Namespace deletion guard

`namespaceGuard.enabled` (default `true`) installs a `ValidatingAdmissionPolicy` that
denies the API ServiceAccount any Namespace `DELETE` outside `virtfoundry-tenant-*` /
`virtfoundry-vpc-*` carrying a `virtfoundry.io/` label. It renders only on clusters
serving `admissionregistration.k8s.io/v1` policies (Kubernetes 1.30+), so the chart
still installs on older clusters — there the ClusterRole is the only limit.

## Host bridges (isolated / public)

`platform.networking.isolated.enabled` and `platform.networking.public.enabled` default
to **`false`**. Enabling either deploys a `hostNetwork` DaemonSet (`NET_ADMIN`, optional
`NET_RAW` for DHCP) with a dedicated ServiceAccount that does not automount a token.
Details: [Configuration — host bridges](https://virtfoundry.github.io/helm-charts/docs/guide/configuration/#host-bridges-isolated--public).

## Profiles

| File | Use case |
|------|----------|
| `values.yaml` | Default — Ingress **off**; CRD store, GHCR image tags; storage `auto`; public CIDR can follow Node InternalIP |
| `values-kind.yaml` | Kind / laptop — NodePort 8080 |
| `values-gateway.yaml` | Gateway API HTTPS HTTPRoute (`websecure`) |
| `values-ingress-tls.yaml` | Ingress + TLS / cert-manager example |

## Docs

Repository [README.md](../../README.md) and [documentation site](https://virtfoundry.github.io/helm-charts/docs/).
