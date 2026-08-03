# VirtFoundry

**VirtFoundry** is a multi-tenant IaaS control plane for Kubernetes. It wraps [KubeVirt](https://kubevirt.io/) for virtual machines, [Multus](https://github.com/k8snetworkplumbingwg/multus-cni) for L2/L3 networks, and Kubernetes NetworkPolicy for security groups — exposed through a REST API and React dashboard.

## Quick install

```bash
helm repo add virtfoundry https://virtfoundry.github.io/helm-charts
helm repo update
helm install virtfoundry virtfoundry/virtfoundry \
  --version 1.0.0 \
  --namespace virtfoundry-system \
  --create-namespace \
  --set secrets.rootPassword='your-root-password' \
  --set secrets.jwtSecret='your-jwt-secret'
```

Gateway API or Ingress profiles are configured via Helm values — see [Configuration](guide/configuration.md).

## Before you install

VirtFoundry requires **KubeVirt**, **Multus**, and **CDI** (for ISO/import paths) on the cluster — the Helm chart deploys the control plane only. See [Installation → Prerequisites](guide/installation.md#why-each-platform-component-is-needed).

## Architecture at a glance

| Layer | Technology |
|-------|------------|
| Control plane | Go API + async worker |
| Hypervisor | KubeVirt VirtualMachine |
| Networking | Multus NADs, host bridges, optional MetalLB |
| Security | IAM, JWT, API keys, tenant namespaces, NetworkPolicy |
| UI | React + Vite + TanStack Query |
| Packaging | Helm chart (`helm-charts`) |

## Repositories

| Repository | Role |
|------------|------|
| [core](https://github.com/virtfoundry/core) | Application source (API, worker, UI) |
| [helm-charts](https://github.com/virtfoundry/helm-charts) | Helm chart, deploy scripts, this documentation |

## Current release

**v1.0.0** — IAM (users, roles, API keys), multi-tenant IaaS on KubeVirt.

See [Changelog](project/changelog.md) and [Versioning](project/versioning.md).

## Support

- [GitHub Issues](https://github.com/virtfoundry/core/issues)
- [Contributing](https://github.com/virtfoundry/helm-charts/blob/main/CONTRIBUTING.md)
- [Governance](project/governance.md)
- [Sponsorship](project/sponsorship.md)

Documentation: **https://virtfoundry.github.io/helm-charts/docs/**
