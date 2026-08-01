# Contributing

Thank you for improving VirtForge Cloud packaging.

## Commits

- Language: **English**
- Format: [Conventional Commits](https://www.conventionalcommits.org/)

## Validate changes

```bash
make lint
```

Or manually:

```bash
helm template virtforge ./charts/virtforge
helm template virtforge ./charts/virtforge -f ./charts/virtforge/values-homelab.yaml
```

CI runs the same checks on pull requests (`.github/workflows/chart-lint.yaml`).

## Branch workflow

**Do not commit directly to `main`.** Every feature or fix uses its own branch:

1. Branch from `main`: `feat/<name>`, `fix/<name>`, or `chore/<name>`
2. Run `make lint` and deploy with `make deploy-homelab` on **homelab**
3. Open PR → maintainer validates on homelab → **merge only after approval**
4. After merge to `main`, tag `v*` to publish the chart to GitHub Pages

## Documentation

- Update [README.md](README.md) when layout or Makefile targets change
- Update [scripts/README.md](scripts/README.md) when adding or moving scripts
- Update the [Wiki](https://github.com/virtforge-cloud/virtforge-chart/wiki) for extended install guides

## Repositories

| Repo | Scope |
|------|-------|
| [virtforge](https://github.com/virtforge-cloud/virtforge) | API, worker, UI, Dockerfiles, CI images |
| [virtforge-chart](https://github.com/virtforge-cloud/virtforge-chart) | Helm chart, deploy/setup scripts |
| [virtforge-website](https://github.com/virtforge-cloud/virtforge-website) | Docs site and marketing |

## Adding scripts

- Place under `scripts/setup/`, `scripts/deploy/`, or `scripts/sideload/`
- Source `scripts/lib/common.sh` for paths and kubeconfig
- Add a Makefile target and document in `scripts/README.md`
- Do **not** add shell scripts to the repo root
