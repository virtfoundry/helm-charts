#!/usr/bin/env bash
# Deploy VirtFoundry to homelab via Gateway API HTTPRoute.
# Builds images locally; pushes to GHCR when possible, otherwise sideloads into containerd.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
# shellcheck source=scripts/lib/common.sh
source "$SCRIPT_DIR/../lib/common.sh"
virtfoundry_source_common
virtfoundry_require_chart
virtfoundry_require_kubeconfig

RELEASE="${RELEASE:-virtfoundry}"
DNS_HOST="${DNS_HOST:-virtfoundry.homelab}"
PLATFORM="${PLATFORM:-linux/amd64}"
BUILD_IMAGES="${BUILD_IMAGES:-true}"
PUSH_IMAGES="${PUSH_IMAGES:-true}"
REGISTRY="${REGISTRY:-ghcr.io/virtfoundry}"
IMAGE_TAG="${IMAGE_TAG:-latest}"
IMPORT_POD="virtfoundry-image-import"
IMPORT_NS="virtfoundry-system"
IMPORT_MANIFEST="${IMPORT_MANIFEST:-$SCRIPTS_DIR/sideload/import-pod.yaml}"
IMPORT_NODE="${IMPORT_NODE:?IMPORT_NODE is required for sideload (e.g. worker-01)}"
IMPORT_NODE_IP="${IMPORT_NODE_IP:-}"
LOCAL_REGISTRY="${LOCAL_REGISTRY:-docker.io/virtfoundry}"
USE_SIDELOAD="${USE_SIDELOAD:-false}"

if [ ! -d "$APP_ROOT/docker" ]; then
  echo "ERROR: virtfoundry app repo not found at APP_ROOT=$APP_ROOT" >&2
  echo "Clone https://github.com/virtfoundry/core next to this repo or set APP_ROOT" >&2
  exit 1
fi

echo "==> Kubeconfig: $KUBECONFIG"
kubectl get nodes

if [ "${INSTALL_MULTUS:-false}" = "true" ]; then
  "$SCRIPT_DIR/../setup/multus.sh"
fi

if [ "$BUILD_IMAGES" = "true" ]; then
  echo "==> Build images ($PLATFORM)"
  docker buildx build --platform "$PLATFORM" \
    -t "${REGISTRY}/core:${IMAGE_TAG}" \
    -t "${LOCAL_REGISTRY}/core:${IMAGE_TAG}" \
    -f "$APP_ROOT/docker/Dockerfile" "$APP_ROOT" --load
  docker buildx build --platform "$PLATFORM" \
    -t "${REGISTRY}/ui:${IMAGE_TAG}" \
    -t "${LOCAL_REGISTRY}/ui:${IMAGE_TAG}" \
    -f "$APP_ROOT/docker/Dockerfile.ui" "$APP_ROOT" --load

  if [ "$PUSH_IMAGES" = "true" ]; then
    echo "==> Push to $REGISTRY"
    if echo "$(gh auth token)" | docker login ghcr.io -u "$(gh api user -q .login)" --password-stdin \
      && docker push "${REGISTRY}/core:${IMAGE_TAG}" \
      && docker push "${REGISTRY}/ui:${IMAGE_TAG}"; then
      echo "==> Images pushed to GHCR"
      USE_SIDELOAD="false"
    else
      echo "WARN: GHCR push failed — falling back to containerd sideload"
      USE_SIDELOAD="true"
    fi
  fi
fi

if [ "$BUILD_IMAGES" = "false" ] && docker image inspect "${LOCAL_REGISTRY}/core:${IMAGE_TAG}" >/dev/null 2>&1; then
  USE_SIDELOAD="true"
fi

IMAGE_API="${REGISTRY}/core:${IMAGE_TAG}"
IMAGE_UI="${REGISTRY}/ui:${IMAGE_TAG}"
PULL_POLICY="IfNotPresent"

if [ "$USE_SIDELOAD" = "true" ]; then
  IMAGE_API="${LOCAL_REGISTRY}/core:${IMAGE_TAG}"
  IMAGE_UI="${LOCAL_REGISTRY}/ui:${IMAGE_TAG}"
  PULL_POLICY="Never"
fi

echo "==> Helm upgrade (Gateway HTTPRoute + platform bootstrap)"
helm upgrade --install "$RELEASE" "$CHART_DIR" \
  -n virtfoundry-system --create-namespace \
  -f "$CHART_DIR/values-homelab.yaml" \
  --set "images.api=${IMAGE_API}" \
  --set "images.worker=${IMAGE_API}" \
  --set "images.ui=${IMAGE_UI}" \
  --set "images.pullPolicy=${PULL_POLICY}" \
  --timeout 10m

echo "==> Wait for MySQL"
kubectl -n virtfoundry-system rollout status statefulset/virtfoundry-mysql --timeout=300s || true
kubectl -n virtfoundry-system wait --for=condition=ready pod -l app=virtfoundry-mysql --timeout=300s || true

if [ "$USE_SIDELOAD" = "true" ]; then
  echo "==> Sideload images into ${IMPORT_NODE} containerd"
  if [ -n "$IMPORT_NODE_IP" ] && [ -x "$SCRIPTS_DIR/sideload/ssh.sh" ]; then
    IMPORT_NODE="$IMPORT_NODE" IMPORT_NODE_IP="$IMPORT_NODE_IP" IMAGE_TAG="$IMAGE_TAG" \
      LOCAL_REGISTRY="$LOCAL_REGISTRY" "$SCRIPTS_DIR/sideload/ssh.sh"
  else
    kubectl -n "$IMPORT_NS" delete pod "$IMPORT_POD" --ignore-not-found --wait=true 2>/dev/null || true
    sed "s/REPLACE_NODE_NAME/${IMPORT_NODE}/" "$IMPORT_MANIFEST" | kubectl apply -f -
    kubectl -n "$IMPORT_NS" wait --for=condition=Ready pod/"$IMPORT_POD" --timeout=120s
    TMPDIR="$(mktemp -d)"
    trap 'rm -rf "$TMPDIR"' EXIT
    docker save "${LOCAL_REGISTRY}/core:${IMAGE_TAG}" -o "$TMPDIR/virtfoundry-api.tar"
    docker save "${LOCAL_REGISTRY}/ui:${IMAGE_TAG}" -o "$TMPDIR/virtfoundry-ui.tar"
    kubectl cp "$TMPDIR/virtfoundry-api.tar" "${IMPORT_NS}/${IMPORT_POD}:/import/virtfoundry-api.tar"
    kubectl cp "$TMPDIR/virtfoundry-ui.tar" "${IMPORT_NS}/${IMPORT_POD}:/import/virtfoundry-ui.tar"
    kubectl -n "$IMPORT_NS" exec "$IMPORT_POD" -- sh -c \
      'cp /import/virtfoundry-api.tar /host/tmp/virtfoundry-api.tar && cp /import/virtfoundry-ui.tar /host/tmp/virtfoundry-ui.tar && \
       chroot /host ctr -n k8s.io images import /tmp/virtfoundry-api.tar && \
       chroot /host ctr -n k8s.io images import /tmp/virtfoundry-ui.tar && \
       chroot /host ctr -n k8s.io images label docker.io/virtfoundry/core:latest io.cri-containerd.image=managed && \
       chroot /host ctr -n k8s.io images label docker.io/virtfoundry/ui:latest io.cri-containerd.image=managed'
    kubectl -n "$IMPORT_NS" delete pod "$IMPORT_POD" --ignore-not-found
  fi
  kubectl -n virtfoundry-system rollout restart deployment/virtfoundry-api deployment/virtfoundry-ui deployment/virtfoundry-worker
fi

echo "==> Ensure Multus"
"$SCRIPT_DIR/../setup/multus.sh"

echo "==> Wait for workloads"
for dep in virtfoundry-api virtfoundry-ui virtfoundry-worker; do
  kubectl -n virtfoundry-system rollout status "deployment/$dep" --timeout=300s
done

GATEWAY_IP="$(kubectl -n traefik get gateway homelab-gateway \
  -o jsonpath='{.status.addresses[0].value}' 2>/dev/null || true)"

if [ -n "$GATEWAY_IP" ]; then
  echo "==> Gateway IP: $GATEWAY_IP"
  echo "    DNS: $DNS_HOST -> $GATEWAY_IP"
  if [ -n "${KUBESPRAY_ROOT:-}" ] && [ -x "${KUBESPRAY_ROOT}/scripts/register-dns.sh" ]; then
    echo "    Run: MIKROTIK_PASSWORD=*** ${KUBESPRAY_ROOT}/scripts/register-dns.sh $DNS_HOST $GATEWAY_IP"
  fi
else
  echo "WARN: Gateway has no LoadBalancer IP — check MetalLB and your Gateway controller"
fi

echo ""
echo "=== VirtFoundry deployed ==="
echo "URL: http://${DNS_HOST}/"
echo "API: http://${DNS_HOST}/api/v1"
echo "Login: root / virtfoundry"
echo ""
kubectl -n virtfoundry-system get pods,svc,httproute 2>/dev/null || kubectl -n virtfoundry-system get pods,svc
