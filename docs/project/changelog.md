# Changelog

All notable changes to the **Helm chart and deploy tooling** are documented here.

Format based on [Keep a Changelog](https://keepachangelog.com/). Versioning: [SemVer](versioning.md).

## [0.2.0] - 2026-08-02

### Added

- Homelab public network profile: bridge CNI NAD, IP pool gateway `10.0.50.1`, dnsmasq bridge address
- `platform.networking.public.bridge.address` and `routePoolViaBridge` for CloudStack coexistence
- `allowPodNetwork: true` default for VM pod + public dual-homed networking
- MkDocs documentation site published to GitHub Pages `/docs/`
- Cursor rules: `versioning.mdc`, `homelab-networking.mdc`

### Changed

- Platform bridge DaemonSet: optional bridge IP + VM pool host routes via `virtforge-pub0`
- Default container images bumped to `0.2.0`
- Homelab DNS guidance: gateway MetalLB IP instead of worker Node IP

### Fixed

- Public VM networking: bridge Multus without host-local IPAM (guest IP via cloud-init pool)
- Documented MikroTik gateway alias and inter-VLAN requirements for SSH from WiFi clients

## [0.1.0] - 2026-08-01

### Added

- Initial Helm chart: API, worker, UI, MySQL
- Gateway API and Ingress profiles
- Platform networking values (`platform.networking.public`, isolated bridge)
- GitHub Pages Helm repository via chart-releaser
- Homelab deploy script and setup helpers (KubeVirt, Multus, CDI)

[0.2.0]: https://github.com/virtforge-cloud/virtforge-chart/compare/v0.1.0...v0.2.0
[0.1.0]: https://github.com/virtforge-cloud/virtforge-chart/releases/tag/v0.1.0
