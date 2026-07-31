#!/bin/bash
# Install KubeVirt on homelab — https://kubevirt.io/quickstart_cloud/
# Does not remove existing cluster resources.
set -euo pipefail

KUBE_CONTEXT="${KUBE_CONTEXT:-homelab}"

echo "=== KubeVirt quickstart — $KUBE_CONTEXT ==="
kubectl config use-context "$KUBE_CONTEXT"

if kubectl get kubevirt.kubevirt.io/kubevirt -n kubevirt &>/dev/null; then
  echo "KubeVirt already installed — skipping"
else
  VERSION=$(curl -s https://storage.googleapis.com/kubevirt-prow/release/kubevirt/kubevirt/stable.txt)
  echo "Stable version: $VERSION"
  kubectl create -f "https://github.com/kubevirt/kubevirt/releases/download/${VERSION}/kubevirt-operator.yaml"
  kubectl create -f "https://github.com/kubevirt/kubevirt/releases/download/${VERSION}/kubevirt-cr.yaml"
  echo "Waiting for KubeVirt..."
  kubectl -n kubevirt wait --for=condition=Available kubevirt.kubevirt.io/kubevirt --timeout=600s
fi

kubectl get kubevirt.kubevirt.io/kubevirt -n kubevirt -o=jsonpath="{.status.phase}{'\n'}"
kubectl get all -n kubevirt

echo ""
echo "Local API against homelab cluster:"
echo "  kubectl config use-context $KUBE_CONTEXT"
echo "  cd ../virtforge && ROOT_PASSWORD=nimbus go run ./cmd/server"
echo ""
echo "UI dev: cd ../virtforge/ui && npm run dev — login root/nimbus"
