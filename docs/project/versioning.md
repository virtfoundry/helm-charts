# Versioning

VirtFoundry follows [Semantic Versioning 2.0.0](https://semver.org/).

## Pre-1.0

The project is **not 1.0 yet**. The current release line is **0.11.1**.

Premature product tags `v1.0.0`–`v1.5.0` and chart tags `virtfoundry-1.x` were cut too early and were **deleted** (2026-09-27) — they are **not** a SemVer 1.0 stability promise. Breaking changes may still land in **0.x MINOR** bumps until a real `1.0.0` is declared.

The Helm index must not list `1.x` packages; a bare `helm install` resolves **0.11.1**. Pin anyway and install the **CRDs first**, then the operator:

```bash
helm install virtfoundry-crds virtfoundry/virtfoundry-crds --version 0.11.1 \
  -n virtfoundry-system --create-namespace
helm install virtfoundry-operator virtfoundry/virtfoundry-operator --version 0.11.1 \
  -n virtfoundry-system
helm install virtfoundry virtfoundry/virtfoundry --version 0.11.1 \
  -n virtfoundry-system \
  --set secrets.rootPassword='...' \
  --set secrets.jwtSecret='...'
```

## Release units

| Artifact | Version source | Tag | Registry / URL |
|----------|----------------|-----|----------------|
| Application | Git tag | `vX.Y.Z` | `ghcr.io/virtfoundry/core`, `ui` |
| Helm chart | `Chart.yaml` `version` | `vX.Y.Z` (same) | `https://virtfoundry.github.io/helm-charts` |
| Operator | Git tag | `vX.Y.Z` | `ghcr.io/virtfoundry/operator` |
| VKS operator + chart `virtfoundry-vks` | Git tag (`Chart.yaml` matches) | `vX.Y.Z` | `ghcr.io/virtfoundry/vks`; chart from the `virtfoundry/vks` repo |
| Terraform provider | Git tag (own line) | `vX.Y.Z` | [Terraform Registry](https://registry.terraform.io/providers/virtfoundry/virtfoundry/latest) |
| VKS node image | Kubernetes version | `node-ubuntu-*` | `ghcr.io/virtfoundry/node-ubuntu:<k8s>@sha256:...` |
| Documentation | Built from chart repo `main` / tags | — | `.../helm-charts/docs/` |

`Chart.yaml` **`appVersion`** matches the application release the chart defaults target.

## Bump rules

| Change | Version bump | Example |
|--------|--------------|---------|
| Bug fix, doc fix, security patch (non-breaking) | PATCH | `0.11.1` → `0.11.2` |
| New feature, chart profile change | MINOR | `0.11.1` → `0.12.0` |
| Breaking API or chart contract | MINOR while on 0.x | `0.11.1` → `0.12.0` (document in CHANGELOG) |
| First stable contract | MAJOR | `0.x` → `1.0.0` (explicit declaration) |

## Release process

1. Finish feature branch → PR → integration testing → merge `main`
2. Update `CHANGELOG.md` (core, helm-charts, operator when touched)
3. **Bump every version pin** (same `X.Y.Z` everywhere — do not skip UI, values, **org landing**, or **GitHub Pages**):

   | Repo | Files |
   |------|-------|
   | **core** | `ui/package.json`, `ui/package-lock.json` (root + `"packages"` entry), `docs/PRODUCT.md` |
   | **helm-charts** | `charts/virtfoundry/Chart.yaml`, `charts/virtfoundry-operator/Chart.yaml`, `charts/virtfoundry/values.yaml` (`images.api` / `images.ui`), `charts/virtfoundry-operator/values.yaml` + `values-homelab.yaml` (`image.tag`), **all** install docs (`quickstart`, `installation`, `kind`, `helm-repository`, `chart-values`, `index`, `README`) — these feed **GitHub Pages** |
   | **vks** | `charts/virtfoundry-vks/Chart.yaml` (`version`, `appVersion`), `CHANGELOG.md` |
   | **terraform-provider** | `CHANGELOG.md`, `version = "~> X.Y"` in README and examples (own line, see below) |
   | **operator** | `charts/virtfoundry-operator/Chart.yaml`, `values.yaml`, `values-homelab.yaml` |
   | **`.github` (org profile)** | [`profile/README.md`](https://github.com/virtfoundry/.github/blob/main/profile/README.md) — org homepage “Current release” + helm `--version` snippets (**routinely forgotten**) |
   | **This doc** | `docs/project/versioning.md` — current release line and examples |

   The UI sidebar/login label reads **`ui/package.json` at build time** (`src/lib/version.ts`). A chart bump without rebuilding/publishing UI leaves users on an old label (e.g. `v0.5.0`).

   After merge to `helm-charts` `main`, confirm Pages shows the new badge/pins at https://virtfoundry.github.io/helm-charts/docs/ .

4. Commit: `chore(release): v0.11.1`
   **Go one repository at a time.** Each merge to `main` and each tag makes CI write a new image digest, so the cluster rolls that Deployment. Several rollouts at once can overload the node's CNI ([Troubleshooting](../guide/troubleshooting.md#pods-stay-in-containercreating-with-failedcreatepodsandbox)). After each merge and each tag, wait until the cluster has settled:

   ```bash
   scripts/ops/wait-settled.sh   # NS, TIMEOUT and MIN_QUIET are configurable
   ```

5. Tag **each** repository that changed:

   ```bash
   git tag v0.11.1
   git push origin v0.11.1
   ```

6. CI publishes container images and Helm package; docs site rebuilds; homelab digest write-back updates Argo overlay
7. **After the homelab syncs, refresh the docs screenshots** in a docs-only PR: `python scripts/docs/capture-ui-shots.py` writes `docs/assets/screenshots/` in the dark theme (set `VF_PASSWORD`, and `VF_USER` and `VF_UI_URL` if they differ; the script has no default password). Check that the login footer shows the new version and that no secrets are visible.

## Compatibility

| VirtFoundry | operator | vks | Terraform provider | Node image (K8s) |
|-------------|----------|-----|--------------------|------------------|
| 0.11.1 | 0.11.1 | 0.11.1 | 0.4.0 | `node-ubuntu:1.36.5` |
| 0.11.0 | 0.11.0 | 0.11.0 | 0.4.0 | `node-ubuntu:1.36.5` |
| 0.10.0 | 0.10.0 | 0.10.0 | 0.4.0 | `node-ubuntu:1.36.5` |
| 0.9.0 | 0.9.0 | — | 0.3.1 | — |

The Terraform provider keeps its own 0.x line. It needs a VirtFoundry release that has the API it calls: `virtfoundry_vks_cluster` needs 0.10.0 or newer. The VKS chart and image share the product version from 0.10.0 on (earlier it was an untagged `0.1.0`).

## Consuming versions

```bash
# Helm — pin 0.11.1; CRDs first, then the operator (see Installation guide)
helm install virtfoundry-crds virtfoundry/virtfoundry-crds --version 0.11.1 ...
helm install virtfoundry-operator virtfoundry/virtfoundry-operator --version 0.11.1 ...
helm install virtfoundry virtfoundry/virtfoundry --version 0.11.1 \
  --set secrets.rootPassword='...' --set secrets.jwtSecret='...' ...

# Container images
ghcr.io/virtfoundry/core:0.11.1
ghcr.io/virtfoundry/ui:0.11.1
ghcr.io/virtfoundry/operator:0.11.1
ghcr.io/virtfoundry/vks:0.11.1
```

Tags `latest` (on `main` builds) may also exist — pin explicitly in production.

## Cross-repo features

Use the **same branch name** in `virtfoundry` and `helm-charts`. Release with the **same version number** when both change.

## Future: umbrella chart

**0.10.x stays three charts and three Argo Applications.** A later **`virtfoundry-platform`** umbrella (Helm dependencies + nested `operator` / `core` / `vks` values) is design-only — see [Future platform umbrella chart](umbrella-chart.md).
