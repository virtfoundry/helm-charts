# Platform prerequisites

Install these **before** `virtfoundry-operator` and `virtfoundry`. VirtFoundry does not bundle hypervisor or CNI operators — pin versions to match your Kubernetes distro.

**Recommended order:** Kubernetes → storage → KubeVirt → Multus → CDI → (optional) MetalLB / snapshot CRDs → **virtfoundry-crds** → **virtfoundry-operator** → **virtfoundry** → (optional) Kamaji + **virtfoundry-vks**.

## Required

| Component | Docs | Verify |
|-----------|------|--------|
| **Kubernetes** 1.28+ | [kubernetes.io/docs/setup](https://kubernetes.io/docs/setup/) | `kubectl version` |
| **[KubeVirt](https://kubevirt.io/)** | [Quickstart](https://kubevirt.io/quickstart/) · [User guide](https://kubevirt.io/user-guide/) | `kubectl get pods -n kubevirt` · `kubectl get crd virtualmachines.kubevirt.io` |
| **[Multus CNI](https://github.com/k8snetworkplumbingwg/multus-cni)** | [Installation](https://github.com/k8snetworkplumbingwg/multus-cni/blob/master/docs/install.md) · [How to use](https://github.com/k8snetworkplumbingwg/multus-cni/blob/master/docs/how-to-use.md) | `kubectl get pods -n kube-system -l app=multus` · `kubectl get crd network-attachment-definitions.k8s.cni.cncf.io` |
| **[CDI](https://github.com/kubevirt/containerized-data-importer)** (ISO/import templates) | [Installing CDI](https://github.com/kubevirt/containerized-data-importer/blob/main/doc/install.md) · [KubeVirt lab](https://kubevirt.io/labs/kubernetes/vm-image.html) | `kubectl get pods -n cdi` · `kubectl get crd datavolumes.cdi.kubevirt.io` |
| **StorageClass** ([Longhorn](https://longhorn.io/docs/latest/deploy/install/) recommended) | [Longhorn install](https://longhorn.io/docs/latest/deploy/install/install-with-helm/) | `kubectl get sc` |
| **virtfoundry-operator** | [Installation](installation.md) | `kubectl get crd tenants.virtfoundry.io` |

## Bundled by the chart

The `virtfoundry` chart installs the following as a **subchart** by default. Set `metrics-server.enabled: false` in your `values.yaml` if your cluster already provides it (AKS / EKS / GKE ship it pre-installed).

| Component | Why | Notes |
|-----------|-----|-------|
| **[metrics-server](https://github.com/kubernetes-sigs/metrics-server)** | Surfaces `metrics.k8s.io` so the dashboard **Cluster overview** can show real CPU and memory usage (Tier 2). The homelab / kind overlay (`-f values-kind.yaml`) appends `--kubelet-insecure-tls` so the metrics-server can scrape kubelets whose serving cert does not chain back to the cluster CA. | Always pinned to `~3.12.0` in the parent chart's `dependencies` block. Override the version through a `helm dependency update` if you need a different minor. |

## Recommended

| Component | Docs | When |
|-----------|------|------|
| **[CSI external-snapshotter](https://github.com/kubernetes-csi/external-snapshotter)** | [Installation](https://github.com/kubernetes-csi/external-snapshotter#installation) | Volume snapshots (Longhorn includes snapshot class) |
| **[MetalLB](https://metallb.universe.tf/)** | [Installation](https://metallb.universe.tf/installation/) | Bare-metal LoadBalancer Services / tenant L4 VIPs |
| **Ingress** or **[Gateway API](https://gateway-api.sigs.k8s.io/)** | [Ingress-NGINX](https://kubernetes.github.io/ingress-nginx/deploy/) · [Gateway API guides](https://gateway-api.sigs.k8s.io/guides/) | Expose UI + API on a hostname |

## Optional: Kubernetes clusters (VKS)

Only needed if tenants will create managed Kubernetes clusters ([VKS](features/vks.md)).

| Component | Docs | Notes |
|-----------|------|-------|
| **[Kamaji](https://kamaji.clastix.io/)** | [Getting started](https://kamaji.clastix.io/getting-started/) | Hosts each tenant control plane. Apply its CRDs with server-side apply and create a `DataStore`; without it `.status.ready` never appears |
| **MetalLB** (or cloud LB) | [Installation](https://metallb.universe.tf/installation/) | Default control-plane Service is `LoadBalancer`; needs an address pool |
| **Node image reachable** | [VKS node image](features/vks.md#node-image) | Nodes pull `ghcr.io/virtfoundry/node-ubuntu` (or your mirror) |

Kubernetes version of tenant clusters is capped by the Kamaji release (for example Kamaji `26.9.5-edge` accepts up to `v1.37.0`).

## Not used

VirtFoundry **does not** require MySQL, Vitess, or an async worker. Platform state is stored in **`virtfoundry.io` CRDs** (`store.driver=kubernetes`).

## Laptop / CI

| Path | Guide |
|------|-------|
| Kind (no VLAN) | [Kind](kind.md) |
| Under 30 min | [Quickstart](quickstart.md) |
| Production-style homelab | [Topologies](topologies.md) |

## Upstream version pins (reference)

Check upstream release notes before upgrading. Homelab has been validated with:

- Kubernetes 1.28+
- KubeVirt 1.4.x / 1.5.x
- Multus 4.x (thin plugin deployment)
- CDI 1.61+
- Longhorn 1.6+

After prerequisites are green, continue with [Installation](installation.md).
