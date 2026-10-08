# virtfoundry-operator

Helm chart for the [VirtFoundry operator](https://github.com/virtfoundry/operator) — installs the controller Deployment. The `virtfoundry.io/v1alpha1` CRDs come from the `virtfoundry-crds` chart: install it first.

Install **before** the `virtfoundry` chart.

## Prerequisites

- Kubernetes 1.28+
- KubeVirt (for Instance status sync from VirtualMachine / VMI)

## Install

```bash
helm repo add virtfoundry https://virtfoundry.github.io/helm-charts
helm repo update

helm install virtfoundry-crds virtfoundry/virtfoundry-crds \
  --namespace virtfoundry-system \
  --create-namespace
helm install virtfoundry-operator virtfoundry/virtfoundry-operator \
  --namespace virtfoundry-system
```

From a git clone:

```bash
helm install virtfoundry-crds ./charts/virtfoundry-crds \
  --namespace virtfoundry-system \
  --create-namespace
helm install virtfoundry-operator ./charts/virtfoundry-operator \
  --namespace virtfoundry-system
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

Other CRDs (from `virtfoundry-crds`) exist for API/GitOps use; additional controllers are tracked in the [core design spec](https://github.com/virtfoundry/core/blob/main/docs/superpowers/specs/2026-09-01-crd-operator-design.md).

## Permissions

The operator ClusterRole matches kubebuilder `config/rbac/role.yaml` for the controllers above:

- **virtfoundry.io:** tenants (CRUD), instances (get/list/watch/update/patch + status/finalizers), offerings/templates (read)
- **core:** namespaces (get/list/watch/create/patch/delete) for tenant namespaces
- **kubevirt.io:** virtualmachines / virtualmachineinstances (CRUD)
- **No Secrets**, NetPol, PVC, VolumeSnapshots, Multus NADs, CDI DataVolumes, KubeVirt snapshot APIs, or other virtfoundry.io kinds until a controller needs them. If Secrets are needed later, grant a `Role` in `virtfoundry-system` rather than widening the ClusterRole.
- **No `update` on Namespaces.** Tenant namespaces are `virtfoundry-tenant-{slug}`, so `resourceNames` cannot scope them (namespaces are cluster scoped and RBAC has no prefix matching). The Tenant reconciler instead refuses to adopt or delete any namespace it cannot prove it owns, by name prefix, `virtfoundry.io/tenant` label, ownerRef, and a UID precondition on delete. Namespace `delete` remains cluster-scoped in RBAC; the ValidatingAdmissionPolicy below is the extra guard.

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

## Where this chart lives

This directory is the only copy of the operator chart. The operator repository has the controller code and no chart.

A change to the operator's permissions takes two pull requests, in this order:

1. Here: add the rule to `templates/rbac.yaml`. Extra permission before the code that uses it is harmless.
2. In [`virtfoundry/operator`](https://github.com/virtfoundry/operator): add the `+kubebuilder:rbac` marker and the code.

Both repositories run the same check (`make verify-operator-chart-rbac` here, `make verify-chart-rbac` there). It fails when the chart's ClusterRole differs from what the controllers declare. To remove a permission, reverse the order: operator first, then here.
