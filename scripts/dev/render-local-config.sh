#!/usr/bin/env bash
# Render config/config.yaml for local dev from Helm values (cluster source of truth).
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=../lib/common.sh
source "$SCRIPT_DIR/../lib/common.sh"
virtforge_source_common
virtforge_require_chart

VALUES="${VALUES:-$CHART_DIR/values.yaml}"
OUTPUT="${OUTPUT:-${APP_CONFIG:-${APP_ROOT:+$APP_ROOT/config/config.yaml}}}"

if [ -z "${OUTPUT:-}" ]; then
  echo "ERROR: set APP_CONFIG or clone virtforge next to virtforge-chart (APP_ROOT)" >&2
  exit 1
fi

mkdir -p "$(dirname "$OUTPUT")"

helm template virtforge "$CHART_DIR" -f "$VALUES" --show-only templates/configmap.yaml \
  | awk '/^  config.yaml: \|$/{p=1;next} p && /^[^ ]/{exit} p{sub(/^    /,""); print}' \
  > "$OUTPUT"

echo "Wrote $OUTPUT (from $VALUES)"
