#!/usr/bin/env bash
# Shared paths and kubeconfig resolution for virtfoundry-chart scripts.

virtfoundry_chart_root() {
  cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd
}

virtfoundry_source_common() {
  CHART_ROOT="${CHART_ROOT:-$(virtfoundry_chart_root)}"
  CHART_DIR="${CHART_DIR:-$CHART_ROOT/charts/virtfoundry}"
  SCRIPTS_DIR="${SCRIPTS_DIR:-$CHART_ROOT/scripts}"

  if [ -z "${APP_ROOT:-}" ]; then
    APP_ROOT="$(cd "$CHART_ROOT/../virtfoundry" 2>/dev/null && pwd \
      || cd "$CHART_ROOT/../core" 2>/dev/null && pwd \
      || cd "$CHART_ROOT/../virtfoundry" 2>/dev/null && pwd \
      || true)"
  fi

  if [ -z "${KUBECONFIG:-}" ]; then
    echo "WARN: KUBECONFIG not set — export KUBECONFIG=/path/to/kubeconfig" >&2
  fi

  export KUBECONFIG
}

virtfoundry_require_chart() {
  if [ ! -f "$CHART_DIR/Chart.yaml" ]; then
    echo "ERROR: Helm chart not found at $CHART_DIR" >&2
    exit 1
  fi
}

virtfoundry_require_kubeconfig() {
  if [ -z "${KUBECONFIG:-}" ] || [ ! -f "$KUBECONFIG" ]; then
    echo "ERROR: KUBECONFIG not set or file missing (export KUBECONFIG=/path/to/kubeconfig)" >&2
    exit 1
  fi
}
