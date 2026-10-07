# Quickstart (under 30 minutes)

Goal: **UI login + first VM**. On a laptop, start with **[Kind](kind.md)** (Docker, no VLAN). On a cluster that already has Kubernetes, KubeVirt, Multus, and CDI, continue below.

If you still need to install those platform components, see **[Platform prerequisites](prerequisites.md)** (official KubeVirt, Multus, CDI links) or the full [Installation](installation.md) guide.

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

# CRDs, then the operator (required)
helm install virtfoundry-crds virtfoundry/virtfoundry-crds \
  --version 0.11.3 \
  --namespace virtfoundry-system --create-namespace
helm install virtfoundry-operator virtfoundry/virtfoundry-operator \
  --version 0.11.3 \
  --namespace virtfoundry-system

# API + UI
helm install virtfoundry virtfoundry/virtfoundry \
  --version 0.11.3 \
  --namespace virtfoundry-system \
  --set secrets.rootPassword='choose-a-strong-password' \
  --set secrets.jwtSecret="$(openssl rand -hex 32)"
```

Wait until pods are ready:

```bash
kubectl -n virtfoundry-system get pods -w
kubectl get crd | grep virtfoundry.io
```

!!! note "Helm `--set` is not optional for secrets"
    `secrets.rootPassword` (12+ chars) and `secrets.jwtSecret` (32+ chars) must be passed on **this same** `helm install` (or via `-f`, or replaced by `secrets.existingSecret`). The chart has no defaults for them and the install fails without them — see [Secrets](configuration.md#secrets). They are chart values, not extra kubectl steps. Public CIDR and StorageClass do **not** need `--set` on a typical homelab: storage `auto` selects Longhorn when present; public stays off unless you enable it. Details: [Chart values](chart-values.md).

Optional — pin the CSI snapshot class (only if auto did not pick Longhorn):

```bash
helm upgrade virtfoundry virtfoundry/virtfoundry -n virtfoundry-system \
  --reuse-values \
  --set platform.storage.snapshotClass=longhorn
```

Empty `snapshotClass` uses Longhorn when that is the resolved default class, otherwise the cluster default `VolumeSnapshotClass`.

---

## 2. Expose the UI (~5–10 min)

Pick **one** path.

=== "Port-forward (fastest)"

    ```bash
    kubectl -n virtfoundry-system port-forward svc/virtfoundry-ui 8080:80
    ```

    Open http://127.0.0.1:8080

=== "Ingress / Gateway API"

    Use your cluster’s IngressClass or Gateway + HTTPRoute. Example values and Gateway notes: [Configuration](configuration.md), [Topologies](topologies.md).

---

## 3. First login (~1 min)

- **User:** `root`
- **Password:** the `secrets.rootPassword` you set (`choose-a-strong-password` above)

---

## 4. Deploy a first VM (~10 min)

In the UI (or API):

1. Open **SSH Keys** and generate a key. Linux VMs need one, and a fresh install has none. The private key is shown **once**: save it.
2. Open **Templates** — use a **container disk** template such as `cirros` (no ISO download).
3. Open **Service offerings** — pick a small offering (or create one).
4. Create a **VM** from that template + offering, with your SSH key and the default isolated network.
5. Wait until the VM is **Running** (the panel shows its IP), then open **Console** (noVNC).

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
curl -fsS http://127.0.0.1:8080/api/v1/healthz
# {"status":"ok","service":"virtfoundry-iaas","hypervisor":"kubevirt"}
```

!!! note "`/health` on the UI address is not the API"
    The UI proxy forwards only `/api/` and `/ws/`. Any other path, including `/health`, falls back to the UI page and returns 200 without testing anything. Use `/api/v1/healthz` (0.11.3 and newer). On 0.11.2 and older, port-forward the API service instead: `kubectl -n virtfoundry-system port-forward svc/virtfoundry-api 8081:8080` and `curl http://127.0.0.1:8081/health`.

---

## Next

| Topic | Doc |
|-------|-----|
| What you can do after login | [Features overview](features/index.md) |
| Full install + why each dependency | [Installation](installation.md) |
| Min vs production layouts | [Topologies](topologies.md) |
| Laptop (kind, no VLAN) | [Kind](kind.md) |
| Helm values (public net, snapshots, **defaults**) | [Configuration](configuration.md) · [Chart values](chart-values.md) |
| Why VirtFoundry vs Proxmox | [Why VirtFoundry](why.md) |
| Traction / CNCF checklist | [CNCF checklist](https://github.com/virtfoundry/core/blob/main/docs/CNCF-CHECKLIST.md) |

Questions: [GitHub Discussions](https://github.com/virtfoundry/core/discussions).
