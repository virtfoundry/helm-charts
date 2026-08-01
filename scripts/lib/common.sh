#!/usr/bin/env bash
# Shared paths and kubeconfig resolution for virtforge-chart scripts.

virtforge_chart_root() {
  cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd
}

virtforge_source_common() {
  CHART_ROOT="${CHART_ROOT:-$(virtforge_chart_root)}"
  CHART_DIR="${CHART_DIR:-$CHART_ROOT/charts/virtforge}"
  SCRIPTS_DIR="${SCRIPTS_DIR:-$CHART_ROOT/scripts}"

  if [ -z "${APP_ROOT:-}" ]; then
    APP_ROOT="$(cd "$CHART_ROOT/../virtforge" 2>/dev/null && pwd || true)"
  fi

  if [ -z "${KUBECONFIG:-}" ]; then
    KUBESPRAY_ROOT="${KUBESPRAY_ROOT:-$(cd "$CHART_ROOT/../../../homelab/kubespray" 2>/dev/null && pwd || true)}"
    if [ -n "${KUBESPRAY_ROOT:-}" ] && [ -f "$KUBESPRAY_ROOT/inventory/homelab-cluster/artifacts/admin.conf" ]; then
      KUBECONFIG="$KUBESPRAY_ROOT/inventory/homelab-cluster/artifacts/admin.conf"
    fi
  fi

  export KUBECONFIG
}

virtforge_require_chart() {
  if [ ! -f "$CHART_DIR/Chart.yaml" ]; then
    echo "ERROR: Helm chart not found at $CHART_DIR" >&2
    exit 1
  fi
}

virtforge_require_kubeconfig() {
  if [ -z "${KUBECONFIG:-}" ] || [ ! -f "$KUBECONFIG" ]; then
    echo "ERROR: KUBECONFIG not set or file missing (export KUBECONFIG=/path/to/kubeconfig)" >&2
    exit 1
  fi
}
