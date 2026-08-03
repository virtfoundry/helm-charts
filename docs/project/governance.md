# Governance

VirtFoundry is an open-source project under the [Apache License 2.0](https://www.apache.org/licenses/LICENSE-2.0). This page describes who leads the project and how decisions are made.

## Maintainer

**VirtFoundry** is maintained by the [virtfoundry](https://github.com/virtfoundry) GitHub organization.

| Role | Responsibility |
|------|----------------|
| **Maintainer / BDFL** | Final say on merges, releases, roadmap, and org settings |
| **Contributors** | Propose changes via pull requests; no automatic governance rights |

The official repositories are:

- [virtfoundry](https://github.com/virtfoundry/core) — application (API, worker, UI)
- [helm-charts](https://github.com/virtfoundry/helm-charts) — Helm chart, deploy tooling, documentation site

Forks and downstream distributions are independent; they are not the official project unless explicitly stated.

## What the license does *not* change

Apache 2.0 allows anyone to use, modify, and redistribute the code, including commercially. It does **not**:

- transfer maintainership of the official GitHub organization
- grant sponsors or users a veto over technical decisions
- prevent the maintainer from choosing what merges into `main`

## Decision process

1. **Day-to-day changes** — pull requests to `main`, reviewed by the maintainer; integration testing for infra-sensitive work.
2. **Releases** — SemVer tags (`vX.Y.Z`) on aligned app + chart versions; see [Versioning](versioning.md).
3. **Breaking or large changes** — discussed in GitHub Issues or Discussions before implementation when impact is broad.
4. **Contributions** — welcome under [CONTRIBUTING.md](https://github.com/virtfoundry/helm-charts/blob/main/CONTRIBUTING.md); merged at maintainer discretion.

## Contributions and copyright

Contributions are licensed under the same Apache 2.0 license as the project. Contributors retain their copyright; they grant the project (and users) the rights defined in Apache 2.0.

There is **no CLA** today. If dual-licensing or enterprise offerings are introduced later, contribution terms may be updated with notice.

## Trademarks and branding

The name **VirtFoundry**, logos, and official documentation URLs represent the project brand. Use of the brand for commercial products or implied endorsement should be coordinated with the maintainer.

Code license (Apache 2.0) and trademark use are separate topics.

## Sponsorship vs. control

Financial sponsors support development; they do **not** acquire ownership of the codebase or merge rights unless covered by a **separate written agreement**. See [Sponsorship](sponsorship.md).

## Contact

- [GitHub Issues](https://github.com/virtfoundry/core/issues) — bugs and features
- [GitHub Discussions](https://github.com/virtfoundry/core/discussions) — questions and ideas (when enabled)

For security reports, follow [SECURITY.md](https://github.com/virtfoundry/core/blob/main/SECURITY.md).
