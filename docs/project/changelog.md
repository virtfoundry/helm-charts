# Changelog

All notable changes to the **Helm chart and deploy tooling** are documented here.

Format based on [Keep a Changelog](https://keepachangelog.com/). Versioning: [SemVer](versioning.md).

## [Unreleased]

### Fixed

- The UI nginx sent `Host` without the port, so WebSocket upgrades (`/ws/events`, `/ws/console`) were rejected with 403 when the UI was served on a non-default port, such as the quickstart's `kubectl port-forward 8080:80`. It now keeps the port (`$http_host`); `scripts/ci/assert-ui-nginx-host.sh` guards it ([Troubleshooting](../guide/troubleshooting.md)).
- The UI and API pods now roll when their ConfigMaps change (checksum annotations). Before, `helm upgrade` changed the ConfigMap and left the pod running with the old file, because the nginx config is mounted with `subPath`.
- Quickstart: the health check URL is `/api/v1/healthz` (needs 0.11.3 or newer; `/health` on the UI address only returned the UI page), and the first-VM steps now say to create an SSH key first.
- `scripts/e2e/homelab-ui.py` works on a fresh install (creates a throwaway SSH key) and fails on WebSocket errors in the browser console.

## [0.11.3] - 2026-10-07

### Changed

- Chart / image pins aligned with core/operator/vks **0.11.3** (core: VKS accepts the network display name, `/api/v1/healthz`).
- `virtfoundry-vks` sample and VKS guide use the Network CR name (`default-default`) in `networkRef`.

## [0.11.2] - 2026-10-07

### Added

- `scripts/e2e/homelab-ui.py`: UI end-to-end on a live install (wizard deploy, post-deploy panel, Open VM, cleanup). It found that Copy ssh did nothing over plain HTTP (fixed in core 0.11.2).
- `scripts/ops/wait-settled.sh`: waits until pods, Deployments and (when installed) Argo CD Applications are ready, quiet for a minimum time. The release process now says to release one repository at a time and run it in between ([Versioning](versioning.md)).

### Changed

- `scripts/setup/multus.sh` pins the Multus image to the immutable `v4.3.1-thick` digest instead of the moving `snapshot-thick` tag (override with `MULTUS_IMAGE`). [Troubleshooting](../guide/troubleshooting.md) explains how to pin an existing install.
- Chart / image pins aligned with core/operator/vks **0.11.2** (core: honest login page and Copy ssh over HTTP).

### Security

- `scripts/deploy/homelab.sh` no longer prints a fixed login and `scripts/docs/capture-ui-shots.py` reads the password from `VF_PASSWORD` instead of embedding one. The old value is in the Git history, so treat it as exposed and rotate it on any install that used it.

## [0.11.1] - 2026-10-07

### Added

- **Chart e2e** workflow: fresh install, umbrella install and the CRD migration from the 0.10.x operator chart on a Kind cluster (`scripts/ci/e2e-charts.sh`).
- Troubleshooting: the `helm install virtfoundry` post-install timeout without KubeVirt, and pods stuck in `ContainerCreating` from Multus throttling ([Troubleshooting](../guide/troubleshooting.md)).

### Changed

- UI screenshots refreshed for 0.11.0; dependency updates (GitHub Actions, mkdocs-material).
- Chart / image pins aligned with core/operator/vks **0.11.1**.

## [0.11.0] - 2026-10-07

### Added

- `charts/virtfoundry-crds`: the 16 `virtfoundry.io` CRDs in one chart, upgraded by `helm upgrade` and protected from `helm uninstall` and Argo CD prune. `make verify-crds-chart` gate. See [CRDs and upgrades](../guide/crds.md).
- `charts/virtfoundry-platform`: umbrella chart for the operator, core and optional VKS in one release. Kamaji is not a dependency. `make verify-platform-parity` gate.
- Docs: Kubernetes clusters (VKS), Terraform provider, Troubleshooting, CRDs and upgrades, split Networking/Storage configuration, copy-paste install; refreshed UI screenshots; mermaid, glightbox, breadcrumbs and cards.

### Changed

- **Breaking:** the `virtfoundry-operator` chart (mirror of virtfoundry/operator) and the VKS chart no longer ship CRDs. **Install `virtfoundry-crds` first**, then the operator. Existing installs adopt their CRDs once: see [CRDs and upgrades](../guide/crds.md).
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

- Control-plane NetworkPolicy DNS egress allows NodeLocalDNS (port 53 without CoreDNS-only selectors) so the UI can resolve `virtfoundry-api` on Kubespray clusters.

## [0.7.2] - 2026-09-25

Security release aligning charts with core/operator 0.7.2 (PSS hardening, networking/Ingress defaults, secrets fail-closed).

### Security

- Harden API/UI Deployments (closes [#42](https://github.com/virtfoundry/helm-charts/issues/42)): non-root + drop ALL + RuntimeDefault seccomp + readOnlyRootFilesystem, requests/limits, UI SA without token automount, Service `80→8080` via nginx ConfigMap. Default NetworkPolicy for control plane (`networkPolicy.enabled`); set `allowedIngressNamespaces` to restrict. Residuals: env-injected secrets; API egress open — follow-ups on the issue. Core images: UI listens on 8080 / API UID 65532.
- **Breaking:** `platform.networking.isolated.enabled` defaults to `false` so a default install is API+UI-only (no hostNetwork bridge DaemonSet). Enabling isolated or public opts into host bridges with documented caps — closes [#40](https://github.com/virtfoundry/helm-charts/issues/40). See [Host bridges](../guide/networking-config.md#host-bridges-isolated-public). Kind / homelab overlays that need Multus L2 must set `isolated.enabled: true` (and usually `bridge.tolerations: [{operator: Exists}]`).
- Bridge DaemonSet hardening: dedicated SA without token automount, no `hostPID`, `NET_ADMIN` / `NET_RAW` instead of `privileged: true`, alpine pinned by digest. Residual: DHCP container still `apk add dnsmasq` at runtime ([#54](https://github.com/virtfoundry/helm-charts/issues/54)).
- **Breaking:** `ingress.enabled` defaults to `false` (no cleartext HTTP control plane). Enabling Ingress requires `ingress.tls` or `ingress.allowCleartext: true`. Gateway profile uses `sectionName: websecure`; HTTP→HTTPS redirect example at [httproute-https-redirect.yaml](../examples/httproute-https-redirect.yaml) — closes [#41](https://github.com/virtfoundry/helm-charts/issues/41). See [Ingress and TLS](../guide/configuration.md#ingress-and-tls).
- `api.security.allowedOrigins` → ConfigMap `security.allowed_origins` (CORS / `/ws/*` Origin allowlist) — closes [#51](https://github.com/virtfoundry/helm-charts/issues/51), residual from [core#98](https://github.com/virtfoundry/core/issues/98) / [PR #113](https://github.com/virtfoundry/core/pull/113). Default `[]` is correct for same-origin UI proxy; split UI/API must list UI origins. See [Allowed origins](../guide/configuration.md#allowed-origins-cors-websockets).
- Document CDI importer egress NetworkPolicy in each **tenant** namespace (created by core `EnsureTenantNamespace`; not a release-NS chart object) — closes [#49](https://github.com/virtfoundry/helm-charts/issues/49), follow-up to [core#95](https://github.com/virtfoundry/core/issues/95). See [Images and templates](../guide/features/templates.md#cdi-importer-egress) and [example private-mirror policy](../examples/cdi-importer-egress-private-mirror.yaml).

- **Breaking:** the `virtfoundry` chart ships no credential defaults. `secrets.rootPassword` (min 12 chars) and `secrets.jwtSecret` (min 32 chars) are required, and the published sentinels `virtfoundry` / `change-me-in-production` are refused — install and `helm template` fail closed instead ([#37](https://github.com/virtfoundry/helm-charts/issues/37), [core#93](https://github.com/virtfoundry/core/issues/93))
- Platform hook RBAC no longer grants `apiGroups: ["*"] / resources: ["*"]`. Each hook Job has its own ServiceAccount: `-platform-kubevirt` (get/patch on `kubevirt/kubevirt` only), `-platform-multus` and `-platform-cdi` (rendered only with `platform.multus.install` / `platform.cdi.install`)
- Hook RBAC carries `helm.sh/hook-delete-policy: before-hook-creation,hook-succeeded`, so no platform identity outlives the install/upgrade

Upgrading from `0.7.1` or older leaves the previous wildcard objects behind — Helm never owned them. Remove them once:

```bash
kubectl delete clusterrolebinding virtfoundry-platform --ignore-not-found
kubectl delete clusterrole virtfoundry-platform --ignore-not-found
kubectl -n virtfoundry-system delete serviceaccount virtfoundry-platform --ignore-not-found
```

### Added

- `secrets.existingSecret` (with `secrets.rootPasswordKey` / `secrets.jwtSecretKey`) — bring your own Secret; recommended for Argo CD and other GitOps flows
- `secrets.autoGenerateJwtSecret` — random 48-char JWT secret on first install, preserved across upgrades via `lookup`
- `secrets.allowInsecureDefaults` — local-development escape hatch that also sets `VF_ALLOW_INSECURE_DEFAULTS=1` on the API

### Changed

- `helm upgrade` without `--set secrets.*` reuses the credentials already stored in the live Secret, so upgrades no longer reset the root password or invalidate issued tokens
- Documented in [Configuration — Secrets](../guide/configuration.md#secrets)

## [0.7.1] - 2026-09-04

### Added

- [Chart values](../guide/chart-values.md) — full default `values.yaml` on the docs site, why `--set` belongs on the Helm command
- `platform.storage.defaultClass: auto` — select Longhorn when the StorageClass exists
- `platform.networking.public.autoFromCluster` — fill CIDR/gateway/pool from Node InternalIP when you do not `--set` them
- `scripts/detect-host-public-net.sh` — print a public-net values snippet from kubectl/host

### Changed

- Charts and default `appVersion` `0.7.1` (core UI hides platform Windows ISO from VM create until the tenant uploads one)

## [0.7.0] - 2026-09-02

First tagged CRD-store / operator chart line (no separate `v0.6.0` / chart `0.6.0` tag was ever published).

### Added

- `virtfoundry-operator` Helm chart with bundled `virtfoundry.io/v1alpha1` CRDs
- `store.driver=kubernetes` profile documented as default install path
- [Platform prerequisites](../guide/prerequisites.md) — install links for KubeVirt, Multus, CDI, Longhorn, MetalLB, CSI snapshotter

### Changed

- **Breaking (0.x):** removed MySQL StatefulSet, worker Deployment, and `values-kubernetes.yaml` overlay
- Charts and default `appVersion` `0.7.0`
- Default images `ghcr.io/virtfoundry/{core,ui,operator}:0.7.0`
- Install docs list KubeVirt, Multus, CDI prerequisites before Helm commands
- Homepage and quickstart point to prerequisites guide
- VM snapshot UI screenshots and CRD store terminal shot refresh

### Removed

- Legacy MySQL store templates and worker chart resources

## [0.5.0] - 2026-08-16

Pre-1.0 release line. VirtFoundry is **not 1.0** yet. Premature `v1.0.0`–`v1.5.0` / `virtfoundry-1.x` tags and releases were **deleted** (2026-09-27); they are not a stability contract and must not appear in the Helm index.

### Changed

- Chart `version` / `appVersion` and default images set to `0.5.0`
- Docs and install snippets pin `--version 0.5.0`

### Docs

- Kind laptop guide (no VLAN); public-network underlay without a switch

### Absorbed (from deleted premature 1.x chart line)

- IAM release, default VPC, volumes, offerings, templates/ISO, dedicated CPU, Features docs, volume-delete 409, UI polish — previously published as chart/app `1.0.0`–`1.5.0`

## [0.2.0] - 2026-08-02

### Added

- Public network profile: bridge CNI NAD, configurable IP pool and gateway, optional dnsmasq bridge address
- `platform.networking.public.bridge.address` and `routePoolViaBridge` for host route steering when multiple bridges share a CIDR
- `allowPodNetwork: true` default for VM pod + public dual-homed networking
- MkDocs documentation site published to GitHub Pages `/docs/`

### Changed

- Platform bridge DaemonSet: optional bridge IP + VM pool host routes via the public bridge
- Default container images bumped to `0.2.0`

### Fixed

- Public VM networking: bridge Multus without host-local IPAM (guest IP via cloud-init pool)

## [0.1.0] - 2026-08-01

### Added

- Initial Helm chart: API, worker, UI, MySQL
- Gateway API and Ingress profiles
- Platform networking values (`platform.networking.public`, isolated bridge)
- GitHub Pages Helm repository via chart-releaser
- Deploy scripts and setup helpers (KubeVirt, Multus, CDI)

[0.7.3]: https://github.com/virtfoundry/helm-charts/compare/v0.7.2...v0.7.3
[0.7.2]: https://github.com/virtfoundry/helm-charts/compare/v0.7.1...v0.7.2
[0.7.1]: https://github.com/virtfoundry/helm-charts/compare/v0.7.0...v0.7.1
[0.7.0]: https://github.com/virtfoundry/helm-charts/compare/v0.5.0...v0.7.0
[0.5.0]: https://github.com/virtfoundry/helm-charts/compare/v0.2.0...v0.5.0
[0.2.0]: https://github.com/virtfoundry/helm-charts/compare/v0.1.0...v0.2.0
[0.1.0]: https://github.com/virtfoundry/helm-charts/releases/tag/v0.1.0
