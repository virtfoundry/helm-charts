#!/usr/bin/env bash
# Synced from virtfoundry/operator hack/verify-chart-rbac.sh for helm-charts CI.
# Fails if the rendered operator ClusterRole drifts from Tenant+Instance+Network
# needs (kubebuilder config/rbac/role.yaml), regains cluster-wide Secret access,
# or if admission guards stop rendering on capable clusters.
#
# Source of truth: virtfoundry/operator hack/verify-chart-rbac.sh (synced here for CI).
set -euo pipefail

CHART_DIR="${CHART_DIR:-charts/virtfoundry-operator}"
VAP_API="admissionregistration.k8s.io/v1/ValidatingAdmissionPolicy"

# API groups / resource names that belong to future controllers, not the
# currently shipped Tenant / Instance / Network reconcile surface.
FORBIDDEN_PATTERNS=(
  'secrets'
  'persistentvolumeclaims'
  'volumesnapshots'
  'virtualmachinesnapshots'
  'virtualmachinerestores'
  'datavolumes'
  'users'
  'roles'
  'apikeys'
  'vpcs'
  'securitygroups'
  'disks'
  'disksnapshots'
  'instancesnapshots'
  'ipaddresses'
)

REQUIRED_SNIPPETS=(
  'resources: \["tenants"\]'
  'resources: \["instances"\]'
  'resources: \["offerings", "templates", "networks", "sshkeys"\]'
  'networks/status'
  'resources: \["network-attachment-definitions"\]'
  'resources: \["namespaces"\]'
  'resources: \["resourcequotas", "limitranges"\]'
  'resources: \["networkpolicies"\]'
  'resources: \["virtualmachines", "virtualmachineinstances"\]'
)

if ! command -v helm >/dev/null 2>&1; then
  echo "helm is required to verify the rendered chart RBAC" >&2
  exit 1
fi

# Comments are dropped so documentation mentioning secrets does not trip the check.
rbac="$(helm template virtfoundry-operator "$CHART_DIR" -s templates/rbac.yaml | sed 's/[[:space:]]*#.*$//')"

for pat in "${FORBIDDEN_PATTERNS[@]}"; do
  if grep -qw "$pat" <<<"$rbac"; then
    echo "FAIL: rendered ClusterRole still grants access to '$pat' (Tenant+Instance only)" >&2
    grep -n -B2 -w "$pat" <<<"$rbac" >&2
    exit 1
  fi
done
echo "OK: rendered ClusterRole has no future-controller / sprawl rules"

for snip in "${REQUIRED_SNIPPETS[@]}"; do
  if ! grep -Eq "$snip" <<<"$rbac"; then
    echo "FAIL: rendered ClusterRole missing required rule matching /$snip/" >&2
    exit 1
  fi
done
echo "OK: rendered ClusterRole covers Tenant + Instance + Network NAD (+ KubeVirt VMs/VMIs)"

# The ClusterRole cannot be scoped by resourceNames (tenant namespaces are
# virtfoundry-tenant-{slug}), so at least keep `update` off namespaces.
namespace_verbs="$(grep -A1 'resources: \["namespaces"\]' <<<"$rbac" | grep 'verbs:' || true)"
[[ -n "$namespace_verbs" ]] || { echo "FAIL: could not find a namespaces rule" >&2; exit 1; }
if grep -qw "update" <<<"$namespace_verbs"; then
  echo "FAIL: rendered ClusterRole grants update on namespaces (verbs: $namespace_verbs)" >&2
  exit 1
fi
echo "OK: rendered ClusterRole cannot update arbitrary namespaces"

guard="$(helm template virtfoundry-operator "$CHART_DIR" \
  -s templates/namespace-guard.yaml --api-versions "$VAP_API")"

if ! grep -q "kind: ValidatingAdmissionPolicy$" <<<"$guard"; then
  echo "FAIL: namespace deletion guard is not rendered on clusters serving $VAP_API" >&2
  exit 1
fi
echo "OK: namespace deletion guard renders on clusters serving ValidatingAdmissionPolicy"

admission="$(helm template virtfoundry-operator "$CHART_DIR" \
  -s templates/cr-admission.yaml --api-versions "$VAP_API")"

if ! grep -q "kind: ValidatingAdmissionPolicy$" <<<"$admission"; then
  echo "FAIL: CR admission policy is not rendered on clusters serving $VAP_API" >&2
  exit 1
fi
if ! grep -q "virtfoundry-tenant-" <<<"$admission"; then
  echo "FAIL: CR admission policy missing Instance tenant-namespace rule" >&2
  exit 1
fi
if ! grep -q "object.spec.cpu" <<<"$admission"; then
  echo "FAIL: CR admission policy missing Offering CPU/memory bounds" >&2
  exit 1
fi
echo "OK: CR admission policy renders Instance namespace + Offering bounds rules"
