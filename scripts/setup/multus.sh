#!/usr/bin/env bash
# Install Multus CNI from upstream manifest (idempotent).
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
# shellcheck source=scripts/lib/common.sh
source "$SCRIPT_DIR/../lib/common.sh"
virtfoundry_source_common
virtfoundry_require_kubeconfig

ENSURE_ONLY=false
while [[ $# -gt 0 ]]; do
  case "$1" in
    --ensure-only)
      ENSURE_ONLY=true
      shift
      ;;
    -h | --help)
      echo "Usage: $0 [--ensure-only]"
      echo "  --ensure-only  Verify Multus is installed and healthy; do not install"
      exit 0
      ;;
    *)
      echo "Unknown option: $1" >&2
      exit 1
      ;;
  esac
done

MANIFEST_URL="${MULTUS_MANIFEST_URL:-https://raw.githubusercontent.com/k8snetworkplumbingwg/multus-cni/master/deployments/multus-daemonset-thick.yml}"

echo "==> Kubeconfig: $KUBECONFIG"

if kubectl get ds -n kube-system kube-multus-ds >/dev/null 2>&1; then
  echo "==> Multus already installed"
elif [ "$ENSURE_ONLY" = true ]; then
  echo "ERROR: Multus not installed (run without --ensure-only to install)" >&2
  exit 1
else
  echo "==> Install Multus from upstream"
  kubectl apply -f "$MANIFEST_URL"
fi

kubectl -n kube-system rollout status daemonset/kube-multus-ds --timeout=300s
echo "Multus OK"
