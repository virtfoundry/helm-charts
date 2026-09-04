# Versioning

VirtFoundry follows [Semantic Versioning 2.0.0](https://semver.org/).

## Pre-1.0

The project is **not 1.0 yet**. The current release line is **0.7.1**.

Git tags `v1.0.0`–`v1.5.0` were cut too early. They remain in git/GHCR for history; they are **not** a SemVer 1.0 stability promise. Breaking changes may still land in **0.x MINOR** bumps until 1.0 is declared.

Helm chart packages `1.x` were **yanked** from the repository index so a bare `helm install` resolves **0.7.1**. Pin anyway and install **operator first**:

```bash
helm install virtfoundry-operator virtfoundry/virtfoundry-operator --version 0.7.1 \
  -n virtfoundry-system --create-namespace
helm install virtfoundry virtfoundry/virtfoundry --version 0.7.1 \
  -n virtfoundry-system \
  --set secrets.rootPassword='...' \
  --set secrets.jwtSecret='...'
```

## Release units

| Artifact | Version source | Tag | Registry / URL |
|----------|----------------|-----|----------------|
| Application | Git tag | `vX.Y.Z` | `ghcr.io/virtfoundry/core`, `ui` |
| Helm chart | `Chart.yaml` `version` | `vX.Y.Z` (same) | `https://virtfoundry.github.io/helm-charts` |
| Documentation | Built from chart repo `main` / tags | — | `.../helm-charts/docs/` |

`Chart.yaml` **`appVersion`** matches the application release the chart defaults target.

## Bump rules

| Change | Version bump | Example |
|--------|--------------|---------|
| Bug fix, doc fix | PATCH | `0.7.1` → `0.7.2` |
| New feature, chart profile change | MINOR | `0.7.1` → `0.8.0` |
| Breaking API or chart contract | MINOR while on 0.x | `0.7.1` → `0.8.0` (document in CHANGELOG) |
| First stable contract | MAJOR | `0.x` → `1.0.0` (explicit declaration) |

## Release process

1. Finish feature branch → PR → integration testing → merge `main`
2. Update `CHANGELOG.md` (core, helm-charts, operator when touched)
3. **Bump every version pin** (same `X.Y.Z` everywhere — do not skip UI or values):

   | Repo | Files |
   |------|-------|
   | **core** | `ui/package.json`, `ui/package-lock.json` (root + `"packages"` entry), `docs/PRODUCT.md` |
   | **helm-charts** | `charts/virtfoundry/Chart.yaml`, `charts/virtfoundry-operator/Chart.yaml`, `charts/virtfoundry/values.yaml` (`images.api` / `images.ui`), `charts/virtfoundry-operator/values.yaml` + `values-homelab.yaml` (`image.tag`), install docs (`quickstart`, `installation`, `kind`, `helm-repository`, `index`, `README`) |
   | **operator** | `charts/virtfoundry-operator/Chart.yaml`, `values.yaml`, `values-homelab.yaml` |
   | **This doc** | `docs/project/versioning.md` — current release line and examples |

   The UI sidebar/login label reads **`ui/package.json` at build time** (`src/lib/version.ts`). A chart bump without rebuilding/publishing UI leaves users on an old label (e.g. `v0.5.0`).

4. Commit: `chore(release): v0.7.1`
5. Tag **each** repository that changed:

   ```bash
   git tag v0.7.1
   git push origin v0.7.1
   ```

6. CI publishes container images and Helm package; docs site rebuilds; homelab digest write-back updates Argo overlay

## Consuming versions

```bash
# Helm — pin 0.7.1; install operator first (see Installation guide)
helm install virtfoundry-operator virtfoundry/virtfoundry-operator --version 0.7.1 ...
helm install virtfoundry virtfoundry/virtfoundry --version 0.7.1 \
  --set secrets.rootPassword='...' --set secrets.jwtSecret='...' ...

# Container images
ghcr.io/virtfoundry/core:0.7.1
ghcr.io/virtfoundry/ui:0.7.1
ghcr.io/virtfoundry/operator:0.7.1
```

Tags `latest` (on `main` builds) may also exist — pin explicitly in production.

## Cross-repo features

Use the **same branch name** in `virtfoundry` and `helm-charts`. Release with the **same version number** when both change.
