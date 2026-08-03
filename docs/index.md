# VirtForge Cloud

**VirtForge Cloud** is a multi-tenant IaaS control plane for Kubernetes. It wraps [KubeVirt](https://kubevirt.io/) for virtual machines, [Multus](https://github.com/k8snetworkplumbingwg/multus-cni) for L2/L3 networks, and Kubernetes NetworkPolicy for security groups — exposed through a REST API and React dashboard.

## Quick install

```bash
helm repo add virtforge https://virtforge-cloud.github.io/virtforge-chart
helm repo update
helm install virtforge virtforge/virtforge \
  --namespace virtforge-system \
  --create-namespace \
  --set secrets.rootPassword='your-root-password' \
  --set secrets.jwtSecret='your-jwt-secret'
```

Gateway API or Ingress profiles are configured via Helm values — see [Configuration](guide/configuration.md).

## Architecture at a glance

| Layer | Technology |
|-------|------------|
| Control plane | Go API + async worker |
| Hypervisor | KubeVirt VirtualMachine |
| Networking | Multus NADs, host bridges, optional MetalLB |
| Security | JWT auth, tenant namespaces, NetworkPolicy SGs |
| UI | React + Vite + TanStack Query |
| Packaging | Helm chart (`virtforge-chart`) |

## Repositories

| Repository | Role |
|------------|------|
| [virtforge](https://github.com/virtforge-cloud/virtforge) | Application source (API, worker, UI) |
| [virtforge-chart](https://github.com/virtforge-cloud/virtforge-chart) | Helm chart, deploy scripts, this documentation |
| [virtforge-website](https://github.com/virtforge-cloud/virtforge-website) | Marketing site (future) |

## Current release

**v0.2.0** — VM templates, public network with IP pool, ISO/CDI bootstrap paths.

See [Changelog](project/changelog.md) and [Versioning](project/versioning.md).

## Support

- [GitHub Issues](https://github.com/virtforge-cloud/virtforge/issues)
- [Contributing](https://github.com/virtforge-cloud/virtforge-chart/blob/main/CONTRIBUTING.md)
- [Governance](project/governance.md) — maintainer role and decision process
- [Sponsorship](project/sponsorship.md) — support the project without buying the code

Documentation is published on **GitHub Pages** (temporary site until [virtforge-website](https://github.com/virtforge-cloud/virtforge-website) is ready).
