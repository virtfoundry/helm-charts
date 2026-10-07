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

MANIFEST_URL="${MULTUS_MANIFEST_URL:-https://raw.githubusercontent.com/k8snetworkplumbingwg/multus-cni/v4.3.1/deployments/multus-daemonset-thick.yml}"
# The upstream manifest references the moving tag multus-cni:snapshot-thick, so a node that
# pulls it later can get a different image than the one you validated. Pin the immutable
# v4.3.1-thick image by digest (override with MULTUS_IMAGE, or set it empty to keep the manifest as is).
MULTUS_IMAGE="${MULTUS_IMAGE-ghcr.io/k8snetworkplumbingwg/multus-cni@sha256:a357a79359b80ddd5f4699117946cacf3b54f5baecf7944535594863e875fc25}"

render_manifest() {
  if [ -z "$MULTUS_IMAGE" ]; then
    curl -fsSL "$MANIFEST_URL"
    return
  fi
  curl -fsSL "$MANIFEST_URL" | sed "s#ghcr.io/k8snetworkplumbingwg/multus-cni:snapshot-thick#${MULTUS_IMAGE}#g"
}

echo "==> Kubeconfig: $KUBECONFIG"

if kubectl get ds -n kube-system kube-multus-ds >/dev/null 2>&1; then
  echo "==> Multus already installed"
elif [ "$ENSURE_ONLY" = true ]; then
  echo "ERROR: Multus not installed (run without --ensure-only to install)" >&2
  exit 1
else
  echo "==> Install Multus from upstream"
  render_manifest | kubectl apply -f -
fi

kubectl -n kube-system rollout status daemonset/kube-multus-ds --timeout=300s
echo "Multus OK"
