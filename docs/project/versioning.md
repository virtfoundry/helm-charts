# Versioning

VirtFoundry follows [Semantic Versioning 2.0.0](https://semver.org/).

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
| Bug fix, doc fix | PATCH | `1.1.0` → `1.1.1` |
| New feature, chart profile change | MINOR | `1.0.0` → `1.1.0` |
| Breaking API or chart contract | MAJOR | `1.x` → `2.0.0` |

Breaking changes in MINOR releases before 1.0 were allowed — from **1.0.0** onward, follow standard SemVer.

## Release process

1. Finish feature branch → PR → integration testing → merge `main`
2. Update `CHANGELOG.md` (both repos)
3. Bump `Chart.yaml` + `values.yaml` image tags (chart repo)
4. Commit: `chore(release): v1.1.0`
5. Tag **both** repositories:

   ```bash
   git tag v1.1.0
   git push origin v1.1.0
   ```

6. CI publishes container images and Helm package; docs site rebuilds

## Consuming versions

```bash
# Helm
helm install virtfoundry virtfoundry/virtfoundry --version 1.1.0

# Container images
ghcr.io/virtfoundry/core:1.1.0
ghcr.io/virtfoundry/ui:1.1.0
```

Tags `0.2`, `latest` (on `main` builds) may also exist — pin explicitly in production.

## Cross-repo features

Use the **same branch name** in `virtfoundry` and `helm-charts`. Release with the **same version number** when both change.

Cursor rules: `.cursor/rules/versioning.mdc` in each repository.
