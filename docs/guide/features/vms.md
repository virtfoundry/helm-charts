# Virtual machines

VMs are KubeVirt `VirtualMachine` objects in the tenant namespace, managed through the VirtFoundry UI/API.

## Deploy

**UI:** Compute → **VMs** → create/deploy.

Typical inputs:

1. Name
2. [Template](templates.md) (container disk or ready ISO)
3. [Service offering](offerings.md) (CPU/memory)
4. Optional networks / SSH keys / cloud-init extras

**API:**

```bash
curl -X POST -H "Authorization: Bearer $TOKEN" \
  -H "X-Tenant-ID: $TENANT_ID" \
  -H "Content-Type: application/json" \
  -d '{
    "name": "web-1",
    "template_id": "…",
    "service_offering_id": "…",
    "network_ids": []
  }' \
  https://iaas.example/api/v1/vms
```

Deploy may run synchronously or via the async worker (`deploy_vm` job). State is reconciled from KubeVirt phase into the control-plane DB.

## Lifecycle

| Action | UI | API |
|--------|----|-----|
| List | `/vms` | `GET /api/v1/vms` |
| Get | `/vms/{name}` | `GET /api/v1/vms/{name}` |
| Update | Detail form | `PATCH /api/v1/vms/{name}` |
| Start | Actions | `POST /api/v1/vms/start` |
| Stop | Actions | `POST /api/v1/vms/stop` |
| Delete | Actions | `POST /api/v1/vms/delete` |
| Logs | Detail → Logs | `GET /api/v1/vms/{name}/logs` |

## VM detail

Path: `/vms/{name}`

| Tab / area | Purpose |
|------------|---------|
| Overview | State, offering, template |
| Network | NICs / attached networks |
| Storage | Attach / detach [volumes](storage.md) |
| Logs | Guest/serial-style logs when available |
| Snapshots | [VM snapshots](storage.md) create/restore |

## Attach / detach volumes

```bash
# List disks on VM
curl -H "Authorization: Bearer $TOKEN" \
  https://iaas.example/api/v1/vms/web-1/volumes

# Attach
curl -X POST -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"volume_id":"…"}' \
  https://iaas.example/api/v1/vms/web-1/volumes

# Detach
curl -X DELETE -H "Authorization: Bearer $TOKEN" \
  https://iaas.example/api/v1/vms/web-1/volumes/$VOLUME_ID
```

## Related

- [Console & SSH](access.md)
- [Volumes & snapshots](storage.md)
- [VPCs & networks](networking.md)
- [Quickstart](../quickstart.md) — first VM path
