# Installation

VirtFoundry installs the **control plane** (API, UI). Platform state is stored in **`virtfoundry.io` CRDs**. Virtual machines and networking rely on KubeVirt, Multus, and CDI on the cluster.

!!! tip "Install prerequisites first"
    See **[Platform prerequisites](prerequisites.md)** for official install links to [KubeVirt](https://kubevirt.io/), [Multus](https://github.com/k8snetworkplumbingwg/multus-cni), [CDI](https://github.com/kubevirt/containerized-data-importer), storage, and optional MetalLB / CSI snapshots.

**Recommended order:** [prerequisites](prerequisites.md) → **virtfoundry-crds** → **virtfoundry-operator** (controller) → **virtfoundry** (API + UI) → optional **virtfoundry-vks** ([Kubernetes clusters](features/vks.md)).

**Want UI + first VM in under 30 minutes?** Start with the [Quickstart](quickstart.md). On a laptop (Docker, no switch/VLAN), use **[Kind](kind.md)**.

For **minimum vs production** layouts (what works for VPC / public / snapshots on a home router), see [Deployment topologies](topologies.md).

## Install everything (copy and paste)

For a fresh Kubernetes 1.28+ cluster that already has a **StorageClass** and a working `kubectl` context. It installs the platform prerequisites (Multus, KubeVirt, CDI), then VirtFoundry, and prints the login.

```bash
git clone --branch v@@VERSION@@ https://github.com/virtfoundry/helm-charts.git \
  && cd helm-charts \
  && ./scripts/setup/multus.sh && ./scripts/setup/kubevirt.sh && ./scripts/setup/cdi.sh \
  && ROOT_PASSWORD="$(openssl rand -base64 18)" \
  && helm repo add virtfoundry https://virtfoundry.github.io/helm-charts && helm repo update \
  && helm install virtfoundry-crds virtfoundry/virtfoundry-crds --version @@VERSION@@ \
       -n virtfoundry-system --create-namespace --wait \
  && helm install virtfoundry-operator virtfoundry/virtfoundry-operator --version @@VERSION@@ \
       -n virtfoundry-system --wait \
  && helm install virtfoundry virtfoundry/virtfoundry --version @@VERSION@@ \
       -n virtfoundry-system --wait \
       --set-string secrets.rootPassword="$ROOT_PASSWORD" \
       --set-string secrets.jwtSecret="$(openssl rand -hex 32)" \
  && echo "Login: root / $ROOT_PASSWORD" \
  && kubectl -n virtfoundry-system port-forward svc/virtfoundry-ui 8080:80
```

Then open <http://127.0.0.1:8080>.

- The root password is shown **once**, in that terminal. Save it, or set `secrets.existingSecret` instead ([Secrets](configuration.md#secrets)).
- Run it **once**. A second run would generate new credentials. Use `helm upgrade` afterwards ([CRDs and upgrades](crds.md)).
- The setup scripts install Multus, KubeVirt and CDI **cluster-wide**. Skip that line if you already run them.
- Not included: Ingress or Gateway API, Longhorn, and [VKS](features/vks.md) (needs Kamaji). On a laptop use [Kind](kind.md) instead.

---

## Prerequisites overview

| Component | Required? | Role in VirtFoundry |
|-----------|-----------|-------------------|
| Kubernetes 1.28+ | **Yes** | Runs all workloads |
| Helm 3.x | **Yes** | Installs the charts |
| **virtfoundry-crds** | **Yes** (CRD store) | The `virtfoundry.io` CRDs, upgraded by Helm and kept on uninstall ([CRDs and upgrades](crds.md)) |
| **virtfoundry-operator** | **Yes** | Controller: reconciles Tenant/Instance status |
| [KubeVirt](https://kubevirt.io/) | **Yes** | Hypervisor — VMs, start/stop, console, **VM** snapshots |
| [Multus CNI](https://github.com/k8snetworkplumbingwg/multus-cni) | **Yes** | Secondary NICs — tenant VPCs, isolated L2, public VM network |
| [CDI](https://github.com/kubevirt/containerized-data-importer) | **Yes** for ISO/import templates; optional for container-disk-only | Imports ISOs and blank boot disks via `DataVolume` |
| Ingress **or** Gateway API + controller | One of them | Exposes UI and API on a hostname |
| StorageClass — **prefer [Longhorn](https://longhorn.io/)** | **Yes** for disks | PVCs for VM volumes, ISO storage; `local-path` only for quick labs |
| CSI snapshotter + snapshot-capable CSI (Longhorn includes this) | **Recommended**; required for **volume** snapshots UI | `VolumeSnapshot` CRDs + `VolumeSnapshotClass`; **not** provided by `local-path` |
| MetalLB (or cloud LB) | Bare metal only | When Services need external IPs (also the default VKS control-plane VIP) |
| Kamaji + **virtfoundry-vks** | Optional | Managed Kubernetes clusters for tenants ([VKS](features/vks.md)) |

!!! note "Not bundled in the Helm chart by default"
    KubeVirt, Multus, and CDI are **cluster-scoped platform operators**. They are installed separately so you can pin versions, align with your distro, and upgrade them independently of VirtFoundry releases.

---

## Why each platform component is needed

### KubeVirt — required

VirtFoundry does **not** embed a hypervisor. The API talks to KubeVirt CRDs (and the operator syncs Instance status back to `virtfoundry.io` CRs):

- `VirtualMachine` / `VirtualMachineInstance` — create, start, stop, delete VMs
- `VirtualMachineSnapshot` — **VM** snapshots (point-in-time of the guest; not the same as CSI volume snapshots)
- VNC subresource — web console in the UI

Without KubeVirt, deploy and lifecycle operations fail immediately (`kubevirt.enabled` assumes the KubeVirt API is reachable).

!!! warning "Volume snapshots ≠ VM snapshots"
    The **Volume Snapshots** page creates Kubernetes `VolumeSnapshot` objects (`snapshot.storage.k8s.io`). That API is **not** installed by KubeVirt and is **not** available with only `local-path`. Without CSI external-snapshotter + a snapshot-capable StorageClass (Longhorn, Ceph RBD, cloud CSI, …), the UI returns `the server could not find the requested resource`. Use **VM Snapshots** on lab/`local-path` clusters, or install a CSI snapshot stack for volume snapshots. Details: [Configuration — Snapshots](storage-config.md#snapshots-vm-vs-volume).

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

# 1. CRDs, then the operator (required)
helm install virtfoundry-crds virtfoundry/virtfoundry-crds \
  --namespace virtfoundry-system \
  --create-namespace
helm install virtfoundry-operator virtfoundry/virtfoundry-operator \
  --namespace virtfoundry-system

# 2. API + UI
helm install virtfoundry virtfoundry/virtfoundry \
  --namespace virtfoundry-system \
  --set secrets.rootPassword='choose-a-strong-password' \
  --set secrets.jwtSecret="$(openssl rand -hex 32)"
```

The chart ships no credential defaults — see [Secrets](configuration.md#secrets) for the
rules and for the `secrets.existingSecret` path.

Pin a release (same CRD store flags):

```bash
helm install virtfoundry-crds virtfoundry/virtfoundry-crds \
  --version 0.11.2 \
  --namespace virtfoundry-system \
  --create-namespace
helm install virtfoundry-operator virtfoundry/virtfoundry-operator \
  --version 0.11.2 \
  --namespace virtfoundry-system

helm install virtfoundry virtfoundry/virtfoundry --version 0.11.2 \
  --namespace virtfoundry-system \
  --set secrets.rootPassword='choose-a-strong-password' \
  --set secrets.jwtSecret="$(openssl rand -hex 32)"
```

Images default to `ghcr.io/virtfoundry/core:0.11.2`, `ui:0.11.2`, and `operator:0.11.2`.

---

## Why `--set` is on the Helm command

`--set` is a **Helm** flag. It must appear on the same `helm install` / `helm upgrade` line as the chart. It does not work as a follow-up kubectl command.

- **Must set at install:** `secrets.rootPassword`, `secrets.jwtSecret` — or `secrets.existingSecret`. The chart has no defaults for them and fails to render without one of the two ([Secrets](configuration.md#secrets)).
- **Usually omit:** public IP CIDR — see below. Storage class — `auto` picks Longhorn when it exists.
- **Prefer `-f`:** anything more than two keys. Written defaults: [Chart values](chart-values.md).

---

### Longhorn — recommended storage (not bundled)

VirtFoundry never ships disks. `platform.storage.defaultClass: auto` selects **`longhorn`** if that StorageClass is already on the cluster, otherwise the cluster default, otherwise `local-path`.

Install [Longhorn](https://longhorn.io/) first if you want replicated VM disks and **volume** snapshots. `local-path` is fine for a first VM; volume snapshots need CSI (Longhorn provides that). Pin the class with `--set platform.storage.defaultClass=longhorn` if auto is not enough.

---

### Public IP — optional; homelab can inherit the node LAN

Leave public **unset** (`enabled: false`, chart default) to install the UI. VMs stay on the pod network.

If you enable public later, CIDR/gateway/pool default to the first **Node InternalIP** (`autoFromCluster: true`) so a single-LAN homelab does not invent `10.0.50.0/24`. That is the **Kubernetes** address, not a VLAN. Dedicated VM VLANs (this project's homelab uses `10.0.50.0/24` on `enp3s0.50`) must set CIDR by hand and `autoFromCluster: false`. Auto never sets `uplink` (that would steal the kubelet NIC).

Script: `scripts/detect-host-public-net.sh`. Full values: [Chart values](chart-values.md). Underlay choices: [Topologies](topologies.md#public-network-underlay).

---

## Install from git clone

```bash
git clone https://github.com/virtfoundry/helm-charts.git
cd helm-charts

helm install virtfoundry-crds ./charts/virtfoundry-crds \
  --namespace virtfoundry-system --create-namespace
helm install virtfoundry-operator ./charts/virtfoundry-operator \
  --namespace virtfoundry-system

helm install virtfoundry ./charts/virtfoundry \
  --namespace virtfoundry-system \
  --set secrets.rootPassword='choose-a-strong-password' \
  --set secrets.jwtSecret="$(openssl rand -hex 32)"
```

Validate templates:

```bash
make lint
```

---

## Install VKS (optional)

VKS adds the `VKSCluster` resource. Install it **after** the operator and core. The `virtfoundry-vks` chart is not in the Helm repository yet, so install it from the [`virtfoundry/vks`](https://github.com/virtfoundry/vks) repository.

Prerequisites: [Kamaji](prerequisites.md#optional-kubernetes-clusters-vks) with its CRDs and a `DataStore`, and a LoadBalancer implementation (MetalLB) unless you use `NodePort`.

```bash
git clone --branch v@@VERSION@@ https://github.com/virtfoundry/vks.git
cd vks

helm install virtfoundry-vks ./charts/virtfoundry-vks \
  --namespace virtfoundry-system
```

The image defaults to `ghcr.io/virtfoundry/vks:@@VERSION@@` (the chart `appVersion`). Pin by digest with `--set image.digest=sha256:...` for GitOps.

| Value | Default | Description |
|-------|---------|-------------|
| `loadBalancerAddressPool` | `""` | Default MetalLB pool for control planes. Empty means cluster autoAssign. A cluster can override it with `spec.controlPlane.addressPool` |
| `nodeAddress` / `nodePort` | `""` / `30443` | Only for `NodePort` control planes (lab) |
| `image.tag` / `image.digest` | `""` | Tag defaults to `appVersion`; digest wins when set |

The `virtfoundry` chart's API ClusterRole already grants access to `vksclusters`, and the operator chart's template allowlist includes `ghcr.io/virtfoundry/`, so the node image is accepted. Verify:

```bash
kubectl get crd vksclusters.virtfoundry.io
kubectl -n virtfoundry-system get pods | grep vks
```

Then create a cluster: [Kubernetes clusters (VKS)](features/vks.md).

---

## First login

Bootstrap credentials come from the chart — there is no built-in default password:

- **User:** `root`
- **Password:** the `secrets.rootPassword` you passed at install (or `ROOT_PASSWORD` in your `secrets.existingSecret`)

API base path: `/api/v1` on the same hostname as the UI.

## Verify CRD store

After install:

```bash
kubectl get crd | grep virtfoundry.io
kubectl get vf-tenant
kubectl get vf-instance -A
kubectl get vmsnapshot -A
kubectl get pods -n virtfoundry-system
```

You should see `virtfoundry-operator` and `virtfoundry-api` Running, Instance CRs for your VMs, and KubeVirt `VirtualMachineSnapshot` objects when you use **VM Snapshots** in the UI.

---

## Operator recovery: legacy tenant namespace

The operator adopts a tenant namespace only when it carries both
`app.kubernetes.io/part-of=virtfoundry` and `virtfoundry.io/tenant=<slug>`. A namespace
created by an older API (before that contract) lacks them. Symptoms:

- `kubectl get tenants.virtfoundry.io` shows the Tenant as `Failed`.
- Operator log: `Refused to adopt Namespace for Tenant`.
- Instances in that namespace are rejected with `namespace ... is missing label app.kubernetes.io/part-of=virtfoundry`.
- API log: `tenant namespace is missing operator ownership labels and the API cannot patch namespaces`.

The API deliberately has no `patch` permission on namespaces (least privilege; the operator
owns tenant namespaces), so label the namespace once by hand. Replace `<slug>` with the
Tenant's `spec.slug`:

```bash
kubectl label namespace virtfoundry-tenant-<slug> \
  app.kubernetes.io/part-of=virtfoundry virtfoundry.io/tenant=<slug>
```

A `Failed` Tenant is a terminal error and is not retried on its own. Restart the operator so
it reconciles again:

```bash
kubectl -n virtfoundry-system rollout restart deploy/virtfoundry-operator
kubectl get tenants.virtfoundry.io   # PHASE should become Ready
```

Namespaces created by the current API already carry both labels, so new tenants need nothing.

---

## Next steps

- [Quickstart](quickstart.md) — under-30-minute UI + first VM path
- [Configuration](configuration.md) — Helm values and networking (includes `platform.storage.snapshotClass`)
- [Chart values (defaults)](chart-values.md) — full `values.yaml`, why `--set`, Longhorn and public IP
- [Helm repository](helm-repository.md) — publishing and consuming chart releases
- [CRDs and upgrades](crds.md) · [Kubernetes clusters (VKS)](features/vks.md) · [Terraform provider](terraform.md) · [Troubleshooting](troubleshooting.md)
