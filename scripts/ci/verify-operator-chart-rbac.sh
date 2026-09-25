#!/usr/bin/env bash
# PR / CI gate for charts/virtfoundry-operator (helm-charts#43, virtfoundry/operator#11).
# Fails if the rendered operator ClusterRole regains cluster-wide Secret access,
# if it can update arbitrary Namespaces, or if the namespace deletion guard stops
# rendering on clusters that serve ValidatingAdmissionPolicy.
#
# Keep in sync with virtfoundry/operator hack/verify-chart-rbac.sh — the operator
# repo is the source of truth for this chart.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
CHART="${CHART_DIR:-${ROOT}/charts/virtfoundry-operator}"
VAP_API="admissionregistration.k8s.io/v1/ValidatingAdmissionPolicy"

die() { echo "operator-chart-rbac: FAIL: $*" >&2; exit 1; }
ok() { echo "operator-chart-rbac: ok: $*"; }

command -v helm >/dev/null || die "helm not installed"
[[ -d "$CHART" ]] || die "chart not found at $CHART"

# Comments are dropped so documentation mentioning secrets does not trip the check.
rbac="$(helm template virtfoundry-operator "$CHART" -s templates/rbac.yaml | sed 's/[[:space:]]*#.*$//')" \
  || die "helm template of templates/rbac.yaml failed"

if grep -qw "secrets" <<<"$rbac"; then
  echo "operator-chart-rbac: offending rules:" >&2
  grep -n -B2 -w "secrets" <<<"$rbac" >&2
  die "rendered ClusterRole grants access to secrets"
fi
ok "rendered ClusterRole has no secrets rule"

# The ClusterRole cannot be scoped by resourceNames (tenant namespaces are
# virtfoundry-tenant-{slug}), so at least keep `update` off namespaces.
namespace_verbs="$(grep -A1 'resources: \["namespaces"\]' <<<"$rbac" | grep 'verbs:' || true)"
[[ -n "$namespace_verbs" ]] || die "could not find a namespaces rule in the rendered ClusterRole"
if grep -qw "update" <<<"$namespace_verbs"; then
  die "rendered ClusterRole grants update on namespaces (verbs: $namespace_verbs)"
fi
ok "rendered ClusterRole cannot update arbitrary namespaces"

# `helm -s` also errors when the template exists but renders nothing (guard
# disabled by default), so both cases collapse into one failure message.
guard="$(helm template virtfoundry-operator "$CHART" \
  -s templates/namespace-guard.yaml --api-versions "$VAP_API" 2>/dev/null || true)"

grep -q "kind: ValidatingAdmissionPolicy$" <<<"$guard" \
  || die "namespace deletion guard must render on clusters serving $VAP_API" \
         "(templates/namespace-guard.yaml missing, empty, or namespaceGuard.enabled defaults to false)"
ok "namespace deletion guard renders on clusters serving ValidatingAdmissionPolicy"

# Published chart: must still install on Kubernetes < 1.30, which has no
# ValidatingAdmissionPolicy API.
legacy="$(helm template virtfoundry-operator "$CHART" 2>/dev/null || true)"
if grep -q "kind: ValidatingAdmissionPolicy$" <<<"$legacy"; then
  die "namespace guard rendered on a cluster without $VAP_API (chart would fail to install)"
fi
ok "namespace deletion guard is skipped on clusters without ValidatingAdmissionPolicy"

ok "all operator chart RBAC gates passed"
