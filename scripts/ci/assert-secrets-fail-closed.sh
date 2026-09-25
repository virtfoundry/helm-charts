#!/usr/bin/env bash
# Guard for helm-charts#37: the chart must refuse to render insecure credentials.
# Every case below has to fail; a successful render means the fail-closed logic is gone.
set -euo pipefail

CHART="${CHART:-./charts/virtfoundry}"
STRONG_ROOT="assert-only-password"
STRONG_JWT="assert-only-jwt-secret-0123456789abcdef0123"

failures=0

expect_failure() {
  local description="$1"
  shift
  if helm template virtfoundry "$CHART" "$@" >/dev/null 2>&1; then
    echo "FAIL: $description rendered successfully but must fail closed" >&2
    failures=$((failures + 1))
  else
    echo "ok: $description fails closed"
  fi
}

expect_failure "chart defaults (no credentials)"
expect_failure "sentinel rootPassword" \
  --set-string secrets.rootPassword=virtfoundry --set-string secrets.jwtSecret="$STRONG_JWT"
expect_failure "sentinel jwtSecret" \
  --set-string secrets.rootPassword="$STRONG_ROOT" --set-string secrets.jwtSecret=change-me-in-production
expect_failure "rootPassword shorter than 12 chars" \
  --set-string secrets.rootPassword=short --set-string secrets.jwtSecret="$STRONG_JWT"
expect_failure "jwtSecret shorter than 32 chars" \
  --set-string secrets.rootPassword="$STRONG_ROOT" --set-string secrets.jwtSecret=too-short-jwt
expect_failure "autoGenerateJwtSecret on upgrade without a readable Secret" \
  --is-upgrade --set-string secrets.rootPassword="$STRONG_ROOT" --set secrets.autoGenerateJwtSecret=true

if [ "$failures" -gt 0 ]; then
  echo "$failures fail-closed assertion(s) broken" >&2
  exit 1
fi

echo "All fail-closed assertions hold"
