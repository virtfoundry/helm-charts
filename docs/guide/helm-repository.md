# Helm repository

The chart is published to **GitHub Pages** when a git tag `v*` is pushed.

## User install

```bash
helm repo add virtforge https://virtforge-cloud.github.io/virtforge-chart
helm repo update
helm search repo virtforge/virtforge --versions
```

Install a specific version:

```bash
helm install virtforge virtforge/virtforge --version 0.2.0 \
  --namespace virtforge-system --create-namespace \
  --set secrets.rootPassword='...' \
  --set secrets.jwtSecret='...'
```

Homelab values overlay:

```bash
helm upgrade --install virtforge virtforge/virtforge \
  -n virtforge-system --create-namespace \
  -f https://raw.githubusercontent.com/virtforge-cloud/virtforge-chart/main/charts/virtforge/values-homelab.yaml
```

## GitHub Pages layout

| Path | Content |
|------|---------|
| `https://virtforge-cloud.github.io/virtforge-chart/` | Helm `index.yaml` + `.tgz` packages |
| `https://virtforge-cloud.github.io/virtforge-chart/docs/` | MkDocs documentation (this site) |

## Maintainer: publish a release

1. Bump `version` and `appVersion` in `charts/virtforge/Chart.yaml`
2. Update `CHANGELOG.md` and default image tags in `values.yaml`
3. Merge to `main`
4. Tag both **virtforge** and **virtforge-chart**:

   ```bash
   git tag v0.2.0
   git push origin v0.2.0
   ```

5. Workflows publish Helm package + rebuild docs

Verify:

```bash
curl -sL https://virtforge-cloud.github.io/virtforge-chart/index.yaml | head
```

See [Versioning](../project/versioning.md) for SemVer policy.
