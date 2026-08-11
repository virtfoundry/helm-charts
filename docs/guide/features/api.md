# API quick reference

Base path: **`/api/v1`**. Health: `GET /health` (outside `/api/v1`).

## Authentication

| Mechanism | Header |
|-----------|--------|
| Login JWT | `Authorization: Bearer <token>` from `POST /auth/login` |
| API key | `Authorization: Bearer vfd_live_…` |

Root (or multi-tenant tools) set tenant context with:

```http
X-Tenant-ID: <tenant-uuid>
```

See [Auth & IAM](iam.md) and [Concepts](concepts.md).

## WebSockets

| Path | Purpose |
|------|---------|
| `/ws/events` | Realtime UI events |
| `/ws/console` | noVNC / VNC proxy |

## Routes (current)

### Auth & shell

| Methods | Path |
|---------|------|
| POST | `/auth/login` |
| GET | `/auth/me` |
| GET | `/dashboard/summary`, `/search`, `/notifications` |

### IAM

| Methods | Path |
|---------|------|
| GET, POST | `/users` |
| PATCH, DELETE | `/users/{id}` |
| GET, POST | `/roles` |
| PATCH, DELETE | `/roles/{id}` |
| GET, POST | `/api-keys` |
| DELETE | `/api-keys/{id}` |

### Tenants & offerings (root write)

| Methods | Path | Notes |
|---------|------|-------|
| GET, POST | `/tenants` | root |
| DELETE | `/tenants/{id}` | root; not `default` |
| GET | `/service-offerings` | all users |
| POST, PATCH, DELETE | `/service-offerings`, `/service-offerings/{id}` | root |

### Catalog & compute

| Methods | Path |
|---------|------|
| GET, POST | `/vm-templates` |
| PATCH, DELETE | `/vm-templates/{id}` |
| GET, POST | `/vms` |
| GET, PATCH | `/vms/{name}` |
| GET | `/vms/{name}/logs` |
| GET, POST | `/vms/{name}/volumes` |
| DELETE | `/vms/{name}/volumes/{volume_id}` |
| POST | `/vms/start`, `/vms/stop`, `/vms/delete` |
| GET, POST | `/ssh-keys` |
| POST | `/ssh-keys/register` |
| DELETE | `/ssh-keys/{id}` |
| GET, POST | `/vms/{name}/ssh` |

### Storage

| Methods | Path |
|---------|------|
| GET, POST | `/volumes` |
| DELETE | `/volumes/{id}` |
| GET, POST | `/snapshots` |
| GET, POST | `/vm-snapshots` |
| POST | `/vm-snapshots/delete`, `/vm-snapshots/restore` |

### Network

| Methods | Path |
|---------|------|
| GET, POST | `/vpcs` |
| GET | `/vpcs/cidr-plan` |
| PATCH, DELETE | `/vpcs/{id}` |
| GET, POST | `/networks` |
| GET | `/networks/cidr-plan` |
| PATCH, DELETE | `/networks/{id}` |
| GET, POST | `/security-groups` |
| PATCH, DELETE | `/security-groups/{id}` |

## Example session

```bash
TOKEN=$(curl -sS -X POST https://iaas.example/api/v1/auth/login \
  -H 'Content-Type: application/json' \
  -d '{"username":"root","password":"…"}' | jq -r .token)

curl -sS https://iaas.example/api/v1/tenants \
  -H "Authorization: Bearer $TOKEN"
```

## Related

- Feature guides: [Overview](index.md)
- Operator install: [Installation](../installation.md)
- Helm values: [Configuration](../configuration.md)
