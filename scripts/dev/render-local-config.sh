#!/usr/bin/env bash
# Render config/config.yaml for local dev from Helm values (cluster source of truth).
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=../lib/common.sh
source "$SCRIPT_DIR/../lib/common.sh"
virtfoundry_source_common
virtfoundry_require_chart

VALUES="${VALUES:-$CHART_DIR/values.yaml}"
OUTPUT="${OUTPUT:-${APP_CONFIG:-${APP_ROOT:+$APP_ROOT/config/config.yaml}}}"

if [ -z "${OUTPUT:-}" ]; then
  echo "ERROR: set APP_CONFIG or clone core next to helm-charts (APP_ROOT)" >&2
  exit 1
fi

mkdir -p "$(dirname "$OUTPUT")"

helm template virtfoundry "$CHART_DIR" -f "$VALUES" --show-only templates/configmap.yaml \
  | awk '/^  config.yaml: \|$/{p=1;next} p && /^[^ ]/{exit} p{sub(/^    /,""); print}' \
  > "$OUTPUT"

echo "Wrote $OUTPUT (from $VALUES)"
