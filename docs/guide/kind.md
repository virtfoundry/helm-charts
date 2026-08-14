# Kind (laptop lab)

Run VirtFoundry on your machine with [kind](https://kind.sigs.k8s.io/) (Kubernetes in Docker). **You do not need a VLAN, a managed switch, or MetalLB.**

This is the path for trying the UI and a first VM. Public guest IPs on your Wi-Fi are optional and come later on this page.

!!! tip "What “public” means here"
    On a homelab with a switch, public is often a dedicated VLAN. On kind it is either **off** (VMs on the pod network + noVNC in the UI) or a **second Docker network** that only your laptop can reach. Same Helm keys either way — see [Topologies — public underlay](topologies.md#public-network-underlay).

## What you need

| Tool | Notes |
|------|--------|
| [Docker](https://docs.docker.com/get-docker/) | Running |
| [kind](https://kind.sigs.k8s.io/docs/user/quick-start/#installation) | `kind version` |
| [kubectl](https://kubernetes.io/docs/tasks/tools/) + [Helm 3](https://helm.sh/docs/intro/install/) | |
| `/dev/kvm` | **Linux** — nested VMs are fast. **Docker Desktop (macOS/Windows)** usually has no KVM; use software emulation (slower). |

```bash
# Linux
test -e /dev/kvm && echo "KVM ok" || echo "No KVM — you will use emulation"
```

---

## 1. Create the cluster

Save as `kind-cluster.yaml` (or copy [`examples/kind-cluster.yaml`](https://github.com/virtfoundry/helm-charts/blob/main/charts/virtfoundry/examples/kind-cluster.yaml) from the chart repo).

```yaml
kind: Cluster
apiVersion: kind.x-k8s.io/v1alpha4
name: virtfoundry
nodes:
  - role: control-plane
    extraMounts:
      - hostPath: /dev/kvm
        containerPath: /dev/kvm
    extraPortMappings:
      - containerPort: 30880
        hostPort: 8080
        protocol: TCP
```

No `/dev/kvm`? Delete the `extraMounts` block.

```bash
kind create cluster --config kind-cluster.yaml
kubectl cluster-info --context kind-virtfoundry
```

Kind ships a `standard` StorageClass (`local-path`). Volume snapshots will **not** work; use **VM snapshots** in the UI.

---

## 2. Platform components

The Helm chart does **not** install KubeVirt, Multus, or CDI. From a [helm-charts](https://github.com/virtfoundry/helm-charts) clone:

```bash
export KUBECONFIG="${KUBECONFIG:-$HOME/.kube/config}"
./scripts/setup/multus.sh
./scripts/setup/kubevirt.sh
./scripts/setup/cdi.sh
```

Without KVM, turn on emulation **after** KubeVirt is Available:

```bash
kubectl -n kubevirt patch kubevirt kubevirt --type merge -p \
  '{"spec":{"configuration":{"developerConfiguration":{"useEmulation":true}}}}'
```

Wait until `kubectl get kubevirt -n kubevirt` shows `Available`.

---

## 3. Install VirtFoundry (public off)

Overlay [`values-kind.yaml`](https://github.com/virtfoundry/helm-charts/blob/main/charts/virtfoundry/values-kind.yaml): NodePort **30880** (mapped to host **8080**), `public.enabled: false`.

```bash
curl -fsSL https://raw.githubusercontent.com/virtfoundry/helm-charts/main/charts/virtfoundry/values-kind.yaml \
  -o values-kind.yaml

helm repo add virtfoundry https://virtfoundry.github.io/helm-charts
helm repo update

helm install virtfoundry virtfoundry/virtfoundry \
  --version 1.5.0 \
  --namespace virtfoundry-system --create-namespace \
  -f values-kind.yaml \
  --set secrets.rootPassword='change-me' \
  --set secrets.jwtSecret='change-me-long-random'
```

Open **http://127.0.0.1:8080** — user `root`, password `change-me`.

Deploy a **container-disk** VM (Templates → small offering → Console). The guest has a pod IP only; you reach it through **noVNC**, not from your LAN.

Isolated VPCs still work: bridge-keeper creates `virtfoundry-br0` **inside** the kind node. That L2 never leaves Docker.

---

## 4. Optional — local “public” IPs (still no VLAN)

Use this when you want a guest address you can `ping` from the **same laptop**, without a switch.

Kubernetes inside kind uses **`eth0`** on the kind Docker network. **Never** set that as `public.bridge.uplink` — bridge-keeper would steal the node IP and the cluster dies.

Add a **second** Docker network (this is the kind equivalent of a second NIC on a house LAN):

```bash
docker network create --driver bridge \
  --subnet 10.0.50.0/24 --gateway 10.0.50.1 \
  virtfoundry-pub

docker network connect virtfoundry-pub virtfoundry-control-plane

docker exec virtfoundry-control-plane ip -br addr
# eth0 = kind (kubelet)     ← do not touch
# eth1 = 10.0.50.x          ← public uplink
```

If the extra NIC is not `eth1`, use the name you see.

```yaml
# values-kind-public.yaml — merge with values-kind.yaml
platform:
  networking:
    public:
      enabled: true
      cidr: 10.0.50.0/24
      gateway: 10.0.50.1          # Docker bridge on your laptop
      dns:
        - 10.0.50.1
      ipPool:
        start: 10.0.50.10
        end: 10.0.50.99
      bridge:
        name: vf-pub0
        uplink: eth1              # extra NIC, not eth0
        address: 10.0.50.2/24     # host side of vf-pub0; not in the VM pool
```

```bash
helm upgrade virtfoundry virtfoundry/virtfoundry \
  --version 1.5.0 \
  -n virtfoundry-system \
  -f values-kind.yaml \
  -f values-kind-public.yaml \
  --reuse-values
```

Attach the **public** network on the VM (UI → Public / deploy with public IP). From the laptop:

```bash
ping -c 2 10.0.50.10    # first address in the pool, if allocated
```

Your phone on Wi-Fi will **not** see `10.0.50.0/24` unless you add a route. That is expected: kind public is local to Docker, like a lab VLAN that only exists on this machine.

!!! danger "Do not enslave eth0"
    `uplink: eth0` takes down kubelet inside the kind node. Recover with `kind delete cluster --name virtfoundry` and recreate.

---

## Cleanup

```bash
kind delete cluster --name virtfoundry
docker network rm virtfoundry-pub   # if you created it
```

## Next

| Goal | Doc |
|------|-----|
| First VM clicks | [Quickstart](quickstart.md) |
| Helm keys | [Configuration — public networking](configuration.md#public-networking) |
| VLAN vs house LAN on real nodes | [Topologies](topologies.md#public-network-underlay) |
| Why KubeVirt / Multus / CDI | [Installation](installation.md) |
