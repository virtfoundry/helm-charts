#!/usr/bin/env bash
# Fails when charts/virtfoundry-operator drifts from its source of truth,
# virtfoundry/operator charts/virtfoundry-operator. The mirror had drifted
# silently before (helm-charts#85): image.requireDigest was accepted but ignored.
#
# README.md is exclusive to this repo and ignored. OPERATOR_CHART_DIR points at a
# local operator checkout; otherwise operator main is cloned shallowly.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
MIRROR="${ROOT}/charts/virtfoundry-operator"
REPO="${OPERATOR_REPO:-https://github.com/virtfoundry/operator.git}"
REF="${OPERATOR_REF:-main}"

if [[ -n "${OPERATOR_CHART_DIR:-}" ]]; then
  SOURCE="${OPERATOR_CHART_DIR}"
else
  TMP="$(mktemp -d)"
  trap 'rm -rf "${TMP}"' EXIT
  git clone --quiet --depth 1 --branch "${REF}" "${REPO}" "${TMP}/operator"
  SOURCE="${TMP}/operator/charts/virtfoundry-operator"
fi

if diff -rq -x README.md "${SOURCE}" "${MIRROR}"; then
  echo "OK: charts/virtfoundry-operator matches operator ${REF}"
else
  echo "FAIL: charts/virtfoundry-operator drifted from virtfoundry/operator ${REF}." >&2
  echo "Sync it from the source of truth (keep README.md) instead of editing the mirror." >&2
  exit 1
fi
