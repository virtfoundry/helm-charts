# Helm repository

The chart is published to **GitHub Pages** when a git tag `v*` is pushed.

## User install

```bash
helm repo add virtfoundry https://virtfoundry.github.io/helm-charts
helm repo update
helm search repo virtfoundry/virtfoundry --versions
```

Install a specific version:

```bash
helm install virtfoundry virtfoundry/virtfoundry --version 1.4.1 \
  --namespace virtfoundry-system --create-namespace \
  --set secrets.rootPassword='...' \
  --set secrets.jwtSecret='...'
```

Optional values overlays (Gateway API, public networking, image tags) can be passed with `-f` on `helm upgrade --install`.

## GitHub Pages layout

| Path | Content |
|------|---------|
| `https://virtfoundry.github.io/helm-charts/` | Helm `index.yaml` + `.tgz` packages |
| `https://virtfoundry.github.io/helm-charts/docs/` | MkDocs documentation (this site) |

Both live on the **`gh-pages`** branch: chart-releaser writes packages at the root; the Docs workflow publishes MkDocs under `docs/`.

!!! warning "One-time setup: enable Pages"
    If `/docs/` returns **404** but CI succeeded, GitHub Pages is probably disabled. Enable it once in the repo:

    **Settings → Pages → Build and deployment → Source:** Deploy from a branch → **`gh-pages`** / **`/ (root)`**

    Or via CLI (repo admin):

    ```bash
    gh api repos/virtfoundry/helm-charts/pages -X POST --input - <<'EOF'
    {
      "build_type": "legacy",
      "source": { "branch": "gh-pages", "path": "/" }
    }
    EOF
    ```

    First deploy can take 1–2 minutes after enabling.

## Maintainer: publish a release

1. Bump `version` and `appVersion` in `charts/virtfoundry/Chart.yaml`
2. Update `CHANGELOG.md` and default image tags in `values.yaml`
3. Merge to `main`
4. Tag both **virtfoundry** and **helm-charts**:

   ```bash
   git tag v1.1.0
   git push origin v1.1.0
   ```

5. Workflows publish Helm package + rebuild docs

Verify:

```bash
curl -sL https://virtfoundry.github.io/helm-charts/index.yaml | head
```

See [Versioning](../project/versioning.md) for SemVer policy.
