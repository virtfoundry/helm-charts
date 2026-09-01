# virtfoundry-operator

Helm chart for the [VirtFoundry operator](https://github.com/virtfoundry/operator) — installs `virtfoundry.io/v1alpha1` CRDs and the controller Deployment.

Install **before** the `virtfoundry` chart when using `store.driver=kubernetes`.

## Prerequisites

- Kubernetes 1.28+
- KubeVirt (for Instance status sync from VirtualMachine / VMI)

## Install

```bash
helm repo add virtfoundry https://virtfoundry.github.io/helm-charts
helm repo update

helm install virtfoundry-operator virtfoundry/virtfoundry-operator \
  --namespace virtfoundry-system \
  --create-namespace
```

From a git clone:

```bash
helm install virtfoundry-operator ./charts/virtfoundry-operator \
  --namespace virtfoundry-system \
  --create-namespace
```

Then install the API/UI chart with the [kubernetes store profile](../virtfoundry/values-kubernetes.yaml).

## Verify

```bash
kubectl get crd | grep virtfoundry.io
kubectl get vf-tenant
kubectl get pods -n virtfoundry-system -l app.kubernetes.io/part-of=virtfoundry
```

## Controllers (today)

| Kind | Reconciler |
|------|------------|
| Tenant | Namespace + Ready status |
| Instance | KubeVirt VM/VMI → `status.phase`, `status.ip` |

Other CRDs are installed for API/GitOps use; additional controllers are tracked in the [core design spec](https://github.com/virtfoundry/core/blob/main/docs/superpowers/specs/2026-09-01-crd-operator-design.md).

## Docs

[Installation guide](https://virtfoundry.github.io/helm-charts/docs/guide/installation/)
