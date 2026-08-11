# Installation

VirtFoundry installs the **control plane only** (API, worker, UI, optional MySQL). Virtual machines, extra networks, and disk imports rely on platform components that must already exist on the cluster — or be installed **before** `helm install`.

For **minimum vs production** layouts (what works for VPC / public / snapshots on a home router), see [Deployment topologies](topologies.md).

## Prerequisites overview

| Component | Required? | Role in VirtFoundry |
|-----------|-----------|-------------------|
| Kubernetes 1.28+ | **Yes** | Runs all workloads |
| Helm 3.x | **Yes** | Installs the chart |
| [KubeVirt](https://kubevirt.io/) | **Yes** | Hypervisor — VMs, start/stop, console, **VM** snapshots |
| [Multus CNI](https://github.com/k8snetworkplumbingwg/multus-cni) | **Yes** | Secondary NICs — tenant VPCs, isolated L2, public VM network |
| [CDI](https://github.com/kubevirt/containerized-data-importer) | **Yes** for ISO/import templates; optional for container-disk-only | Imports ISOs and blank boot disks via `DataVolume` |
| Ingress **or** Gateway API + controller | One of them | Exposes UI and API on a hostname |
| StorageClass — **prefer [Longhorn](https://longhorn.io/)** | **Yes** for disks | PVCs for MySQL, VM volumes, ISO storage; `local-path` only for quick labs |
| CSI snapshotter + snapshot-capable CSI (Longhorn includes this) | **Recommended**; required for **volume** snapshots UI | `VolumeSnapshot` CRDs + `VolumeSnapshotClass`; **not** provided by `local-path` |
| MetalLB (or cloud LB) | Bare metal only | When Services need external IPs |

!!! note "Not bundled in the Helm chart by default"
    KubeVirt, Multus, and CDI are **cluster-scoped platform operators**. They are installed separately so you can pin versions, align with your distro, and upgrade them independently of VirtFoundry releases.

---

## Why each platform component is needed

### KubeVirt — required

VirtFoundry does **not** embed a hypervisor. The API and worker talk to KubeVirt CRDs:

- `VirtualMachine` / `VirtualMachineInstance` — create, start, stop, delete VMs
- `VirtualMachineSnapshot` — **VM** snapshots (point-in-time of the guest; not the same as CSI volume snapshots)
- VNC subresource — web console in the UI

Without KubeVirt, deploy and lifecycle operations fail immediately (`kubevirt.enabled` assumes the KubeVirt API is reachable).

!!! warning "Volume snapshots ≠ VM snapshots"
    The **Volume Snapshots** page creates Kubernetes `VolumeSnapshot` objects (`snapshot.storage.k8s.io`). That API is **not** installed by KubeVirt and is **not** available with only `local-path`. Without CSI external-snapshotter + a snapshot-capable StorageClass (Longhorn, Ceph RBD, cloud CSI, …), the UI returns `the server could not find the requested resource`. Use **VM Snapshots** on lab/`local-path` clusters, or install a CSI snapshot stack for volume snapshots. Details: [Configuration — Snapshots](configuration.md#snapshots-vm-vs-volume).

**Verify:**

```bash
kubectl get pods -n kubevirt
kubectl get crd virtualmachines.kubevirt.io
```

---

### Multus CNI — required

VirtFoundry models **multi-tenant networking**: tenants, VPCs, security groups, and an optional shared public network. That requires **more than the default pod CNI**:

| Feature | How VirtFoundry uses Multus |
|---------|---------------------------|
| Tenant VPC / private networks | Creates `NetworkAttachmentDefinition` (NAD) per network on an isolated bridge |
| Public / routable VM IPs | Secondary NIC on a bridge or macvlan NAD + cloud-init addressing |
| Security groups | Kubernetes `NetworkPolicy` on the pod network; extra NICs use Multus interfaces |

The hypervisor driver attaches Multus networks to VM launcher pods (`v1.multus-cni.io/default-network` and additional NADs). **VPCs, custom networks, and public IP pools do not work without Multus.**

Pod-only VMs (no `network_ids`, public network disabled) still use KubeVirt’s masquerade interface, but the product expects Multus for full IaaS functionality.

**Verify:**

```bash
kubectl get pods -n kube-system -l app=multus
kubectl get crd network-attachment-definitions.k8s.cni.cncf.io
```

---

### CDI — required for ISO and import workflows

[CDI](https://github.com/kubevirt/containerized-data-importer) provides `DataVolume` resources. VirtFoundry uses CDI when:

- Registering an **ISO template** (HTTP import of an `.iso` into a PVC)
- Creating a **blank boot disk** for install-from-ISO (e.g. Windows eval)
- Waiting for import completion before a VM can boot from ISO

**Container-disk templates** (image URL pointing at a registry-hosted disk image) can work **without CDI** — KubeVirt pulls the image directly as a `containerDisk`.

| Template / deploy path | CDI needed? |
|------------------------|-------------|
| Linux cloud image (container disk) | No |
| ISO template or install-from-ISO | **Yes** |
| Attaching an existing imported volume | **Yes** (volume created via CDI) |

If you only use container-disk templates, you can skip CDI initially; enable it before using ISO features.

**Verify:**

```bash
kubectl get pods -n cdi
kubectl get crd datavolumes.cdi.kubevirt.io
```

---

## Installing platform components

The chart can optionally trigger install **hooks** (`platform.multus.install`, `platform.cdi.install`, KubeVirt job). By default these are **off** — most clusters install platform software once, outside VirtFoundry upgrades.

**Recommended:** use the helper scripts (idempotent) from a chart clone:

```bash
export KUBECONFIG=/path/to/kubeconfig

./scripts/setup/kubevirt.sh   # KubeVirt operator + CRDs
./scripts/setup/multus.sh     # Multus DaemonSet
./scripts/setup/cdi.sh        # CDI operator
```

Or install from upstream docs and verify CRDs before proceeding.

**Order:** Multus and storage class first → KubeVirt → CDI (CDI depends on KubeVirt CRDs).

---

## Install VirtFoundry from Helm repository

After platform prerequisites are healthy:

```bash
helm repo add virtfoundry https://virtfoundry.github.io/helm-charts
helm repo update

helm install virtfoundry virtfoundry/virtfoundry \
  --namespace virtfoundry-system \
  --create-namespace \
  --set secrets.rootPassword='change-me' \
  --set secrets.jwtSecret='change-me-long-random'
```

Pin a release:

```bash
helm install virtfoundry virtfoundry/virtfoundry --version 1.4.1 \
  --namespace virtfoundry-system \
  --create-namespace \
  --set secrets.rootPassword='change-me' \
  --set secrets.jwtSecret='change-me-long-random'
```

Images default to `ghcr.io/virtfoundry/core:1.4.1` and `ui:1.4.1`.

---

## Install from git clone

```bash
git clone https://github.com/virtfoundry/helm-charts.git
cd helm-charts

helm install virtfoundry ./charts/virtfoundry \
  --namespace virtfoundry-system \
  --create-namespace \
  --set secrets.rootPassword='change-me' \
  --set secrets.jwtSecret='change-me'
```

Validate templates:

```bash
make lint
```

---

## First login

Default bootstrap credentials (override with `secrets.rootPassword`):

- **User:** `root`
- **Password:** value of `secrets.rootPassword` (default in chart values: `virtfoundry`)

API base path: `/api/v1` on the same hostname as the UI.

---

## Next steps

- [Configuration](configuration.md) — Helm values and networking
- [Helm repository](helm-repository.md) — publishing and consuming chart releases
