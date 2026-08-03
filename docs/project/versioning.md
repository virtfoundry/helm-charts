# Versioning

VirtFoundry follows [Semantic Versioning 2.0.0](https://semver.org/) while in **0.x** (pre-1.0).

## Release units

| Artifact | Version source | Tag | Registry / URL |
|----------|----------------|-----|----------------|
| Application | Git tag | `vX.Y.Z` | `ghcr.io/virtfoundry/core`, `ui` |
| Helm chart | `Chart.yaml` `version` | `vX.Y.Z` (same) | `https://virtfoundry.github.io/helm-charts` |
| Documentation | Built from chart repo `main` / tags | — | `.../helm-charts/docs/` |

`Chart.yaml` **`appVersion`** matches the application release the chart defaults target.

## Bump rules (pre-1.0)

| Change | Version bump | Example |
|--------|--------------|---------|
| Bug fix, doc fix | PATCH | `0.2.0` → `0.2.1` |
| New feature, chart profile change | MINOR | `0.1.0` → `0.2.0` |
| Stable API commitment | MAJOR | `0.x` → `1.0.0` (future) |

Breaking changes before 1.0 may appear in MINOR releases — always read [Changelog](changelog.md).

## Release process

1. Finish feature branch → PR → integration testing → merge `main`
2. Update `CHANGELOG.md` (both repos)
3. Bump `Chart.yaml` + `values.yaml` image tags (chart repo)
4. Commit: `chore(release): v0.2.0`
5. Tag **both** repositories:

   ```bash
   git tag v0.2.0
   git push origin v0.2.0
   ```

6. CI publishes container images and Helm package; docs site rebuilds

## Consuming versions

```bash
# Helm
helm install virtfoundry virtfoundry/virtfoundry --version 0.2.0

# Container images
ghcr.io/virtfoundry/core:0.2.0
ghcr.io/virtfoundry/ui:0.2.0
```

Tags `0.2`, `latest` (on `main` builds) may also exist — pin explicitly in production.

## Cross-repo features

Use the **same branch name** in `virtfoundry` and `helm-charts`. Release with the **same version number** when both change.

Cursor rules: `.cursor/rules/versioning.mdc` in each repository.
