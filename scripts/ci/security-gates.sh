#!/usr/bin/env bash
# PR / CI security gates for charts/virtfoundry.
# Keeps #37 (secrets fail-closed), #38 (no platform RBAC wildcards) and #39
# (least-privilege API ClusterRole) from regressing.
#
# Gates activate when the corresponding fix is present in the tree:
#   #37 → templates reference virtfoundry.validateSecrets
#   #38 → platform-rbac.yaml defines the -platform-kubevirt ServiceAccount
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
CHART="${ROOT}/charts/virtfoundry"
SAFE_ROOT='correct-horse-battery-staple'
SAFE_JWT='AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=' # 44 chars, not a known sentinel
PLATFORM_RBAC="${CHART}/templates/platform-rbac.yaml"

die() { echo "security-gates: FAIL: $*" >&2; exit 1; }
ok() { echo "security-gates: ok: $*"; }

command -v helm >/dev/null || die "helm not installed"
[[ -d "$CHART" ]] || die "chart not found at $CHART"

TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

# --- Gate: secrets fail-closed (#37) ---
if grep -q 'virtfoundry.validateSecrets' "${CHART}/templates/"*.yaml "${CHART}/templates/"*.tpl 2>/dev/null; then
  if helm template vf "$CHART" >"${TMP}/default.out" 2>"${TMP}/default.err"; then
    die "default values must fail closed (helm-charts#37); got a successful render"
  fi
  if ! grep -qiE 'rootPassword|jwtSecret|secrets\.' "${TMP}/default.err"; then
    die "default render failed, but error did not mention secrets (unexpected): $(head -c 400 "${TMP}/default.err")"
  fi
  ok "default values fail closed (#37)"

  if grep -qE '^[[:space:]]*jwtSecret:[[:space:]]*change-me-in-production[[:space:]]*$' "${CHART}/values.yaml" \
    || grep -qE '^[[:space:]]*rootPassword:[[:space:]]*virtfoundry[[:space:]]*$' "${CHART}/values.yaml"; then
    die "values.yaml still ships sentinel secrets.rootPassword/jwtSecret defaults (#37)"
  fi
  ok "values.yaml has no sentinel secret defaults (#37)"
else
  ok "skip secrets fail-closed (validateSecrets not in chart yet)"
fi

# --- Render with explicit non-sentinel secrets (works with or without #37) ---
helm template vf "$CHART" \
  --set "secrets.rootPassword=${SAFE_ROOT}" \
  --set "secrets.jwtSecret=${SAFE_JWT}" \
  >"${TMP}/safe.yaml" \
  || die "helm template with safe secrets failed"

# --- Gate: scoped platform hook RBAC (#38) ---
# Only enforce once the chart has the per-job identities from #38.
if [[ -f "$PLATFORM_RBAC" ]] && grep -q 'platform-kubevirt' "$PLATFORM_RBAC"; then
  if grep -E '^[[:space:]]*name:[[:space:]]*virtfoundry-platform[[:space:]]*$' "${TMP}/safe.yaml" >/dev/null; then
    die "rendered manifests still include legacy name virtfoundry-platform (expected -platform-kubevirt/multus/cdi)"
  fi
  ok "no legacy virtfoundry-platform identity (#38)"

  check_platform_wildcards() {
    local file="$1"
    local label="$2"
    python3 - "$file" "$label" <<'PY'
import re, sys
from pathlib import Path
text = Path(sys.argv[1]).read_text()
label = sys.argv[2]
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
    print(f"security-gates: FAIL ({label}): platform ClusterRole wildcards:", file=sys.stderr)
    for f in fail:
        print(f"  - {f}", file=sys.stderr)
    sys.exit(1)
print(f"security-gates: ok: platform ClusterRoles have no wildcards ({label})")
PY
  }

  check_platform_wildcards "${TMP}/safe.yaml" "default"

  helm template vf "$CHART" \
    --set "secrets.rootPassword=${SAFE_ROOT}" \
    --set "secrets.jwtSecret=${SAFE_JWT}" \
    --set platform.multus.install=true \
    --set platform.cdi.install=true \
    >"${TMP}/all.yaml" \
    || die "helm template with multus+cdi failed"

  check_platform_wildcards "${TMP}/all.yaml" "multus+cdi"
else
  ok "skip platform RBAC gates (scoped -platform-kubevirt identities not in chart yet)"
fi

# --- Gate: least-privilege API ClusterRole (#39) ---
# The API ClusterRole has to stay cluster scoped (tenant namespaces are created at
# runtime), so these checks police the verbs instead: no way to enumerate or destroy
# Secrets, no writes to Nodes, no pod creation, and no wildcards.
check_api_clusterrole() {
  local file="$1"
  local label="$2"
  local secrets_mode="$3" # "fallback" (get/create/update) or "none"
  python3 - "$file" "$label" "$secrets_mode" "${CHART}/../virtfoundry-operator/crds" <<'PY'
import re
import sys
from pathlib import Path

path, label, secrets_mode, crd_dir = sys.argv[1:5]

failures = []


def fail(msg):
    failures.append(msg)


def parse_rules(doc):
    """Minimal parser for the rule shape this chart renders (flow or block lists)."""
    lines = doc.splitlines()
    start = next((i for i, line in enumerate(lines) if line.rstrip() == "rules:"), None)
    if start is None:
        return []
    rules, current, key = [], None, None
    for line in lines[start + 1:]:
        if not line.strip() or line.lstrip().startswith("#"):
            continue
        if not line.startswith("  "):
            break
        item = line.strip()
        if line.startswith("  - "):
            current, key = {}, None
            rules.append(current)
            item = item[2:]
        if item.startswith("- "):
            if current is None or key is None:
                raise SystemExit(f"security-gates: cannot parse rule list near: {line!r}")
            current[key].append(item[2:].strip().strip("\"'"))
            continue
        match = re.match(r"([A-Za-z]+):\s*(.*)$", item)
        if not match or current is None:
            raise SystemExit(f"security-gates: cannot parse rule line: {line!r}")
        key, rest = match.group(1), match.group(2).strip()
        if rest.startswith("["):
            current[key] = [v.strip().strip("\"'") for v in rest.strip("[]").split(",") if v.strip()]
        else:
            current[key] = [rest.strip("\"'")] if rest else []
    return rules


docs = re.split(r"(?m)^---\s*$", Path(path).read_text())
role = None
for doc in docs:
    if not re.search(r"(?m)^kind:\s*ClusterRole\s*$", doc):
        continue
    name = re.search(r"(?m)^\s{2}name:\s*(\S+)\s*$", doc)
    if name and name.group(1).endswith("-api"):
        role = doc
        break

if role is None:
    raise SystemExit(f"security-gates: FAIL ({label}): no *-api ClusterRole in the rendered output")

rules = parse_rules(role)
if len(rules) < 10 or any("verbs" not in r or "resources" not in r for r in rules):
    raise SystemExit(f"security-gates: FAIL ({label}): parsed {len(rules)} usable API ClusterRole rules")


def verbs_for(resource, group=""):
    out = set()
    for rule in rules:
        if group in rule.get("apiGroups", []) and resource in rule.get("resources", []):
            out |= set(rule["verbs"])
    return out


for rule in rules:
    if "*" in rule.get("apiGroups", []):
        fail("apiGroups wildcard")
    if "*" in rule.get("resources", []):
        fail(f"resources wildcard for apiGroups {rule.get('apiGroups')}")
    if "*" in rule["verbs"]:
        fail(f"verbs wildcard for resources {rule.get('resources')}")

# helm-charts#39: a compromised API pod must not be able to read every Secret in
# the cluster or delete the ones it can reach.
secrets = verbs_for("secrets")
if secrets_mode == "none":
    if secrets:
        fail(f"expected no cluster-wide secrets rule with rbac.api.secretNamespaces set, got {sorted(secrets)}")
else:
    forbidden = secrets & {"list", "watch", "delete", "deletecollection", "patch"}
    if forbidden:
        fail(f"cluster-wide secrets rule grants {sorted(forbidden)}")
    if not secrets:
        fail("expected the cluster-scoped secrets fallback (get/create/update) by default")

nodes = verbs_for("nodes")
write_verbs = nodes - {"get", "list", "watch"}
if write_verbs:
    fail(f"nodes rule grants {sorted(write_verbs)} (read only: the API never mutates Nodes)")

pods = verbs_for("pods") - {"get", "list", "watch"}
if pods:
    fail(f"pods rule grants {sorted(pods)} (virt-launcher pods are created by KubeVirt)")

# Explicit virtfoundry.io resources must cover every shipped CRD, otherwise the
# list silently falls behind a new kind.
granted = set()
for rule in rules:
    if "virtfoundry.io" in rule.get("apiGroups", []):
        granted |= {r for r in rule["resources"] if "/" not in r}
plurals = set()
for crd in sorted(Path(crd_dir).glob("*.yaml")):
    plurals |= set(re.findall(r"(?m)^\s+plural:\s*(\S+)\s*$", crd.read_text()))
if not plurals:
    fail(f"no CRD plurals found under {crd_dir}")
missing = plurals - granted
if missing:
    fail(f"virtfoundry.io rule is missing CRDs {sorted(missing)} (add them to templates/rbac.yaml)")
unknown = granted - plurals
if unknown:
    fail(f"virtfoundry.io rule grants unknown resources {sorted(unknown)}")

if failures:
    print(f"security-gates: FAIL ({label}): API ClusterRole:", file=sys.stderr)
    for item in failures:
        print(f"  - {item}", file=sys.stderr)
    sys.exit(1)
print(f"security-gates: ok: API ClusterRole is least privilege ({label})")
PY
}

check_api_clusterrole "${TMP}/safe.yaml" "default" fallback

helm template vf "$CHART" \
  --set "secrets.rootPassword=${SAFE_ROOT}" \
  --set "secrets.jwtSecret=${SAFE_JWT}" \
  --set 'rbac.api.secretNamespaces={virtfoundry-tenant-acme,virtfoundry-tenant-globex}' \
  >"${TMP}/scoped-secrets.yaml" \
  || die "helm template with rbac.api.secretNamespaces failed"

check_api_clusterrole "${TMP}/scoped-secrets.yaml" "secretNamespaces" none

for ns in virtfoundry-tenant-acme virtfoundry-tenant-globex; do
  python3 - "${TMP}/scoped-secrets.yaml" "$ns" <<'PY' || exit 1
import re
import sys
from pathlib import Path

path, ns = sys.argv[1:3]
for doc in re.split(r"(?m)^---\s*$", Path(path).read_text()):
    if not re.search(r"(?m)^kind:\s*RoleBinding\s*$", doc):
        continue
    if re.search(rf"(?m)^\s{{2}}namespace:\s*{re.escape(ns)}\s*$", doc):
        print(f"security-gates: ok: secrets RoleBinding rendered in {ns} (#39)")
        sys.exit(0)
print(f"security-gates: FAIL: rbac.api.secretNamespaces did not render a RoleBinding in {ns}", file=sys.stderr)
sys.exit(1)
PY
done

# Namespace deletion guard: must render on 1.30+, must be skipped below it so the
# chart still installs (same contract as the operator chart, helm-charts#43).
VAP_API="admissionregistration.k8s.io/v1/ValidatingAdmissionPolicy"
guard="$(helm template vf "$CHART" \
  --set "secrets.rootPassword=${SAFE_ROOT}" \
  --set "secrets.jwtSecret=${SAFE_JWT}" \
  -s templates/api-namespace-guard.yaml --api-versions "$VAP_API" 2>/dev/null || true)"
grep -q "kind: ValidatingAdmissionPolicy$" <<<"$guard" \
  || die "API namespace deletion guard must render on clusters serving ${VAP_API}" \
         "(templates/api-namespace-guard.yaml missing, empty, or namespaceGuard.enabled defaults to false)"
ok "API namespace deletion guard renders on clusters serving ValidatingAdmissionPolicy (#39)"

if grep -q "kind: ValidatingAdmissionPolicy$" "${TMP}/safe.yaml"; then
  die "API namespace guard rendered on a cluster without ${VAP_API} (chart would fail to install)"
fi
ok "API namespace deletion guard is skipped on clusters without ValidatingAdmissionPolicy (#39)"

# Bridge DaemonSet must not render on default values (isolated/public both off) — #40.
if grep -q "bridge-setup" "${TMP}/safe.yaml"; then
  die "default helm template must not render bridge-setup DaemonSet (isolated.enabled should be false; #40)"
fi
if grep -qE "hostPID:\\s*true" "${TMP}/safe.yaml"; then
  die "default helm template must not set hostPID: true (#40)"
fi
ok "default install does not schedule hostNetwork bridge DaemonSet (#40)"

# When opted in, DaemonSet must use caps (not privileged) and no hostPID.
helm template vf "$CHART" \
  --set "secrets.rootPassword=${SAFE_ROOT}" \
  --set "secrets.jwtSecret=${SAFE_JWT}" \
  --set platform.networking.isolated.enabled=true \
  >"${TMP}/bridge-on.yaml" \
  || die "helm template with isolated.enabled=true failed"

grep -q "kind: DaemonSet$" "${TMP}/bridge-on.yaml" \
  || die "isolated.enabled=true must render bridge DaemonSet (#40)"
grep -q "name: .*bridge-setup" "${TMP}/bridge-on.yaml" \
  || die "isolated.enabled=true must render bridge-setup ServiceAccount (#40)"
grep -q "automountServiceAccountToken: false" "${TMP}/bridge-on.yaml" \
  || die "bridge ServiceAccount must set automountServiceAccountToken: false (#40)"
if grep -qE "hostPID:\\s*true" "${TMP}/bridge-on.yaml"; then
  die "bridge DaemonSet must not set hostPID: true (#40)"
fi
if grep -qE "privileged:\\s*true" "${TMP}/bridge-on.yaml"; then
  die "bridge DaemonSet must not use privileged: true (#40)"
fi
grep -q "NET_ADMIN" "${TMP}/bridge-on.yaml" \
  || die "bridge DaemonSet must request NET_ADMIN (#40)"
grep -q "alpine@sha256:" "${TMP}/bridge-on.yaml" \
  || die "bridge DaemonSet must pin alpine by digest (#40)"
ok "opt-in bridge DaemonSet uses caps, no hostPID, pinned alpine (#40)"

# --- Gate: API/UI pod hardening (#42) ---
python3 - "${TMP}/safe.yaml" <<'PY' || exit 1
import re
import sys
from pathlib import Path

text = Path(sys.argv[1]).read_text()
docs = re.split(r"(?m)^---\s*$", text)

def find_dep(name_suffix):
    for doc in docs:
        if not re.search(r"(?m)^kind:\s*Deployment\s*$", doc):
            continue
        name = re.search(r"(?m)^\s{2}name:\s*(\S+)\s*$", doc)
        if name and name.group(1).endswith(name_suffix):
            return doc
    return None

failures = []
for suffix in ("-api", "-ui"):
    dep = find_dep(suffix)
    if dep is None:
        failures.append(f"missing Deployment *{suffix}")
        continue
    for needle in (
        "runAsNonRoot: true",
        "type: RuntimeDefault",
        "allowPrivilegeEscalation: false",
        "readOnlyRootFilesystem: true",
        "drop:",
        "requests:",
        "limits:",
    ):
        if needle not in dep:
            failures.append(f"{suffix}: missing {needle}")
    if "ALL" not in dep:
        failures.append(f"{suffix}: capabilities.drop must include ALL")

ui_sa = None
for doc in docs:
    if not re.search(r"(?m)^kind:\s*ServiceAccount\s*$", doc):
        continue
    name = re.search(r"(?m)^\s{2}name:\s*(\S+)\s*$", doc)
    if name and name.group(1).endswith("-ui"):
        ui_sa = doc
        break
if ui_sa is None:
    failures.append("missing UI ServiceAccount")
elif "automountServiceAccountToken: false" not in ui_sa:
    failures.append("UI ServiceAccount must set automountServiceAccountToken: false")

ui_dep = find_dep("-ui")
if ui_dep and "automountServiceAccountToken: false" not in ui_dep:
    failures.append("UI Deployment must set automountServiceAccountToken: false")
if ui_dep and re.search(r"containerPort:\s*80\b", ui_dep):
    failures.append("UI must not listen on containerPort 80 (use 8080)")

np_kinds = [d for d in docs if re.search(r"(?m)^kind:\s*NetworkPolicy\s*$", d)]
if len(np_kinds) < 2:
    failures.append("expected NetworkPolicy for API and UI when networkPolicy.enabled defaults true")

if failures:
    print("security-gates: FAIL (#42) API/UI hardening:", file=sys.stderr)
    for item in failures:
        print(f"  - {item}", file=sys.stderr)
    sys.exit(1)
print("security-gates: ok: API/UI pod hardening (#42)")
PY

ok "all security gates passed"
