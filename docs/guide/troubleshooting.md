# Troubleshooting

Problems seen on real installs, with the fix.

## Volume snapshot fails: `the server could not find the requested resource`

The cluster has no `VolumeSnapshot` CRDs, or its StorageClass cannot snapshot (`local-path` cannot). Install the CSI external-snapshotter and a snapshot-capable class such as Longhorn, or use VM snapshots instead. Details: [Storage configuration](storage-config.md#snapshots-vm-vs-volume).

## Chart install fails to render

`secrets.rootPassword` (12+ chars) and `secrets.jwtSecret` (32+ chars) have no defaults. Pass both on the same `helm` command, or use `secrets.existingSecret`. See [Secrets](configuration.md#secrets).

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
