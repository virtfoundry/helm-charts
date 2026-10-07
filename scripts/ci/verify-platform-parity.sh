#!/usr/bin/env bash
# The umbrella chart must render exactly the resources of the standalone charts
# (same kind/namespace/name), so moving from three releases to one does not
# rename or recreate anything. Needs network (pulls the VKS OCI chart).
set -euo pipefail
cd "$(dirname "$0")/../.."

ROOT=ci-render-only-password
JWT=ci-render-only-jwt-secret-0123456789abcdef
NS=virtfoundry-system
umb=charts/virtfoundry-platform
tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT

helm dependency build "$umb" >/dev/null
vks_tgz="$(ls "$umb"/charts/virtfoundry-vks-*.tgz)"

helm lint "$umb" --set-string core.secrets.rootPassword="$ROOT" --set-string core.secrets.jwtSecret="$JWT" >/dev/null

{
  helm template virtfoundry-operator charts/virtfoundry-operator -n "$NS"
  echo ---
  helm template virtfoundry charts/virtfoundry -n "$NS" --set-string secrets.rootPassword="$ROOT" --set-string secrets.jwtSecret="$JWT"
  echo ---
  helm template virtfoundry-vks "$vks_tgz" -n "$NS"
} > "$tmp/standalone.yaml"

helm template platform "$umb" -n "$NS" --set vks.enabled=true \
  --set-string core.secrets.rootPassword="$ROOT" --set-string core.secrets.jwtSecret="$JWT" > "$tmp/umbrella.yaml"

ids() {
  python3 - "$1" <<'PY'
import sys, yaml
for d in sorted({(d["kind"], d["metadata"].get("namespace", ""), d["metadata"]["name"])
                 for d in yaml.safe_load_all(open(sys.argv[1])) if d}):
    print(*d)
PY
}

if ! diff <(ids "$tmp/standalone.yaml") <(ids "$tmp/umbrella.yaml"); then
  echo "FAIL: virtfoundry-platform renders different resources than the standalone charts" >&2
  exit 1
fi
echo "OK: virtfoundry-platform matches the standalone charts"

# VKS is off by default.
helm template platform "$umb" -n "$NS" \
  --set-string core.secrets.rootPassword="$ROOT" --set-string core.secrets.jwtSecret="$JWT" > "$tmp/default.yaml"
if ids "$tmp/default.yaml" | grep -q "virtfoundry-vks"; then
  echo "FAIL: VKS resources rendered with vks.enabled=false" >&2
  exit 1
fi
echo "OK: VKS is off by default"
