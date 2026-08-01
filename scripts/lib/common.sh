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
    echo "WARN: KUBECONFIG not set — export KUBECONFIG=/path/to/kubeconfig" >&2
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
