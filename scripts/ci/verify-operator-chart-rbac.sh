#!/usr/bin/env bash
# Runs the operator's own RBAC check against the chart in this repository.
#
# The chart lives here only (charts/virtfoundry-operator). The check lives in
# virtfoundry/operator (hack/verify-chart-rbac.sh), next to the ClusterRole that
# controller-gen writes from the kubebuilder markers: it fails when the chart grants
# less, more, or something else than the controllers need.
#
# OPERATOR_DIR points at an operator checkout; otherwise operator main is cloned.
# Needs helm and Go (the comparison tool is a small Go program in the operator repo).
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
command -v go >/dev/null 2>&1 || { echo "go is required: the RBAC comparison runs from the operator repository" >&2; exit 1; }

if [[ -z "${OPERATOR_DIR:-}" ]]; then
  OPERATOR_DIR="$(mktemp -d)"
  trap 'rm -rf "${OPERATOR_DIR}"' EXIT
  git clone --quiet --depth 1 --branch "${OPERATOR_REF:-main}" \
    "${OPERATOR_REPO:-https://github.com/virtfoundry/operator.git}" "${OPERATOR_DIR}"
fi
OPERATOR_DIR="$(cd "${OPERATOR_DIR}" && pwd)"

cd "${OPERATOR_DIR}"
CHART_DIR="${ROOT}/charts/virtfoundry-operator" ./hack/verify-chart-rbac.sh
