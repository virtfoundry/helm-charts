# Quickstart (under 30 minutes)

Goal: **UI login + first VM**. On a laptop, start with **[Kind](kind.md)** (Docker, no VLAN). On a cluster that already has Kubernetes, KubeVirt, Multus, and CDI, continue below.

If you still need to install those platform components, budget extra time and follow the full [Installation](installation.md) guide (or run `./scripts/setup/{kubevirt,multus,cdi}.sh` from a [helm-charts](https://github.com/virtfoundry/helm-charts) clone).

!!! tip "Homelab with Argo / Longhorn"
    Production-shaped layouts (Gateway API, Longhorn, snapshots): [Deployment topologies](topologies.md). Public IPs without a VLAN: [Kind](kind.md) or [Topologies — public underlay](topologies.md#public-network-underlay).

---

## 0. Check prerequisites (~2 min)

```bash
kubectl get crd virtualmachines.kubevirt.io
kubectl get ds -A | grep -i multus || kubectl get pods -A | grep -i multus
kubectl get crd datavolumes.cdi.kubevirt.io
kubectl get storageclass
```

You need at least one **default** or known StorageClass. Prefer [Longhorn](https://longhorn.io/) (or any CSI with snapshots) for real disks.

!!! warning "`local-path` labs"
    Fine for a first UI click. **Volume snapshots will not work** without CSI external-snapshotter + a `VolumeSnapshotClass`. Use **VM snapshots** on lab StorageClasses, or install Longhorn (etc.) for volume snapshots.

---

## 1. Install VirtFoundry (~5 min)

```bash
helm repo add virtfoundry https://virtfoundry.github.io/helm-charts
helm repo update

# CRDs + operator (required)
helm install virtfoundry-operator virtfoundry/virtfoundry-operator \
  --namespace virtfoundry-system --create-namespace

# API + UI — CRD store (no MySQL/worker)
helm install virtfoundry virtfoundry/virtfoundry \
  --version 0.5.0 \
  --namespace virtfoundry-system \
  --set secrets.rootPassword='change-me' \
  --set secrets.jwtSecret='change-me-long-random' \
  --set store.driver=kubernetes \
  --set mysql.enabled=false \
  --set worker.enabled=false
```

Wait until pods are ready:

```bash
kubectl -n virtfoundry-system get pods -w
kubectl get crd | grep virtfoundry.io
```

Optional — set the CSI snapshot class used by the Volume Snapshots UI (Longhorn example):

```bash
helm upgrade virtfoundry virtfoundry/virtfoundry -n virtfoundry-system \
  --reuse-values \
  --set platform.storage.snapshotClass=longhorn
```

Empty `snapshotClass` uses the cluster default `VolumeSnapshotClass` when one is marked default.

---

## 2. Expose the UI (~5–10 min)

Pick **one** path.

### A. Port-forward (fastest)

```bash
kubectl -n virtfoundry-system port-forward svc/virtfoundry-ui 8080:80
```

Open http://127.0.0.1:8080

### B. Ingress / Gateway API

Use your cluster’s IngressClass or Gateway + HTTPRoute. Example values and Gateway notes: [Configuration](configuration.md), [Topologies](topologies.md).

---

## 3. First login (~1 min)

- **User:** `root`
- **Password:** the `secrets.rootPassword` you set (`change-me` above)

---

## 4. Deploy a first VM (~10 min)

In the UI (or API):

1. Open **Templates** — use a **container disk** template (no ISO download).
2. Open **Service offerings** — pick a small offering (or create one).
3. Create a **VM** from that template + offering.
4. Wait until the VM is **Running**, then open **Console** (noVNC).

!!! note "Networking"
    Full tenant VPC / Multus bridge demos need host bridges and often a public pool — [Kind](kind.md) for a laptop, [Topologies](topologies.md) on real nodes. Container-disk VMs can still prove the control plane without a full L2 lab.

---

## 5. Sanity checks

```bash
kubectl -n virtfoundry-system get deploy
kubectl get vf-instance -A
kubectl get vmsnapshot -A
kubectl get vm -A
```

API health (with port-forward or your hostname):

```bash
curl -sS http://127.0.0.1:8080/api/v1/healthz || true
```

---

## Next

| Topic | Doc |
|-------|-----|
| What you can do after login | [Features overview](features/index.md) |
| Full install + why each dependency | [Installation](installation.md) |
| Min vs production layouts | [Topologies](topologies.md) |
| Laptop (kind, no VLAN) | [Kind](kind.md) |
| Helm values (public net, snapshots) | [Configuration](configuration.md) |
| Why VirtFoundry vs Proxmox | [Why VirtFoundry](why.md) |
| Traction / CNCF checklist | [CNCF checklist](https://github.com/virtfoundry/core/blob/main/docs/CNCF-CHECKLIST.md) |

Questions: [GitHub Discussions](https://github.com/virtfoundry/core/discussions).
