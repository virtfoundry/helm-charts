# Auth and IAM

VirtFoundry authorizes every API call with **permissions**, not a single coarse role string. Humans use short-lived **JWT**s; automation uses long-lived **API keys**.

## Login

| Method | Path | Notes |
|--------|------|-------|
| POST | `/api/v1/auth/login` | Body: `username`, `password` → `{ token }` |
| GET | `/api/v1/auth/me` | Current user (JWT or API key) |

UI: `/login`. Bootstrap **root** password comes from Helm `secrets.rootPassword`. Tenant admins are `{slug}-admin` — see [Concepts](concepts.md).

## Built-in roles

| Role | Permissions | Who |
|------|-------------|-----|
| **platform.root** | `*` | Bootstrap `root` |
| **tenant.admin** | All tenant perms except `tenants:*` | `{slug}-admin` on create |
| **tenant.operator** | Compute, network, storage, SSH (no user admin) | Ops |
| **tenant.viewer** | Read-only (`*:read`) | Auditors |

Tenant admins can create **custom roles** with a permission list.

## Permission strings

| Permission | Typical use |
|------------|-------------|
| `tenants:read` / `tenants:write` | Root tenant list/create/delete |
| `users:read` / `users:write` | Users, roles, API keys |
| `vpcs:read` / `vpcs:write` | VPCs + CIDR plan |
| `networks:read` / `networks:write` | Private networks |
| `security_groups:read` / `security_groups:write` | Security groups |
| `volumes:read` / `volumes:write` | Volumes + volume snapshots |
| `vms:read` / `vms:write` | VMs, templates, VM snapshots |
| `vms:console` | noVNC console |
| `ssh_keys:read` / `ssh_keys:write` | SSH key pairs |

Middleware maps HTTP method + path to `resource:read` or `resource:write` automatically.

## Users and roles (UI)

**Platform → IAM** (`/iam`)

1. **Users** — create with username, password, role
2. **Roles** — list system + custom; edit permissions on custom roles
3. Root: set the tenant context with the shell switcher first

## API keys

Format: `vfd_live_<prefix>_<secret>` — the full secret is shown **once** on create.

| Method | Path | Notes |
|--------|------|-------|
| GET | `/api/v1/api-keys` | Own keys (admins see tenant keys) |
| POST | `/api/v1/api-keys` | Optional `scopes[]` ⊆ user permissions |
| DELETE | `/api/v1/api-keys/{id}` | Revoke |

Use as `Authorization: Bearer vfd_live_…` (same as JWT).

!!! tip "Terraform / CI"
    Prefer API keys over sharing the root password. Keys are revocable and can be scoped.

## Related

- [Concepts](concepts.md) — tenancy and root impersonation
- [API quick reference](api.md)
