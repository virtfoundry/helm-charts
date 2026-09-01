# Governance

VirtFoundry is an open-source project under the [Apache License 2.0](https://www.apache.org/licenses/LICENSE-2.0), aligned with [CNCF](https://www.cncf.io/) open-source project practices.

## Maintainers

See [MAINTAINERS.md (core)](https://github.com/virtfoundry/core/blob/main/MAINTAINERS.md).

| Name | GitHub | Role |
|------|--------|------|
| Matheus Thurler | [@Matheus-Thurler](https://github.com/Matheus-Thurler) | Lead maintainer |
| Rodrigo Gonçalves | [@RodrigoGoncalves-dev](https://github.com/RodrigoGoncalves-dev) | Maintainer |

Matheus retains final merge authority and is the primary security contact. Rodrigo supports review, homelab validation, and operator/infra work.

## Official repositories

| Repository | Role |
|------------|------|
| [core](https://github.com/virtfoundry/core) | REST API, UI |
| [operator](https://github.com/virtfoundry/operator) | `virtfoundry.io` CRDs and operator |
| [helm-charts](https://github.com/virtfoundry/helm-charts) | Helm charts and documentation site |
| [terraform-provider-virtfoundry](https://github.com/virtfoundry/terraform-provider-virtfoundry) | Terraform provider |

Forks and downstream distributions are independent unless explicitly stated.

## What the license does *not* change

Apache 2.0 allows use, modification, and redistribution, including commercially. It does **not** transfer maintainership of the official GitHub organization or grant sponsors veto rights over technical decisions.

## Decision process

1. **Day-to-day** — PRs to `main`, maintainer review; cluster validation for infra-sensitive work.
2. **Releases** — SemVer tags; see [Versioning](versioning.md).
3. **Breaking or large changes** — GitHub Issues or Discussions when impact is broad.
4. **Contributions** — [CONTRIBUTING.md](https://github.com/virtfoundry/helm-charts/blob/main/CONTRIBUTING.md); no CLA today.

## Trademarks and sponsorship

See [Sponsorship](sponsorship.md). Code license and trademark use are separate.

## Contact

- [GitHub Issues](https://github.com/virtfoundry/core/issues)
- [GitHub Discussions](https://github.com/virtfoundry/core/discussions)
- Security: [SECURITY.md](https://github.com/virtfoundry/core/blob/main/SECURITY.md)
