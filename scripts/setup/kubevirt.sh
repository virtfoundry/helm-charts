#!/usr/bin/env bash
# Install KubeVirt on the target cluster (idempotent).
# https://kubevirt.io/quickstart_cloud/
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
# shellcheck source=scripts/lib/common.sh
source "$SCRIPT_DIR/../lib/common.sh"
virtfoundry_source_common

KUBE_CONTEXT="${KUBE_CONTEXT:-$(kubectl config current-context 2>/dev/null || echo homelab)}"

echo "=== KubeVirt — context: $KUBE_CONTEXT ==="
kubectl config use-context "$KUBE_CONTEXT"

if kubectl get kubevirt.kubevirt.io/kubevirt -n kubevirt &>/dev/null; then
  echo "KubeVirt already installed — skipping"
else
  VERSION="$(curl -fsSL https://storage.googleapis.com/kubevirt-prow/release/kubevirt/kubevirt/stable.txt)"
  echo "Stable version: $VERSION"
  kubectl create -f "https://github.com/kubevirt/kubevirt/releases/download/${VERSION}/kubevirt-operator.yaml"
  kubectl create -f "https://github.com/kubevirt/kubevirt/releases/download/${VERSION}/kubevirt-cr.yaml"
  echo "Waiting for KubeVirt..."
  kubectl -n kubevirt wait --for=condition=Available kubevirt.kubevirt.io/kubevirt --timeout=600s
fi

kubectl get kubevirt.kubevirt.io/kubevirt -n kubevirt -o=jsonpath="{.status.phase}{'\n'}"
kubectl get all -n kubevirt

echo ""
echo "Local API against this cluster:"
echo "  kubectl config use-context $KUBE_CONTEXT"
if [ -n "${APP_ROOT:-}" ]; then
  echo "  cd $APP_ROOT && ROOT_PASSWORD=virtfoundry go run ./cmd/server"
  echo "  UI dev: cd $APP_ROOT/ui && npm run dev"
fi
