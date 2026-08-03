#!/usr/bin/env bash
# Sideload container images into a cluster node via SSH (no registry required).
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
# shellcheck source=scripts/lib/common.sh
source "$SCRIPT_DIR/../lib/common.sh"
virtfoundry_source_common

NODE="${IMPORT_NODE:?IMPORT_NODE is required (e.g. worker-01)}"
NODE_IP="${IMPORT_NODE_IP:?IMPORT_NODE_IP is required (e.g. 10.0.30.251)}"
SSH_USER="${SSH_USER:-${USER}}"
LOCAL_REGISTRY="${LOCAL_REGISTRY:-docker.io/virtfoundry}"
IMAGE_TAG="${IMAGE_TAG:-latest}"

TMPDIR="$(mktemp -d)"
trap 'rm -rf "$TMPDIR"' EXIT

echo "==> Save images locally"
docker save "${LOCAL_REGISTRY}/core:${IMAGE_TAG}" -o "$TMPDIR/virtfoundry-api.tar"
docker save "${LOCAL_REGISTRY}/ui:${IMAGE_TAG}" -o "$TMPDIR/virtfoundry-ui.tar"

echo "==> Copy to ${NODE} (${NODE_IP})"
scp "$TMPDIR/virtfoundry-api.tar" "$TMPDIR/virtfoundry-ui.tar" "${SSH_USER}@${NODE_IP}:/tmp/"

echo "==> Import into containerd on ${NODE}"
ssh "${SSH_USER}@${NODE_IP}" "sudo /usr/local/bin/ctr -n k8s.io images import /tmp/virtfoundry-api.tar && \
  sudo /usr/local/bin/ctr -n k8s.io images import /tmp/virtfoundry-ui.tar && \
  sudo /usr/local/bin/ctr -n k8s.io images label docker.io/virtfoundry/core:${IMAGE_TAG} io.cri-containerd.image=managed && \
  sudo /usr/local/bin/ctr -n k8s.io images label docker.io/virtfoundry/ui:${IMAGE_TAG} io.cri-containerd.image=managed && \
  rm -f /tmp/virtfoundry-api.tar /tmp/virtfoundry-ui.tar"

echo "==> Done — restart virtfoundry pods to pick up images"
