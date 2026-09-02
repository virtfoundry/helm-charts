# Versioning

VirtFoundry follows [Semantic Versioning 2.0.0](https://semver.org/).

## Pre-1.0

The project is **not 1.0 yet**. The current release line is **0.6.0**.

Git tags `v1.0.0`–`v1.5.0` were cut too early. They remain in git/GHCR for history; they are **not** a SemVer 1.0 stability promise. Breaking changes may still land in **0.x MINOR** bumps until 1.0 is declared.

Helm chart packages `1.x` were **yanked** from the repository index so a bare `helm install` resolves **0.6.0**. Pin anyway and install **operator first**:

```bash
helm install virtfoundry-operator virtfoundry/virtfoundry-operator --version 0.6.0 \
  -n virtfoundry-system --create-namespace
helm install virtfoundry virtfoundry/virtfoundry --version 0.6.0 \
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
| Bug fix, doc fix | PATCH | `0.5.0` → `0.5.1` |
| New feature, chart profile change | MINOR | `0.5.0` → `0.6.0` |
| Breaking API or chart contract | MINOR while on 0.x | `0.5.0` → `0.6.0` (document in CHANGELOG) |
| First stable contract | MAJOR | `0.x` → `1.0.0` (explicit declaration) |

## Release process

1. Finish feature branch → PR → integration testing → merge `main`
2. Update `CHANGELOG.md` (both repos)
3. Bump `Chart.yaml` + `values.yaml` image tags (chart repo) and `ui/package.json` (core)
4. Commit: `chore(release): v0.6.0`
5. Tag **both** repositories:

   ```bash
   git tag v0.6.0
   git push origin v0.6.0
   ```

6. CI publishes container images and Helm package; docs site rebuilds

## Consuming versions

```bash
# Helm — pin 0.6.0; install operator first (see Installation guide)
helm install virtfoundry-operator virtfoundry/virtfoundry-operator --version 0.6.0 ...
helm install virtfoundry virtfoundry/virtfoundry --version 0.6.0 \
  --set secrets.rootPassword='...' --set secrets.jwtSecret='...' ...

# Container images
ghcr.io/virtfoundry/core:0.6.0
ghcr.io/virtfoundry/ui:0.6.0
ghcr.io/virtfoundry/operator:0.6.0
```

Tags `latest` (on `main` builds) may also exist — pin explicitly in production.

## Cross-repo features

Use the **same branch name** in `virtfoundry` and `helm-charts`. Release with the **same version number** when both change.
