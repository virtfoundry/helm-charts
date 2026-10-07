# Changelog

See [docs/project/changelog.md](docs/project/changelog.md) for the full release history (published on GitHub Pages).

## [Unreleased]

## [0.11.1] - 2026-10-07

### Added

- **Chart e2e** workflow: fresh install, umbrella install and the CRD migration from the 0.10.x operator chart on a Kind cluster (`scripts/ci/e2e-charts.sh`).
- Troubleshooting: the `helm install virtfoundry` post-install timeout without KubeVirt, and pods stuck in `ContainerCreating` from Multus throttling ([Troubleshooting](docs/guide/troubleshooting.md)).

### Changed

- UI screenshots refreshed for 0.11.0; dependency updates (GitHub Actions, mkdocs-material).
- Chart / image pins aligned with core/operator/vks **0.11.1**.

## [0.11.0] - 2026-10-07

### Added

- `charts/virtfoundry-crds`: the 16 `virtfoundry.io` CRDs in one chart, upgraded by `helm upgrade` and protected from `helm uninstall` and Argo CD prune. `make verify-crds-chart` gate. See [CRDs and upgrades](docs/guide/crds.md).
- `charts/virtfoundry-platform`: umbrella chart for the operator, core and optional VKS in one release. Kamaji is not a dependency. `make verify-platform-parity` gate.
- Docs: Kubernetes clusters (VKS), Terraform provider, Troubleshooting, CRDs and upgrades, split Networking/Storage configuration, copy-paste install; refreshed UI screenshots; mermaid, glightbox, breadcrumbs and cards.

### Changed

- **Breaking:** the `virtfoundry-operator` chart (mirror of virtfoundry/operator) and the VKS chart no longer ship CRDs. **Install `virtfoundry-crds` first**, then the operator. Existing installs adopt their CRDs once: see [CRDs and upgrades](docs/guide/crds.md).
- Chart / image pins aligned with core/operator/vks **0.11.0**.

## [0.10.0] - 2026-10-06

### Added

- Isolated bridge host address (`platform.networking.isolated.bridge.address`) and a unique public bridge IP per node.
- API ClusterRole can manage `vksclusters`.
- Operator VAP allowlist includes `ghcr.io/virtfoundry/` (VKS node image).
- Docs: operator recovery for legacy tenant namespaces; future umbrella chart design.
- CI: API roles checked against core's RBAC contract; operator chart drift check; `requireDigest` gate restored.

### Changed

- Operator chart synced from the upstream source of truth.
- Chart / image pins aligned with core/operator **0.10.0**.

### Security

- CodeQL, Scorecard, Dependabot (grouped monthly) and dependency review.

## [0.9.0] - 2026-10-01

### Added

- Instance CRD: `spec.powerState` for CRD-first Start/Stop; `cloudInitUserData` / `cloudInitSecretRef` sync from operator.
- Optional public bridge DHCP (`platform.networking.public.dhcp.enabled`); dnsmasq as root + `NET_BIND_SERVICE`.
- Operator ClusterRole sync for Network NAD and sshkeys; VAP / kubevirt mutate RoleBinding security slices.

### Changed

- Chart / image pins aligned with core/operator **0.9.0**.

### Security

- Pin chart CI actions and CDI/Multus URLs.

## [0.8.0] - 2026-09-28

### Changed

- Chart / image pins aligned with core **0.8.0** (UI day-2 polish). No chart schema change.

## [0.7.3] - 2026-09-25

### Fixed

- Control-plane NetworkPolicy DNS egress allows NodeLocalDNS (and any DNS on port 53), not only `kube-system` CoreDNS pods — fixes UI nginx CrashLoop (`host not found in upstream "virtfoundry-api"`) on Kubespray clusters.

## [0.7.2] - 2026-09-25

Security release: Restricted PSS pods, isolated networking default off, Ingress TLS-by-default, secrets fail-closed, CORS origins, CDI importer egress docs.

### Security

- Harden API/UI pods for Restricted PSS alignment (closes [#42](https://github.com/virtfoundry/helm-charts/issues/42)): `runAsNonRoot`, drop ALL caps, `seccompProfile: RuntimeDefault`, `readOnlyRootFilesystem` + emptyDir for `/tmp` (and nginx cache/run), resource requests/limits. UI dedicated SA with `automountServiceAccountToken: false`; Service stays `80→8080` via chart nginx ConfigMap. Control-plane NetworkPolicy enabled by default (tighten with `networkPolicy.allowedIngressNamespaces`). Residual: secrets still env-injected; API egress open for kube-apiserver — see follow-ups on [#42](https://github.com/virtfoundry/helm-charts/issues/42). Coordinates [core UI/API non-root images](https://github.com/virtfoundry/core).
- **Breaking:** `platform.networking.isolated.enabled` defaults to `false`. A default chart install no longer schedules the hostNetwork bridge DaemonSet. Opt in for Multus host bridges; privileges documented in [Host bridges](docs/guide/configuration.md#host-bridges-isolated--public) — closes [#40](https://github.com/virtfoundry/helm-charts/issues/40).
- Bridge DaemonSet: dedicated SA (`automountServiceAccountToken: false`), drop `hostPID`, replace `privileged: true` with `NET_ADMIN` (+ `NET_RAW` for DHCP), pin alpine by digest, empty default tolerations (respect control-plane NoSchedule). Residual: public DHCP still runs `apk add dnsmasq` at runtime until a prebuilt image exists ([#54](https://github.com/virtfoundry/helm-charts/issues/54)).
- **Breaking:** `ingress.enabled` defaults to `false`. Enabling Ingress requires `ingress.tls` (or `ingress.allowCleartext: true` for lab HTTP). Gateway example binds `sectionName: websecure`; HTTP→HTTPS redirect example at [httproute-https-redirect.yaml](docs/examples/httproute-https-redirect.yaml) — closes [#41](https://github.com/virtfoundry/helm-charts/issues/41). See [Ingress and TLS](docs/guide/configuration.md#ingress-and-tls).
- Expose `api.security.allowedOrigins` in chart values → ConfigMap `security.allowed_origins` for CORS / WS Origin allowlist ([core#98](https://github.com/virtfoundry/core/issues/98) / [PR #113](https://github.com/virtfoundry/core/pull/113)) — closes [#51](https://github.com/virtfoundry/helm-charts/issues/51). Same-origin UI proxy needs nothing; split UI/API must set the list.
- Document CDI importer egress NetworkPolicy (tenant NS, not chart release NS) aligned with [core#95](https://github.com/virtfoundry/core/issues/95) allowlist — closes [#49](https://github.com/virtfoundry/helm-charts/issues/49). Policy is created by core on tenant ensure; chart docs cover private-mirror extensions ([example](docs/examples/cdi-importer-egress-private-mirror.yaml)).

**Breaking (security).** The `virtfoundry` chart no longer ships default credentials. `secrets.rootPassword` (min 12 chars) and `secrets.jwtSecret` (min 32 chars) are required, the published sentinels `virtfoundry` / `change-me-in-production` are rejected, and `secrets.existingSecret` is supported for GitOps. An upgrade that omits the values reuses the ones already stored in the live Secret. See [Secrets](docs/guide/configuration.md#secrets) — [#37](https://github.com/virtfoundry/helm-charts/issues/37).

Security: platform hook Jobs no longer share a wildcard ClusterRole. Each Job gets a scoped ServiceAccount that is deleted when the hook phase succeeds. Upgrades must remove the old `virtfoundry-platform` ServiceAccount/ClusterRole/ClusterRoleBinding by hand — see [docs/project/changelog.md](docs/project/changelog.md).

## [0.7.1] - 2026-09-04

Charts `0.7.1`. Default images `0.7.1` (VM create hides platform Windows ISO until the tenant uploads one). Docs: chart default values page. Chart: storage class `auto` (Longhorn if present). Public CIDR can inherit Node InternalIP (`autoFromCluster`). Script `scripts/detect-host-public-net.sh`.

## [0.7.0] - 2026-09-02

First tagged CRD-store / operator chart line (no separate `v0.6.0` / chart `0.6.0` tag was ever published). Charts `0.7.0`. CRD store default; `virtfoundry-operator` chart shipped. MySQL/worker templates and `values-kubernetes.yaml` removed. New [Platform prerequisites](docs/guide/prerequisites.md) guide with KubeVirt, Multus, CDI, Longhorn, MetalLB, CSI snapshotter install links. Docs: install prerequisites, VM snapshot screenshots, simplified quick install.

## [0.5.0] - 2026-08-16

Pre-1.0 line. Premature `v1.x` / `virtfoundry-1.x` tags and the `v1.5.0` GitHub Release were deleted in the 2026-09-27 cleanup (already yanked from the Helm index). Default images `0.5.0`. Pin Helm `--version 0.5.0`. Absorbs features that had been published under the premature 1.x chart line (IAM/VPC/volumes/offerings/templates/dedicated CPU, etc.).

## [0.2.0] - 2026-08-02

Public network profile, bridge CNI NAD, MkDocs site, versioning rules, configurable gateway and IP pool.

## [0.1.0] - 2026-08-01

Initial Helm chart and GitHub Pages Helm repository.
