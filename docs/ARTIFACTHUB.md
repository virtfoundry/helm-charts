# Helm repo (GitHub Pages) and Artifact Hub

The chart is published to GitHub Pages on every git tag `v*`.

## User install

```bash
helm repo add virtforge https://virtforge-cloud.github.io/virtforge-chart
helm repo update
helm install virtforge virtforge/virtforge \
  --namespace virtforge-system \
  --create-namespace \
  --set secrets.rootPassword='your-root-password' \
  --set secrets.jwtSecret='your-jwt-secret'
```

Homelab profile:

```bash
helm upgrade --install virtforge virtforge/virtforge \
  -n virtforge-system --create-namespace \
  -f https://raw.githubusercontent.com/virtforge-cloud/virtforge-chart/main/charts/virtforge/values-homelab.yaml
```

## Maintainer: one-time GitHub Pages setup

1. Repo **Settings → Pages**
2. **Build and deployment → Source:** Deploy from a branch
3. **Branch:** `gh-pages` / `/ (root)`
4. Save (branch is created automatically by chart-releaser on first release)

## Maintainer: publish a release

1. Bump `version` in [`charts/virtforge/Chart.yaml`](../charts/virtforge/Chart.yaml)
2. Commit and push to `main`
3. Create and push a matching tag (chart version without `v` prefix in tag is standard: chart `0.1.0` → tag `v0.1.0`):

   ```bash
   git tag v0.1.0
   git push origin v0.1.0
   ```

4. Workflow [`.github/workflows/release.yaml`](../.github/workflows/release.yaml) packages the chart and updates `gh-pages`

Verify:

```bash
curl -sL https://virtforge-cloud.github.io/virtforge-chart/index.yaml | head
```

## Maintainer: Artifact Hub

1. Open https://artifacthub.io/control-panel/repositories/add
2. **Kind:** Helm charts
3. **URL:** `https://virtforge-cloud.github.io/virtforge-chart`
4. After registration, copy **Repository ID** into [`artifacthub-repo.yml`](../artifacthub-repo.yml):

   ```yaml
   repositoryID: <uuid-from-artifact-hub>
   owners:
     - name: virtforge-cloud
       email: virtforge-cloud@users.noreply.github.com
   ```

5. Commit and push — Artifact Hub picks up metadata from the repo
