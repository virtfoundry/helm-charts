#!/usr/bin/env bash
# Sideload container images into a cluster node via SSH (no registry required).
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
# shellcheck source=scripts/lib/common.sh
source "$SCRIPT_DIR/../lib/common.sh"
virtforge_source_common

NODE="${IMPORT_NODE:?IMPORT_NODE is required (e.g. homelab-worker-01)}"
NODE_IP="${IMPORT_NODE_IP:?IMPORT_NODE_IP is required (e.g. 10.0.30.251)}"
SSH_USER="${SSH_USER:-${USER}}"
LOCAL_REGISTRY="${LOCAL_REGISTRY:-docker.io/virtforge}"
IMAGE_TAG="${IMAGE_TAG:-latest}"

TMPDIR="$(mktemp -d)"
trap 'rm -rf "$TMPDIR"' EXIT

echo "==> Save images locally"
docker save "${LOCAL_REGISTRY}/iaas-api:${IMAGE_TAG}" -o "$TMPDIR/virtforge-api.tar"
docker save "${LOCAL_REGISTRY}/iaas-ui:${IMAGE_TAG}" -o "$TMPDIR/virtforge-ui.tar"

echo "==> Copy to ${NODE} (${NODE_IP})"
scp "$TMPDIR/virtforge-api.tar" "$TMPDIR/virtforge-ui.tar" "${SSH_USER}@${NODE_IP}:/tmp/"

echo "==> Import into containerd on ${NODE}"
ssh "${SSH_USER}@${NODE_IP}" "sudo /usr/local/bin/ctr -n k8s.io images import /tmp/virtforge-api.tar && \
  sudo /usr/local/bin/ctr -n k8s.io images import /tmp/virtforge-ui.tar && \
  sudo /usr/local/bin/ctr -n k8s.io images label docker.io/virtforge/iaas-api:${IMAGE_TAG} io.cri-containerd.image=managed && \
  sudo /usr/local/bin/ctr -n k8s.io images label docker.io/virtforge/iaas-ui:${IMAGE_TAG} io.cri-containerd.image=managed && \
  rm -f /tmp/virtforge-api.tar /tmp/virtforge-ui.tar"

echo "==> Done — restart virtforge pods to pick up images"
