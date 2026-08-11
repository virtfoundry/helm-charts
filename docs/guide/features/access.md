# Console and SSH

Two ways to reach a guest: **noVNC console** (browser) and **SSH** (keys + optional NodePort expose).

## noVNC console

**UI:** Compute → open a VM → **Console**, or `/console` with the VM selected.

The browser opens a WebSocket to `/ws/console`, which proxies KubeVirt’s VNC subresource.

| Requirement | Notes |
|-------------|--------|
| Permission | `vms:console` (included for admin/operator) |
| VM state | Prefer **Running** |

!!! tip
    Console is best for installers (ISO/Windows) and recovery when networking is broken. Prefer SSH for day-2 Linux access.

## SSH keys

**UI:** Compute → **SSH keys** (`/ssh-keys`)

| Action | Description |
|--------|-------------|
| **Generate** | Creates a key pair; private key download once |
| **Register** | Paste an existing public key |
| **Delete** | Remove from the catalog |

Keys can be selected at VM deploy so cloud-init injects them (container-disk Linux images).

| Method | Path |
|--------|------|
| GET | `/api/v1/ssh-keys` |
| POST | `/api/v1/ssh-keys` (generate) |
| POST | `/api/v1/ssh-keys/register` |
| DELETE | `/api/v1/ssh-keys/{id}` |

## Expose SSH (NodePort)

For lab access without a public Multus IP:

```bash
# Status
curl -H "Authorization: Bearer $TOKEN" \
  https://iaas.example/api/v1/vms/web-1/ssh

# Expose
curl -X POST -H "Authorization: Bearer $TOKEN" \
  https://iaas.example/api/v1/vms/web-1/ssh
```

Response includes how to reach SSH (NodePort / service details). Use with a registered key or the password set via cloud-init.

!!! warning "Security"
    NodePort exposes SSH on the cluster node network. Prefer private Multus networks or a bastion in production — see [Topologies](../topologies.md).

## Related

- [Virtual machines](vms.md)
- [Images & templates](templates.md) — cloud-init capable images
