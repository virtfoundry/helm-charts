# Helm repository

The chart is published to **GitHub Pages** when a git tag `v*` is pushed.

## User install

```bash
helm repo add virtfoundry https://virtfoundry.github.io/virtfoundry-chart
helm repo update
helm search repo virtfoundry/virtfoundry --versions
```

Install a specific version:

```bash
helm install virtfoundry virtfoundry/virtfoundry --version 0.2.0 \
  --namespace virtfoundry-system --create-namespace \
  --set secrets.rootPassword='...' \
  --set secrets.jwtSecret='...'
```

Optional values overlays (Gateway API, public networking, image tags) can be passed with `-f` on `helm upgrade --install`.

## GitHub Pages layout

| Path | Content |
|------|---------|
| `https://virtfoundry.github.io/virtfoundry-chart/` | Helm `index.yaml` + `.tgz` packages |
| `https://virtfoundry.github.io/virtfoundry-chart/docs/` | MkDocs documentation (this site) |

## Maintainer: publish a release

1. Bump `version` and `appVersion` in `charts/virtfoundry/Chart.yaml`
2. Update `CHANGELOG.md` and default image tags in `values.yaml`
3. Merge to `main`
4. Tag both **virtfoundry** and **virtfoundry-chart**:

   ```bash
   git tag v0.2.0
   git push origin v0.2.0
   ```

5. Workflows publish Helm package + rebuild docs

Verify:

```bash
curl -sL https://virtfoundry.github.io/virtfoundry-chart/index.yaml | head
```

See [Versioning](../project/versioning.md) for SemVer policy.
