# Security groups

Security groups are tenant-scoped firewall policies rendered as Kubernetes **NetworkPolicy** objects (plus VirtFoundry metadata).

## Defaults

On tenant bootstrap, VirtFoundry creates default security groups so new environments are not wide open by accident. Admins can add groups and rules for application traffic.

## UI

**Network → Security groups** (`/security-groups`)

1. Create a group (name, description, optional VPC link)
2. Edit **rules** (direction, protocol, ports, CIDR / peer)
3. Attach usage through VM / network workflows as supported by the UI

## API

| Method | Path |
|--------|------|
| GET | `/api/v1/security-groups` |
| POST | `/api/v1/security-groups` |
| PATCH | `/api/v1/security-groups/{id}` |
| DELETE | `/api/v1/security-groups/{id}` |

Permission: `security_groups:read` / `security_groups:write`.

## Mental model

```text
Security group (tenant DB)
        │
        ▼
NetworkPolicy in tenant namespace
        │
        ▼
Pod / VM traffic selection (KubeVirt + Multus)
```

Exact selectors depend on how VMs are labeled and which networks they join. Prefer least privilege: open only the ports you need from known CIDRs.

## Related

- [VPCs & networks](networking.md)
- [Auth & IAM](iam.md) — who can edit groups
