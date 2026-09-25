# Changelog

See [docs/project/changelog.md](docs/project/changelog.md) for the full release history (published on GitHub Pages).

## [Unreleased]

### Security

- Expose `api.security.allowedOrigins` in chart values → ConfigMap `security.allowed_origins` for CORS / WS Origin allowlist ([core#98](https://github.com/virtfoundry/core/issues/98) / [PR #113](https://github.com/virtfoundry/core/pull/113)) — closes [#51](https://github.com/virtfoundry/helm-charts/issues/51). Same-origin UI proxy needs nothing; split UI/API must set the list.
- Document CDI importer egress NetworkPolicy (tenant NS, not chart release NS) aligned with [core#95](https://github.com/virtfoundry/core/issues/95) allowlist — closes [#49](https://github.com/virtfoundry/helm-charts/issues/49). Policy is created by core on tenant ensure; chart docs cover private-mirror extensions ([example](docs/examples/cdi-importer-egress-private-mirror.yaml)).

**Breaking (security).** The `virtfoundry` chart no longer ships default credentials. `secrets.rootPassword` (min 12 chars) and `secrets.jwtSecret` (min 32 chars) are required, the published sentinels `virtfoundry` / `change-me-in-production` are rejected, and `secrets.existingSecret` is supported for GitOps. An upgrade that omits the values reuses the ones already stored in the live Secret. See [Secrets](docs/guide/configuration.md#secrets) — [#37](https://github.com/virtfoundry/helm-charts/issues/37).

Security: platform hook Jobs no longer share a wildcard ClusterRole. Each Job gets a scoped ServiceAccount that is deleted when the hook phase succeeds. Upgrades must remove the old `virtfoundry-platform` ServiceAccount/ClusterRole/ClusterRoleBinding by hand — see [docs/project/changelog.md](docs/project/changelog.md).

## [0.7.1] - 2026-09-04

Charts `0.7.1`. Default images `0.7.1` (VM create hides platform Windows ISO until the tenant uploads one). Docs: chart default values page. Chart: storage class `auto` (Longhorn if present). Public CIDR can inherit Node InternalIP (`autoFromCluster`). Script `scripts/detect-host-public-net.sh`.

## [0.7.0] - 2026-09-02

Charts `0.7.0`. New [Platform prerequisites](docs/guide/prerequisites.md) guide with KubeVirt, Multus, CDI, Longhorn, MetalLB, CSI snapshotter install links. Docs version bump; no MySQL references.

## [0.6.0] - 2026-09-01

CRD store default. Operator chart at `0.6.0`. MySQL/worker templates and `values-kubernetes.yaml` removed. Docs: install prerequisites, VM snapshot screenshots, simplified quick install.

## [0.5.0] - 2026-08-16

Pre-1.0 line. Same product as the former `1.5.0` tag plus Kind docs. Tags `v1.x` stay in git; they are not a 1.0 contract. Default images `0.5.0`. Pin Helm `--version 0.5.0`.

## [1.5.0] - 2026-08-11

Root delete-tenant, dedicated CPU, Features docs, IFNAMSIZ-safe bridge default. Default images `1.5.0`.

## [1.4.1] - 2026-08-05

Volume delete 409 fix and UI version label. Default images `1.4.1`.

## [1.4.0] - 2026-08-05

Template catalog dedup, ISO import polling, VM-TEMPLATES guide. Default images `1.4.0`.

## [1.3.0] - 2026-08-05

Service offerings CRUD, admin UI, VM resize persist. Default images `1.3.0`.

## [1.2.0] - 2026-08-05

Volume attach/detach, storage UI, defaultClass wiring. Default images `1.2.0`.

## [1.1.1] - 2026-08-04

VM pod network fix, login page redesign, optimized logo assets. Default images `1.1.1`.

## [1.1.0] - 2026-08-04

Default VPC per tenant, UI polish (accordion nav, header menus, Redux), self-service API keys, default images `1.1.0`.

## [0.2.0] - 2026-08-02

Public network profile, bridge CNI NAD, MkDocs site, versioning rules, configurable gateway and IP pool.

## [0.1.0] - 2026-08-01

Initial Helm chart and GitHub Pages Helm repository.
