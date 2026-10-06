#!/usr/bin/env bash
# charts/virtfoundry-crds must match its sources of truth (operator CRDs + the VKS CRD)
# and render every CRD protected from `helm uninstall` (resource-policy keep) and Argo prune. Needs network unless
# OPERATOR_DIR / VKS_DIR point at local checkouts.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
CHART="${ROOT}/charts/virtfoundry-crds"
TMP="$(mktemp -d)"
trap 'rm -rf "${TMP}"' EXIT

DEST="${TMP}/expected" OPERATOR_DIR="${OPERATOR_DIR:-}" VKS_DIR="${VKS_DIR:-}" \
  bash "${ROOT}/scripts/crds/sync-crds-chart.sh" >/dev/null
if ! diff -rq "${TMP}/expected" "${CHART}/manifests"; then
  echo "FAIL: charts/virtfoundry-crds/manifests drifted from operator/vks." >&2
  echo "Run scripts/crds/sync-crds-chart.sh and commit the result." >&2
  exit 1
fi
echo "OK: manifests match operator and vks"

helm lint "${CHART}" >/dev/null
rendered="$(helm template crds "${CHART}")"
total="$(grep -c '^kind: CustomResourceDefinition' <<<"${rendered}")"
kept="$(grep -c 'helm.sh/resource-policy: keep' <<<"${rendered}")"
argo="$(grep -c 'argocd.argoproj.io/sync-options: Prune=false,Delete=false' <<<"${rendered}")"
if [[ "${total}" -eq 0 || "${total}" -ne "${kept}" || "${total}" -ne "${argo}" ]]; then
  echo "FAIL: of ${total} CRDs, ${kept} have resource-policy keep and ${argo} have the Argo Prune/Delete=false option" >&2
  exit 1
fi
echo "OK: ${total} CRDs, all protected from helm uninstall and Argo prune"
