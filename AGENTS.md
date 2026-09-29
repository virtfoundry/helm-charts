# AGENTS — virtfoundry/helm-charts

Charts `virtfoundry` (API+UI) e `virtfoundry-operator` (CRDs), docs site e overlays de homelab.

## Cursor Team Kit

Usar o plugin **cursor-team-kit**:

| Situação | Skill |
|----------|--------|
| Branch + PR | `new-branch-and-pr` / `review-and-ship` |
| CI | `fix-ci` + `loop-on-ci` |
| PR legível | `make-pr-easy-to-review` |
| Typecheck | `check-compiler-errors` |
| Limpar noise de AI | `deslop` |

Rules: `typescript-exhaustive-switch`, `no-inline-imports` quando houver TS.

## VirtFoundry

- SemVer produto **0.8.x** (Chart.yaml / CHANGELOG alinhados ao core/operator).
- Validar installs no **homelab** — nunca Kind como gate de produto.
- Overlay homelab: digests pinados (sem `:latest` flutuante).
- Preview sem commit só com pedido explícito.
- Não taguear / mergear release sem OK do maintainer.

## Docs locais

- [README.md](README.md)
- [docs/guide/](docs/guide/) — quickstart / install
- [docs/project/versioning.md](docs/project/versioning.md)
- [CHANGELOG.md](CHANGELOG.md)
