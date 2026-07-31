# Contributing

- Commits: English, [Conventional Commits](https://www.conventionalcommits.org/)
- Documentation: English; update the [Wiki](https://github.com/virtforge-cloud/virtforge-chart/wiki) when install steps change
- Validate Helm chart: `helm template virtforge ./charts/virtforge`
- Validate homelab overlay: `kubectl kustomize kustomize/overlays/homelab`

## Repositories

| Repo | Scope |
|------|-------|
| [virtforge](https://github.com/virtforge-cloud/virtforge) | API, worker, UI, Dockerfiles |
| [virtforge-chart](https://github.com/virtforge-cloud/virtforge-chart) | Helm chart, Kustomize, homelab scripts |
| [virtforge-website](https://github.com/virtforge-cloud/virtforge-website) | Docs site and marketing pages |
