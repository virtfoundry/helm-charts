# Images and templates

VM templates define the **OS image** used when deploying a virtual machine. Templates are either **container disks** (cloud-init Linux) or **ISO imports** (typically Windows via CDI).

## Platform vs tenant templates

| Scope | `tenant_id` | Who manages | Examples |
|-------|-------------|-------------|----------|
| **Platform** | empty | Seeded at startup; read-only in UI | `cirros`, `ubuntu-2204`, `windows-server-2022` |
| **Tenant** | tenant UUID | Bootstrap or UI/API | e.g. `fedora-39` |

Tenants see **both** platform and their own templates. Platform templates are not copied per tenant.

## Container disks

KubeVirt runs container disks as ephemeral root volumes. Prefer images with cloud-init for Linux.

**Sources:**

- [quay.io/containerdisks](https://quay.io/organization/containerdisks)
- [KubeVirt container images](https://github.com/kubevirt/kubevirt/tree/main/containerimages)

| Name | Image |
|------|-------|
| Cirros (demo) | `quay.io/kubevirt/cirros-container-disk-demo` |
| Ubuntu 22.04 | `quay.io/containerdisks/ubuntu:22.04` |
| Fedora demo | `quay.io/kubevirt/fedora-container-disk-demo` |

## Register via UI

1. Select a tenant (root: use the tenant switcher).
2. Open **Images & Templates** (`/templates`).
3. **Register image** → **Container disk** or **ISO (PVC)**.
4. For container disks: name, display name, image URL, optional `#cloud-config` user-data.

Platform templates show a **platform** badge and cannot be edited or deleted.

## Register via API

```bash
curl -H "Authorization: Bearer $TOKEN" \
  -H "X-Tenant-ID: $TENANT_ID" \
  https://iaas.example/api/v1/vm-templates

curl -X POST -H "Authorization: Bearer $TOKEN" \
  -H "X-Tenant-ID: $TENANT_ID" \
  -H "Content-Type: application/json" \
  -d '{
    "name": "ubuntu-2404",
    "display_name": "Ubuntu 24.04",
    "image": "quay.io/containerdisks/ubuntu:24.04",
    "source_type": "container",
    "os_type": "linux"
  }' \
  https://iaas.example/api/v1/vm-templates
```

| Method | Path | Description |
|--------|------|-------------|
| GET | `/api/v1/vm-templates` | Platform + tenant |
| POST | `/api/v1/vm-templates` | Create tenant template |
| PATCH | `/api/v1/vm-templates/{id}` | Update tenant template |
| DELETE | `/api/v1/vm-templates/{id}` | Delete tenant template |

## ISO import (CDI)

ISO templates download install media into a DataVolume/PVC in the tenant namespace.

**Requirements:** CDI on the cluster (Helm chart can install it), HTTP(S) ISO URL, RWO StorageClass.

**Flow:**

1. Create template with `source_type: "iso"` and `image` = ISO URL
2. `import_state: importing`, `state: Inactive`
3. Worker creates CDI HTTP import DataVolume
4. Success → `import_state: ready`, `state: Active`
5. Failure → `import_state: failed`

| Field | Default | Description |
|-------|---------|-------------|
| `iso_size_gi` | 8 | DataVolume size for the ISO |
| `boot_disk_size_gi` | 32 | Blank boot disk at VM deploy |
| `storage_class` | cluster default | StorageClass for DataVolumes |

The UI polls every 5s while any template is importing.

```bash
curl -X POST -H "Authorization: Bearer $TOKEN" \
  -H "X-Tenant-ID: $TENANT_ID" \
  -H "Content-Type: application/json" \
  -d '{
    "name": "windows-server-2022",
    "display_name": "Windows Server 2022 Eval",
    "image": "https://go.microsoft.com/fwlink/?linkid=2195280",
    "source_type": "iso",
    "iso_size_gi": 8,
    "boot_disk_size_gi": 32
  }' \
  https://iaas.example/api/v1/vm-templates
```

!!! warning
    You cannot deploy from an ISO template until `import_state` is `ready`.

## Deploying with templates

On **VMs**, pick a template + [service offering](offerings.md). See [Virtual machines](vms.md).
