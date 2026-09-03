# Changelog

All notable changes to the **Helm chart and deploy tooling** are documented here.

Format based on [Keep a Changelog](https://keepachangelog.com/). Versioning: [SemVer](versioning.md).

## [Unreleased]

### Added

- [Chart values](../guide/chart-values.md) — full default `values.yaml` on the docs site, why `--set` belongs on the Helm command
- `platform.storage.defaultClass: auto` — select Longhorn when the StorageClass exists
- `platform.networking.public.autoFromCluster` — fill CIDR/gateway/pool from Node InternalIP when you do not `--set` them
- `scripts/detect-host-public-net.sh` — print a public-net values snippet from kubectl/host

## [0.7.0] - 2026-09-02

### Added

- [Platform prerequisites](../guide/prerequisites.md) — install links for KubeVirt, Multus, CDI, Longhorn, MetalLB, CSI snapshotter

### Changed

- Charts and default `appVersion` `0.7.0`
- Homepage and quickstart point to prerequisites guide

## [0.6.0] - 2026-09-01

### Added

- `virtfoundry-operator` Helm chart (`0.6.0`) with bundled `virtfoundry.io/v1alpha1` CRDs
- `store.driver=kubernetes` profile documented as default install path

### Changed

- **Breaking (0.x):** removed MySQL StatefulSet, worker Deployment, and `values-kubernetes.yaml` overlay
- Default images `ghcr.io/virtfoundry/{core,ui,operator}:0.6.0`
- Install docs list KubeVirt, Multus, CDI prerequisites before Helm commands
- VM snapshot UI screenshots and CRD store terminal shot refresh

### Removed

- Legacy MySQL store templates and worker chart resources

## [0.5.0] - 2026-08-16

Pre-1.0 release line. VirtFoundry is **not 1.0** yet; `v1.0.0`–`v1.5.0` tags were premature and are not a stability contract.

### Changed

- Chart `version` / `appVersion` and default images set to `0.5.0`
- Docs and install snippets pin `--version 0.5.0`

### Docs

- Kind laptop guide (no VLAN); public-network underlay without a switch

## [1.5.0] - 2026-08-11

### Changed

- Default container images bumped to `1.5.0` (API, worker, UI)

### Added

- `appVersion` aligned with [core v1.5.0](https://github.com/virtfoundry/core/releases/tag/v1.5.0): root delete-tenant, dedicated CPU offerings, Features docs, IFNAMSIZ-safe public bridge default, CI attestation fix

### Docs

- Features guide under `docs/guide/features/` (published on GitHub Pages)

## [1.4.1] - 2026-08-05

### Changed

- Default container images bumped to `1.4.1` (API, worker, UI)

### Fixed

- `appVersion` aligned with [core v1.4.1](https://github.com/virtfoundry/core/releases/tag/v1.4.1): volume delete while attached returns 409 Conflict; UI version label synced with release

No chart template or values schema changes — upgrade by bumping the chart version or overriding image tags.

## [1.4.0] - 2026-08-05

### Changed

- Default container images bumped to `1.4.0` (API, worker, UI)

### Added

- `appVersion` aligned with [core v1.4.0](https://github.com/virtfoundry/core/releases/tag/v1.4.0): template seed dedup, ISO import polling UI, `docs/VM-TEMPLATES.md`

No chart template or values schema changes — upgrade by bumping the chart version or overriding image tags.

## [1.3.0] - 2026-08-05

### Changed

- Default container images bumped to `1.3.0` (API, worker, UI)

### Added

- `appVersion` aligned with [core v1.3.0](https://github.com/virtfoundry/core/releases/tag/v1.3.0): service offerings CRUD API, `/offerings` admin UI, `service_offering_id` persist on VM resize

No chart template or values schema changes — upgrade by bumping the chart version or overriding image tags.

## [1.2.0] - 2026-08-05

### Changed

- Default container images bumped to `1.2.0` (API, worker, UI)

### Added

- `appVersion` aligned with [core v1.2.0](https://github.com/virtfoundry/core/releases/tag/v1.2.0): volume attach/detach API, VM Detail Storage tab, volume delete guard, `defaultClass` wiring for tenant PVCs

No chart template or values schema changes — upgrade by bumping the chart version or overriding image tags.

## [1.1.1] - 2026-08-04

### Changed

- Default container images bumped to `1.1.1` (API, worker, UI)

### Fixed

- `appVersion` aligned with [core v1.1.1](https://github.com/virtfoundry/core/releases/tag/v1.1.1): VM create pod NIC naming fix, login page layout and theme support, optimized logo PNGs

No chart template or values schema changes — upgrade by bumping the chart version or overriding image tags.

## [1.1.0] - 2026-08-04

### Added

- Default container images bumped to `1.1.0` (API, worker, UI)
- Chart icon updated to application favicon

### Changed

- `appVersion` aligned with [core v1.1.0](https://github.com/virtfoundry/core/releases/tag/v1.1.0): default VPC (`10.0.0.0/16`) per tenant, self-service API keys, UI accordion navigation and header menus, Redux client state, dashboard and favicon updates

No chart template or values schema changes — upgrade by bumping the chart version or overriding image tags.

## [1.0.0] - 2026-08-03

### Added

- IAM release: users, roles, API keys, permission middleware
- Default container images `1.0.0`

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

[0.6.0]: https://github.com/virtfoundry/helm-charts/compare/v0.5.0...v0.6.0
[0.5.0]: https://github.com/virtfoundry/helm-charts/compare/v1.5.0...v0.5.0
[1.5.0]: https://github.com/virtfoundry/helm-charts/compare/v1.4.1...v1.5.0
[1.4.1]: https://github.com/virtfoundry/helm-charts/compare/v1.4.0...v1.4.1
[1.4.0]: https://github.com/virtfoundry/helm-charts/compare/v1.3.0...v1.4.0
[1.3.0]: https://github.com/virtfoundry/helm-charts/compare/v1.2.0...v1.3.0
[1.2.0]: https://github.com/virtfoundry/helm-charts/compare/v1.1.1...v1.2.0
[1.1.1]: https://github.com/virtfoundry/helm-charts/compare/v1.1.0...v1.1.1
[1.1.0]: https://github.com/virtfoundry/helm-charts/compare/v1.0.0...v1.1.0
[1.0.0]: https://github.com/virtfoundry/helm-charts/compare/v0.2.0...v1.0.0
[0.2.0]: https://github.com/virtfoundry/helm-charts/compare/v0.1.0...v0.2.0
[0.1.0]: https://github.com/virtfoundry/helm-charts/releases/tag/v0.1.0
