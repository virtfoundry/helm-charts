#!/usr/bin/env bash
# Install CDI (Containerized Data Importer) for ISO/DataVolume imports (idempotent).
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
# shellcheck source=scripts/lib/common.sh
source "$SCRIPT_DIR/../lib/common.sh"
virtfoundry_source_common

KUBE_CONTEXT="${KUBE_CONTEXT:-$(kubectl config current-context)}"

echo "==> Context: $KUBE_CONTEXT"
kubectl config use-context "$KUBE_CONTEXT"

if kubectl get cdi cdi -n cdi &>/dev/null; then
  echo "==> CDI already installed"
  kubectl -n cdi get pods
  exit 0
fi

echo "TIP: CDI can also be installed via Helm hook: platform.cdi.install=true"

VERSION="${CDI_VERSION:-$(curl -fsSL https://api.github.com/repos/kubevirt/containerized-data-importer/releases/latest | grep '"tag_name"' | head -1 | cut -d'"' -f4)}"
echo "==> Installing CDI $VERSION"

kubectl apply -f "https://github.com/kubevirt/containerized-data-importer/releases/download/${VERSION}/cdi-operator.yaml"
kubectl apply -f "https://github.com/kubevirt/containerized-data-importer/releases/download/${VERSION}/cdi-cr.yaml"

echo "==> Waiting for CDI..."
kubectl -n cdi wait --for=condition=Available cdi/cdi --timeout=300s
kubectl -n cdi rollout status deployment/cdi-deployment --timeout=300s
kubectl -n cdi get pods
echo "==> CDI ready"
