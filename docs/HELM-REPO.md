# Helm repository (GitHub Pages)

The chart is published to GitHub Pages on every git tag `v*`.

## User install

```bash
helm repo add virtfoundry https://virtfoundry.github.io/helm-charts
helm repo update
helm install virtfoundry virtfoundry/virtfoundry \
  --namespace virtfoundry-system \
  --create-namespace \
  --set secrets.rootPassword='your-root-password' \
  --set secrets.jwtSecret='your-jwt-secret'
```

Use `-f` with a values overlay for Gateway API, public networking, or custom image tags when needed.

## Maintainer: GitHub Pages setup

1. Repo **Settings → Pages**
2. **Build and deployment → Source:** Deploy from a branch
3. **Branch:** `gh-pages` / `/ (root)`

The `gh-pages` branch is created automatically by chart-releaser on first release.

## Maintainer: publish a release

1. Bump `version` in [`charts/virtfoundry/Chart.yaml`](../charts/virtfoundry/Chart.yaml)
2. Commit and push to `main`
3. Create and push a matching tag (`0.1.0` → `v0.1.0`):

   ```bash
   git tag v0.1.1
   git push origin v0.1.1
   ```

4. Workflow [`.github/workflows/release.yaml`](../.github/workflows/release.yaml) packages the chart and updates `gh-pages`

Verify:

```bash
curl -sL https://virtfoundry.github.io/helm-charts/index.yaml | head
helm repo add virtfoundry https://virtfoundry.github.io/helm-charts
helm search repo virtfoundry/virtfoundry
```
