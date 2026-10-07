# Troubleshooting

Problems seen on real installs, with the fix.

## Volume snapshot fails: `the server could not find the requested resource`

The cluster has no `VolumeSnapshot` CRDs, or its StorageClass cannot snapshot (`local-path` cannot). Install the CSI external-snapshotter and a snapshot-capable class such as Longhorn, or use VM snapshots instead. Details: [Storage configuration](storage-config.md#snapshots-vm-vs-volume).

## Chart install fails to render

`secrets.rootPassword` (12+ chars) and `secrets.jwtSecret` (32+ chars) have no defaults. Pass both on the same `helm` command, or use `secrets.existingSecret`. See [Secrets](configuration.md#secrets).

## `helm install virtfoundry` fails with `failed post-install: timed out waiting for the condition`

The `virtfoundry` chart runs a post-install Job (`virtfoundry-kubevirt-config`) that patches the KubeVirt CR (CPU allocation ratio, feature gates). Without KubeVirt installed, the Job never succeeds and Helm gives up after about five minutes.

Install KubeVirt first ([Platform prerequisites](prerequisites.md)), or skip the Job on a cluster where you manage KubeVirt yourself:

```bash
helm upgrade --install virtfoundry virtfoundry/virtfoundry -n virtfoundry-system \
  --set platform.kubevirt.cpuAllocationRatio=0 \
  --set platform.kubevirt.featureGates.enabled=false \
  --set-string secrets.rootPassword='...' --set-string secrets.jwtSecret='...'
```

A failed install leaves a `failed` release; run `helm uninstall virtfoundry -n virtfoundry-system` before installing again.

## Pods stay in `ContainerCreating` with `FailedCreatePodSandBox`

Events on the pod read `Failed to create pod sandbox: ... DeadlineExceeded` or `failed to reserve sandbox name ... is reserved for ...`, and **any** new pod on the node hangs, including a plain `pause` pod. Running pods are not affected.

The usual cause is the **Multus thick daemon** (`kube-multus-ds`) being throttled by its own API client. Every CNI request waits for a pod lookup; the kubelet keeps resending the request for each pod it cannot start, and the backlog never drains. Check the daemon on the affected node:

```bash
kubectl -n kube-system logs <kube-multus-ds-pod-on-that-node> --since=10m \
  | grep -E "client-side throttling|error waiting for pod|rate limiter"
```

Restart that one pod. It runs with `hostNetwork`, so it comes back even while the CNI is broken, and running workloads keep their network:

```bash
kubectl -n kube-system delete pod <kube-multus-ds-pod-on-that-node>
```

Pending pods start on the kubelet's next retry, within a couple of minutes.

To avoid it: do not roll many Deployments at the same time on a single worker (for example, merging several dependency updates in a row), and pin the Multus image by digest. The upstream manifest used by `scripts/setup/multus.sh` references the moving tag `snapshot-thick`.

## Tenant API keys fail to authenticate

The tenant namespace is missing from `rbac.api.secretNamespaces`, so the API cannot store the key Secret. Add the namespace ([Configuration](configuration.md#rbac-api-permissions)).

## New CRD field is ignored after a chart upgrade

Helm does not upgrade CRDs on later installs ([CRDs and upgrades](crds.md)). Apply them by hand:

```bash
kubectl apply --server-side --force-conflicts -f charts/virtfoundry-crds/manifests/   # charts/virtfoundry-operator/crds/ on 0.10.x
```

## VM has no isolated network (Multus)

- The host bridge DaemonSet is off by default. Set `platform.networking.isolated.enabled: true` ([Host bridges](networking-config.md#host-bridges-isolated-public)).
- On Kind or single-node clusters, set `bridge.tolerations: [{operator: Exists}]`.
- Multus NADs use the CNI `bridge` plugin. The node must have the containernetworking `bridge` binary.
- For guest-to-VIP traffic from an isolated bridge, the host needs an address on the bridge (for example `10.0.0.1`) plus MASQUERADE.

## KubeVirt on Kind

Kind nodes run containerd without ImageVolume support, so containerDisk init fails. Disable the gate:

```bash
kubectl -n kubevirt patch kubevirt kubevirt --type merge -p \
  '{"spec":{"configuration":{"developerConfiguration":{"disabledFeatureGates":["ImageVolume"]}}}}'
```

KubeVirt does not work on Kind under macOS. Use a Linux host ([Kind guide](kind.md)).

## VKS cluster stays `Provisioning`

- Kubernetes version and node template must match (`ubuntu-node-1-36-5` pairs with `v1.36.5`).
- Kamaji `DataStore` needs its CRDs applied with server-side apply, or `.status.ready` never appears.
- A `LoadBalancer` control plane needs a VIP: check `kubectl get svc` for a pending external IP and the MetalLB pool ([VKS](features/vks.md#control-plane-address)).
- The tenant namespace needs the `virtfoundry.io/tenant` label.
