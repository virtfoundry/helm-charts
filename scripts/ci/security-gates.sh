#!/usr/bin/env bash
# PR / CI security gates for charts/virtfoundry.
# Keeps #37 (secrets fail-closed) and #38 (no platform RBAC wildcards) from regressing.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
CHART="${ROOT}/charts/virtfoundry"
SAFE_ROOT='correct-horse-battery-staple'
SAFE_JWT='AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=' # 44 chars, not a known sentinel

die() { echo "security-gates: FAIL: $*" >&2; exit 1; }
ok() { echo "security-gates: ok: $*"; }

command -v helm >/dev/null || die "helm not installed"
[[ -d "$CHART" ]] || die "chart not found at $CHART"

TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

# --- Gate: secrets fail-closed (#37) ---
# When the chart ships validateSecrets, bare defaults must not render.
if grep -q 'virtfoundry.validateSecrets' "${CHART}/templates/"*.yaml "${CHART}/templates/"*.tpl 2>/dev/null; then
  if helm template vf "$CHART" >"${TMP}/default.out" 2>"${TMP}/default.err"; then
    die "default values must fail closed (helm-charts#37); got a successful render"
  fi
  if ! grep -qiE 'rootPassword|jwtSecret|secrets\.' "${TMP}/default.err"; then
    die "default render failed, but error did not mention secrets (unexpected): $(head -c 400 "${TMP}/default.err")"
  fi
  ok "default values fail closed (#37)"

  if ! grep -qE 'change-me-in-production|^[[:space:]]*jwtSecret:[[:space:]]*$' "${CHART}/values.yaml"; then
    # empty or non-sentinel is fine; block known published HMAC default if still present as a default
    :
  fi
  if grep -qE '^[[:space:]]*jwtSecret:[[:space:]]*change-me-in-production[[:space:]]*$' "${CHART}/values.yaml" \
    || grep -qE '^[[:space:]]*rootPassword:[[:space:]]*virtfoundry[[:space:]]*$' "${CHART}/values.yaml"; then
    die "values.yaml still ships sentinel secrets.rootPassword/jwtSecret defaults (#37)"
  fi
  ok "values.yaml has no sentinel secret defaults (#37)"
else
  ok "skip secrets fail-closed (validateSecrets not in chart yet)"
fi

# --- Gate: render with explicit non-sentinel secrets (works on #45 and #46) ---
helm template vf "$CHART" \
  --set "secrets.rootPassword=${SAFE_ROOT}" \
  --set "secrets.jwtSecret=${SAFE_JWT}" \
  >"${TMP}/safe.yaml" \
  || die "helm template with safe secrets failed"

# --- Gate: no legacy platform SA / ClusterRole (#38) ---
if grep -E '^[[:space:]]*name:[[:space:]]*virtfoundry-platform[[:space:]]*$' "${TMP}/safe.yaml" >/dev/null; then
  die "rendered manifests still include legacy name virtfoundry-platform (expected -platform-kubevirt/multus/cdi)"
fi
ok "no legacy virtfoundry-platform identity (#38)"

# --- Gate: platform hook ClusterRoles must not use apiGroups/resources wildcards (#38) ---
python3 - "$TMP/safe.yaml" <<'PY'
import re, sys
from pathlib import Path

text = Path(sys.argv[1]).read_text()
docs = re.split(r"(?m)^---\s*$", text)
fail = []
for doc in docs:
    if not doc.strip():
        continue
    if not re.search(r"(?m)^kind:\s*ClusterRole\s*$", doc):
        continue
    name_m = re.search(r"(?m)^\s*name:\s*(\S+)\s*$", doc)
    name = name_m.group(1) if name_m else ""
    if "platform" not in name:
        continue
    if re.search(r'apiGroups:\s*\[\s*"?\*"?\s*\]', doc) or re.search(r"apiGroups:\s*\[\s*\*\s*\]", doc):
        fail.append(f"{name}: apiGroups wildcard")
    if re.search(r'resources:\s*\[\s*"?\*"?\s*\]', doc) or re.search(r"resources:\s*\[\s*\*\s*\]", doc):
        fail.append(f"{name}: resources wildcard")
if fail:
    print("security-gates: FAIL: platform ClusterRole wildcards:", file=sys.stderr)
    for f in fail:
        print(f"  - {f}", file=sys.stderr)
    sys.exit(1)
print("security-gates: ok: platform ClusterRoles have no apiGroups/resources wildcards (#38)")
PY

# --- Gate: Multus/CDI flags must not reintroduce chart-wide * wildcards on platform roles ---
helm template vf "$CHART" \
  --set "secrets.rootPassword=${SAFE_ROOT}" \
  --set "secrets.jwtSecret=${SAFE_JWT}" \
  --set platform.multus.install=true \
  --set platform.cdi.install=true \
  >"${TMP}/all.yaml" \
  || die "helm template with multus+cdi failed"

python3 - "$TMP/all.yaml" <<'PY'
import re, sys
from pathlib import Path
text = Path(sys.argv[1]).read_text()
docs = re.split(r"(?m)^---\s*$", text)
fail = []
for doc in docs:
    if not doc.strip():
        continue
    if not re.search(r"(?m)^kind:\s*ClusterRole\s*$", doc):
        continue
    name_m = re.search(r"(?m)^\s*name:\s*(\S+)\s*$", doc)
    name = name_m.group(1) if name_m else ""
    if "platform" not in name:
        continue
    if re.search(r'apiGroups:\s*\[\s*"?\*"?\s*\]', doc) or re.search(r"apiGroups:\s*\[\s*\*\s*\]", doc):
        fail.append(f"{name}: apiGroups wildcard")
    if re.search(r'resources:\s*\[\s*"?\*"?\s*\]', doc) or re.search(r"resources:\s*\[\s*\*\s*\]", doc):
        fail.append(f"{name}: resources wildcard")
if fail:
    print("security-gates: FAIL (multus+cdi):", file=sys.stderr)
    for f in fail:
        print(f"  - {f}", file=sys.stderr)
    sys.exit(1)
print("security-gates: ok: platform ClusterRoles stay scoped with multus+cdi (#38)")
PY

ok "all security gates passed"
