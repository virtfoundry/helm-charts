# Helm repository

The chart is published to **GitHub Pages** when a git tag `v*` is pushed.

## User install

```bash
helm repo add virtfoundry https://virtfoundry.github.io/helm-charts
helm repo update
helm search repo virtfoundry/virtfoundry --versions
```

**Prerequisites on the cluster:** KubeVirt, Multus, CDI (ISO/import), StorageClass, Ingress or Gateway API — see [Installation](installation.md#prerequisites-overview). Then install a specific chart version (operator first):

```bash
helm install virtfoundry-operator virtfoundry/virtfoundry-operator --version 0.7.0 \
  --namespace virtfoundry-system --create-namespace

helm install virtfoundry virtfoundry/virtfoundry --version 0.7.0 \
  --namespace virtfoundry-system \
  --set secrets.rootPassword='...' \
  --set secrets.jwtSecret='...'
```

Optional values overlays (Gateway API, public networking, image tags) can be passed with `-f` on `helm upgrade --install`.

## GitHub Pages layout

| Path | Content |
|------|---------|
| `https://virtfoundry.github.io/helm-charts/` | Helm `index.yaml` (`.tgz` packages are GitHub Release assets) |
| `https://virtfoundry.github.io/helm-charts/docs/` | MkDocs documentation (this site) |

Both live on the **`gh-pages`** branch: chart-releaser writes `index.yaml` at the root; the Docs workflow publishes MkDocs under `docs/`. Chart packages `1.x` were yanked from the index (git tags `v1.x` remain).

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
   git tag v0.7.0
   git push origin v0.7.0
   ```

5. Workflows publish Helm packages (`virtfoundry`, `virtfoundry-operator`) + rebuild docs

Verify:

```bash
curl -sL https://virtfoundry.github.io/helm-charts/index.yaml | head
```

See [Versioning](../project/versioning.md) for SemVer policy.
