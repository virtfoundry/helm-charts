# Contributing

Thank you for improving VirtFoundry packaging.

## Commits

- Language: **English**
- Format: [Conventional Commits](https://www.conventionalcommits.org/)

## Validate changes

```bash
make lint
```

Or manually:

```bash
helm template virtfoundry ./charts/virtfoundry
```

CI runs the same checks on pull requests (`.github/workflows/chart-lint.yaml`).

## Branch workflow

**Do not commit directly to `main`.** Every feature or fix uses its own branch:

1. Branch from `main`: `feat/<name>`, `fix/<name>`, or `chore/<name>`
2. Run `make lint` and validate on a test cluster before opening a PR
3. Open PR → maintainer validates → **merge only after approval**
4. After merge to `main`, tag `v*` to publish the chart to GitHub Pages

## Documentation

- Update [README.md](README.md) when layout or Makefile targets change
- Update [scripts/README.md](scripts/README.md) when adding or moving scripts
- Update the [docs site](https://virtfoundry.github.io/helm-charts/docs/) (`docs/` + `mkdocs.yml`) for user-facing guides
- Update the [Wiki](https://github.com/virtfoundry/helm-charts/wiki) for extended install guides

## Repositories

| Repo | Scope |
|------|-------|
| [virtfoundry](https://github.com/virtfoundry/core) | API, worker, UI, Dockerfiles, CI images |
| [helm-charts](https://github.com/virtfoundry/helm-charts) | Helm chart, deploy/setup scripts |
| [virtfoundry-website](https://github.com/virtfoundry/core-website) | Docs site and marketing |

## Adding scripts

- Place under `scripts/setup/`, `scripts/deploy/`, or `scripts/sideload/`
- Source `scripts/lib/common.sh` for paths and kubeconfig
- Add a Makefile target and document in `scripts/README.md`
- Do **not** add shell scripts to the repo root
