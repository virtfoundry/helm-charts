# Concepts and tenancy

VirtFoundry isolates every customer (or lab project) as a **tenant**. Resources are scoped to that tenant unless you are the platform **root**.

## Tenant

| Field | Meaning |
|-------|---------|
| Name | Display name |
| Slug | DNS-safe id; drives namespace and admin username |
| Namespace | Kubernetes namespace `virtfoundry-tenant-{slug}` |
| State | e.g. `active` |

On create, VirtFoundry:

1. Ensures the tenant namespace (quota, labels)
2. Creates the tenant admin user **`{slug}-admin`** with the password you set
3. Bootstraps a **default VPC** and default security groups for that tenant

!!! tip "Login username"
    Use **`{slug}-admin`**, not the display name. Example: tenant name `Acme`, slug `acme` → login `acme-admin`.

## Root vs tenant user

| Actor | Scope | UI |
|-------|-------|-----|
| **root** | All tenants | Sees **Tenants**, **Offerings**; tenant switcher in the shell |
| **Tenant user** | Single `tenant_id` | IAM / compute / network for that tenant only |

Root impersonates a tenant with the UI switcher or the HTTP header **`X-Tenant-ID: <tenant-uuid>`** on API calls.

## Default tenant

A **`default`** tenant is ensured at startup for day-1 demos.

!!! warning "Protected"
    The `default` tenant **cannot be deleted** (UI hides trash; API returns 403).

## Create and delete tenants (root)

**UI:** Platform → **Tenants** (`/tenants`)

1. **Create** — name, slug, admin password; after create, copy the admin username from the success dialog
2. **Delete** — trash icon on non-default tenants; confirms, then deletes the K8s namespace and purges tenant data

**API (root JWT):**

```bash
# List
curl -H "Authorization: Bearer $TOKEN" https://iaas.example/api/v1/tenants

# Create
curl -X POST -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"name":"Acme","slug":"acme","admin_password":"…"}' \
  https://iaas.example/api/v1/tenants

# Delete
curl -X DELETE -H "Authorization: Bearer $TOKEN" \
  https://iaas.example/api/v1/tenants/$TENANT_ID
```

## Related

- [Auth & IAM](iam.md) — users and roles inside a tenant
- [API quick reference](api.md) — `X-Tenant-ID`
