---
hide:
  - navigation
  - toc
title: Home
---

<div class="vf-hero" markdown="1">

<span class="vf-badge">Release v1.3.0</span>

# VirtFoundry

<p class="vf-lead">
Kubernetes-native IaaS control plane — virtual machines with KubeVirt,
multi-tenant networking with Multus, and security groups with NetworkPolicy.
One REST API, one dashboard, one Helm chart.
</p>

[Get started :material-rocket-launch:](guide/installation.md){ .md-button .md-button--primary }
[View on GitHub :material-github:](https://github.com/virtfoundry/core){ .md-button }
[Changelog :material-history:](project/changelog.md){ .md-button }

</div>

<div class="vf-grid" markdown="1">

<div class="vf-card" markdown="1">

<span class="vf-icon">:material-server:</span>

### Control plane
Go API + async worker orchestrate tenants, compute, storage, and network resources.

</div>

<div class="vf-card" markdown="1">

<span class="vf-icon">:material-monitor:</span>

### KubeVirt VMs
Deploy, start, stop, snapshot, and console into VirtualMachines from the UI or API.

</div>

<div class="vf-card" markdown="1">

<span class="vf-icon">:material-lan:</span>

### Multus networking
VPCs, isolated L2 networks, public IP pools, and default VPC per tenant.

</div>

<div class="vf-card" markdown="1">

<span class="vf-icon">:material-shield-lock:</span>

### IAM & isolation
JWT login, API keys, roles, tenant namespaces, and Kubernetes NetworkPolicy.

</div>

</div>

## Quick install

```bash
helm repo add virtfoundry https://virtfoundry.github.io/helm-charts
helm repo update
helm install virtfoundry virtfoundry/virtfoundry \
  --version 1.3.0 \
  --namespace virtfoundry-system \
  --create-namespace \
  --set secrets.rootPassword='your-root-password' \
  --set secrets.jwtSecret='your-jwt-secret'
```

Gateway API or Ingress profiles are configured via Helm values — see [Configuration](guide/configuration.md).

## Before you install

VirtFoundry requires **KubeVirt**, **Multus**, and **CDI** (for ISO/import paths) on the cluster — the Helm chart deploys the control plane only. See [Installation → Prerequisites](guide/installation.md#why-each-platform-component-is-needed).

## Architecture

| Layer | Technology |
|-------|------------|
| Control plane | Go API + async worker |
| Hypervisor | KubeVirt VirtualMachine |
| Networking | Multus NADs, host bridges, optional MetalLB |
| Security | IAM, JWT, API keys, tenant namespaces, NetworkPolicy |
| UI | React + Vite + Redux + TanStack Query |
| Packaging | Helm chart (`helm-charts`) |

## Repositories

| Repository | Role |
|------------|------|
| [core](https://github.com/virtfoundry/core) | Application source (API, worker, UI) |
| [helm-charts](https://github.com/virtfoundry/helm-charts) | Helm chart, deploy scripts, this documentation |

<div class="vf-links" markdown="1">

[Installation guide](guide/installation.md)
[Helm repository](guide/helm-repository.md)
[Versioning policy](project/versioning.md)
[Contributing](https://github.com/virtfoundry/helm-charts/blob/main/CONTRIBUTING.md)
[GitHub Issues](https://github.com/virtfoundry/core/issues)

</div>

## Support

- [Governance](project/governance.md)
- [Sponsorship](project/sponsorship.md)
