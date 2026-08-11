# Service offerings

A **service offering** is a CPU/memory catalog entry used when deploying a VM (CloudStack-style “compute offering”).

## Shared vs dedicated CPU

| Mode | Behavior |
|------|----------|
| **Shared** (default) | Guest `domain.cpu.cores` set; CPU **request** omitted so KubeVirt `cpuAllocationRatio` can overcommit |
| **Dedicated** (`dedicated_cpu`) | Guaranteed QoS — CPU request equals limit |

Offerings are **platform-wide** (all tenants see the same catalog).

## Who can manage

| Action | Who |
|--------|-----|
| List | Any authenticated user |
| Create / update / delete | **root only** |

## UI

**Platform → Offerings** (`/offerings`) — root only.

Typical fields: name, display name, CPU cores, memory (Mi/Gi), optional dedicated CPU flag.

## API

```bash
# List (any user)
curl -H "Authorization: Bearer $TOKEN" \
  https://iaas.example/api/v1/service-offerings

# Create (root)
curl -X POST -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"name":"small","display_name":"Small","cpu_number":1,"memory_mb":1024}' \
  https://iaas.example/api/v1/service-offerings
```

| Method | Path | Auth |
|--------|------|------|
| GET | `/api/v1/service-offerings` | JWT |
| POST | `/api/v1/service-offerings` | root |
| PATCH | `/api/v1/service-offerings/{id}` | root |
| DELETE | `/api/v1/service-offerings/{id}` | root |

## Related

- [Virtual machines](vms.md) — pick an offering at deploy time
- [Configuration](../configuration.md) — KubeVirt CPU overcommit (`cpuAllocationRatio`)
