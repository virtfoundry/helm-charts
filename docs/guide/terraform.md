# Terraform provider

The official provider manages tenants, networking, compute, storage, IAM and VKS clusters through the REST API (`/api/v1`).

- Registry: [`virtfoundry/virtfoundry`](https://registry.terraform.io/providers/virtfoundry/virtfoundry/latest)
- Source and per-resource reference: [terraform-provider-virtfoundry](https://github.com/virtfoundry/terraform-provider-virtfoundry)

## Install

```hcl
terraform {
  required_version = ">= 1.11"

  required_providers {
    virtfoundry = {
      source  = "virtfoundry/virtfoundry"
      version = "~> 0.3"
    }
  }
}

provider "virtfoundry" {
  endpoint  = "https://virtfoundry.example.com"
  api_key   = var.virtfoundry_api_key
  tenant_id = var.tenant_id
}
```

Terraform 1.11 or newer gives write-only attributes for secrets. Older versions (1.0+) work with reduced protection.

## Authentication

| Argument | Env var | Use |
|----------|---------|-----|
| `api_key` (`vfd_live_...`) | `VIRTFOUNDRY_API_KEY` | CI/CD (recommended) |
| `username` / `password` | `VIRTFOUNDRY_USERNAME` / `VIRTFOUNDRY_PASSWORD` | Development (JWT login) |
| `endpoint` | `VIRTFOUNDRY_ENDPOINT` | API URL (required) |
| `tenant_id` | `VIRTFOUNDRY_TENANT_ID` | Default tenant |
| `insecure` | `VIRTFOUNDRY_INSECURE` | Skip TLS verification, development only |

## Deploy a VM

```hcl
resource "virtfoundry_security_group" "ssh" {
  name   = "allow-ssh"
  vpc_id = var.vpc_id

  rule {
    direction = "ingress"
    protocol  = "tcp"
    port_from = 22
    port_to   = 22
    cidr      = "10.0.0.0/8" # never default to 0.0.0.0/0 in shared environments
  }
}

resource "virtfoundry_vm" "web" {
  name                = "web-01"
  template_id         = var.template_id
  service_offering_id = "small"
  public_ip           = true
  security_group_ids  = [virtfoundry_security_group.ssh.id]
  desired_state       = "running"
}
```

## VKS clusters

```hcl
resource "virtfoundry_vks_cluster" "dev" {
  name               = "dev"
  kubernetes_version = "v1.36.5" # must match a published node image

  workers = {
    count        = 2
    template_ref = "ubuntu-node-1-36-5"
    offering_ref = "medium"
    network_ref  = "default"
  }
}

data "virtfoundry_vks_kubeconfig" "dev" {
  name = virtfoundry_vks_cluster.dev.name
}
```

Changing any cluster argument **replaces** the cluster. The kubeconfig is sensitive but still lands in state, so enable state encryption. See [Kubernetes clusters](features/vks.md).

## Resources

| Area | Resources |
|------|-----------|
| Tenancy and IAM | `tenant`, `user`, `role`, `api_key` |
| Network | `vpc`, `network`, `security_group` |
| Compute | `vm`, `vm_template`, `vm_snapshot`, `ssh_key` |
| Storage | `volume`, `volume_snapshot` |
| Kubernetes | `vks_cluster` (+ data source `vks_kubeconfig`) |
| Ephemeral (TF 1.10+) | `api_key`, `ssh_key` — secret never stored in state |

Data sources: `service_offerings`, `vm_templates`, `vpcs`, `networks`, `security_groups`, `ssh_keys`, `users`, `roles`.
