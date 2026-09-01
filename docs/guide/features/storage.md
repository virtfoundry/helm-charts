# Volumes and snapshots

VirtFoundry storage has **volumes** (persistent disks) and **two different snapshot types**.

## Volumes

PVC-backed disks in the tenant namespace (default StorageClass from Helm `platform.storage.defaultClass`).

**UI:** Storage → **Volumes** (`/volumes`) — create / delete.

| Method | Path |
|--------|------|
| GET | `/api/v1/volumes` |
| POST | `/api/v1/volumes` |
| DELETE | `/api/v1/volumes/{id}` |

Attach volumes to a running or stopped VM from the VM detail page — see [Virtual machines](vms.md).

!!! tip "StorageClass"
    Use [Longhorn](https://longhorn.io/) (or another CSI with snapshots) beyond throwaway labs. `local-path` is fine for a first VM, not for volume snapshots. See [Configuration](../configuration.md).

## Two snapshot features

| Kind | UI / API | Kubernetes API | Cluster need |
|------|----------|----------------|--------------|
| **VM snapshot** | `/vm-snapshots`, VM detail | `VirtualMachineSnapshot` | KubeVirt (already required) |
| **Volume snapshot** | `/snapshots` | `VolumeSnapshot` | CSI snapshotter + snapshot-capable SC |

### VM snapshots

Point-in-time snapshot of a whole guest (KubeVirt). Works on any cluster with KubeVirt — no CSI snapshot stack required.

**UI:** Compute → **VM Snapshots** (`/vm-snapshots`).

Example after creating snapshots for VMs `fedora-primary` and `fedora-standby`:

```bash
kubectl get vmsnapshot -n virtfoundry-tenant-default
# NAME                      SOURCEKIND       SOURCENAME       PHASE       READYTOUSE
# fedora-primary-baseline   VirtualMachine   fedora-primary   Succeeded   true
```

| Action | API |
|--------|-----|
| List / create | `GET`/`POST /api/v1/vm-snapshots` |
| Delete | `POST /api/v1/vm-snapshots/delete` |
| Restore | `POST /api/v1/vm-snapshots/restore` |

Works on lab StorageClasses where volume snapshots do not.

### Volume snapshots

CSI snapshot of a PVC.

| Action | API |
|--------|-----|
| List / create | `GET`/`POST /api/v1/snapshots` |
| Delete | **Not exposed yet** |

Set `platform.storage.snapshotClass` (e.g. `longhorn`) or rely on a default `VolumeSnapshotClass`. Details and prerequisites: [Configuration — Snapshots](../configuration.md#snapshots-vm-vs-volume).

!!! warning "`local-path`"
    Volume snapshots **fail** without CSI external-snapshotter + a capable driver. Use **VM snapshots** on pure `local-path` labs.

## Related

- [Configuration](../configuration.md)
- [Topologies](../topologies.md)
- [Virtual machines](vms.md)
