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

## Allowed ISO URLs

CDI downloads the ISO from **inside the cluster**. VirtFoundry validates the URL in the API ([core#95](https://github.com/virtfoundry/core/issues/95)): `https` on port 443 only, no embedded credentials, no loopback / link-local / private / reserved targets, and the host must be on an admin allowlist.

Configure via the API config (ConfigMap or env):

```yaml
security:
  iso_import:
    allowed_hosts:
      - "iso.mylab.example.com"
      - "*.blob.core.windows.net"
    disable_http_import: false
```

```bash
VIRTFOUNDRY_ISO_ALLOWED_HOSTS="iso.mylab.example.com,*.blob.core.windows.net"
VIRTFOUNDRY_ISO_DISABLE_HTTP_IMPORT=1
```

With no `allowed_hosts`, the built-in list covers public Microsoft / Linux install media and common object-storage hosts. Setting `allowed_hosts` **replaces** that list. Details: [core VM-TEMPLATES](https://github.com/virtfoundry/core/blob/main/docs/VM-TEMPLATES.md#allowed-iso-urls).

## CDI importer egress

The allowlist is **name-based**. CDI resolves the hostname itself, so DNS rebinding (or a redirect to a private address) can still reach cluster-internal or metadata targets if the network path exists.

VirtFoundry therefore creates an **Egress** NetworkPolicy in each **tenant** namespace (where CDI importer pods run — not the chart release namespace). A single NetworkPolicy in `virtfoundry-system` cannot cover tenant importers.

| | |
|--|--|
| Name | `virtfoundry-cdi-importer-egress` |
| Created by | core `EnsureTenantNamespace` (on tenant create and on API bootstrap for existing tenants) |
| Selects | pods labeled `cdi.kubevirt.io=importer` |
| Allows | DNS to `kube-system` / `k8s-app=kube-dns` (UDP+TCP 53); `0.0.0.0/0` and `::/0` except private / link-local / CGNAT ranges |

**Requirements:** the cluster CNI must enforce NetworkPolicy (Calico, Cilium, etc.). Without enforcement the object is inert.

### Private ISO mirrors

If your mirror lives on RFC1918 (or another denied range), either:

1. Patch the policy in the tenant NS to add an `egress` `ipBlock` for that CIDR, or
2. Apply a second allow policy in the same namespace (NetworkPolicies are additive for allowed traffic).

Example second policy (also under [`docs/examples/`](../../examples/cdi-importer-egress-private-mirror.yaml)):

```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: virtfoundry-cdi-importer-private-mirror
  namespace: virtfoundry-tenant-acme   # each tenant NS
spec:
  podSelector:
    matchLabels:
      cdi.kubevirt.io: importer
  policyTypes: [Egress]
  egress:
    - to:
        - ipBlock:
            cidr: 10.10.0.0/24        # your mirror subnet
```

Also add the mirror hostname to `security.iso_import.allowed_hosts` so the API accepts the URL.

### Residuals

- DNS rebinding to a *public* malicious IP is still possible; the allowlist remains the app control.
- Upload / other CDI components are not selected by this policy (only `cdi.kubevirt.io=importer`).

Tracked as [helm-charts#49](https://github.com/virtfoundry/helm-charts/issues/49).

## Deploying with templates

On **VMs**, pick a template + [service offering](offerings.md). See [Virtual machines](vms.md).
