# Website / front door

## Canonical URL (today)

**https://virtfoundry.github.io/helm-charts/docs/**

This MkDocs site on GitHub Pages is the **official public front door** for VirtFoundry: positioning, Quickstart, installation, topologies, and project docs.

| URL | Role |
|-----|------|
| https://virtfoundry.github.io/helm-charts/docs/ | **Docs + marketing landing** (canonical) |
| https://virtfoundry.github.io/helm-charts/ | Helm chart repository (`index.yaml`) — not the human landing page |
| https://github.com/virtfoundry/core | Source of truth for the application |
| https://github.com/orgs/virtfoundry/projects/1 | Traction project board |

## Decision

- **Do not wait** on a custom domain to have a single front door.
- Point READMEs, social posts, and talks at the Pages docs URL (Quickstart / Why).
- Optional later: `virtfoundry.dev` (or similar) as a CNAME → same GitHub Pages site. When that happens, update `mkdocs.yml` `site_url` and this page; keep old Pages URLs working via redirect if possible.

## Landing content

The docs home page leads with:

1. **Quickstart** — under-30-minute path  
2. **Why VirtFoundry** — vs Proxmox / KubeVirt  
3. Installation / topologies for deeper setup  

See [index.md](../index.md), [quickstart.md](../guide/quickstart.md), and [Why VirtFoundry](../guide/why.md).
