# virtfoundry-operator

Helm chart for the [VirtFoundry operator](https://github.com/virtfoundry/operator) — installs `virtfoundry.io/v1alpha1` CRDs and the controller Deployment.

Install **before** the `virtfoundry` chart.

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

Then install the API/UI chart (`virtfoundry`).

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

## Permissions

The operator ClusterRole is scoped to what the controllers above actually reconcile:

- **No Secrets.** No controller reads or writes Secrets. If one ever needs to, grant a `Role` in `virtfoundry-system` rather than widening the ClusterRole.
- **No `update` on Namespaces.** Tenant namespaces are `virtfoundry-tenant-{slug}`, so `resourceNames` cannot scope them (namespaces are cluster scoped and RBAC has no prefix matching). The Tenant reconciler instead refuses to adopt or delete any namespace it cannot prove it owns, by name prefix, `virtfoundry.io/tenant` label, ownerRef, and a UID precondition on delete.

### Namespace deletion guard

`namespaceGuard.enabled` (default `true`) installs a `ValidatingAdmissionPolicy` that denies the operator ServiceAccount any Namespace `DELETE` outside `virtfoundry-tenant-*` labelled `virtfoundry.io/tenant`. Humans and other controllers keep whatever their own RBAC allows.

It renders only on clusters serving `admissionregistration.k8s.io/v1` policies (Kubernetes 1.30+), so the chart still installs on older clusters — there the ownership guard in the reconciler is the only protection.

```bash
# Opt out (not recommended) on clusters where you manage the policy yourself
helm install virtfoundry-operator virtfoundry/virtfoundry-operator \
  --set namespaceGuard.enabled=false
```

## Docs

[Installation guide](https://virtfoundry.github.io/helm-charts/docs/guide/installation/)
