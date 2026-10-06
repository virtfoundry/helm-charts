#!/usr/bin/env bash
# Checks the rendered virtfoundry-api RBAC against the contract owned by core
# (docs/rbac-contract.yaml): every required verb must be granted, and verbs the code
# only calls on a best-effort basis (it tolerates Forbidden) must NOT be granted.
#
# Why: the API's typed client-go calls are checked in core, but fake clientsets cannot
# see RBAC, so a call without a matching grant only failed at deploy time (core#192).
#
# API_RBAC_CONTRACT points at a local copy of the contract; otherwise core main is fetched.
# Verbs the chart grants beyond the contract are reported as warnings, not failures.
# Needs python3 with PyYAML (installed from requirements-docs.txt in CI).
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
CONTRACT_URL="${API_RBAC_CONTRACT_URL:-https://raw.githubusercontent.com/virtfoundry/core/main/docs/rbac-contract.yaml}"
TMP="$(mktemp -d)"
trap 'rm -rf "${TMP}"' EXIT

if [[ -n "${API_RBAC_CONTRACT:-}" ]]; then
  cp "${API_RBAC_CONTRACT}" "${TMP}/contract.yaml"
else
  curl -fsSL "${CONTRACT_URL}" -o "${TMP}/contract.yaml"
fi

RENDER=(--set-string secrets.rootPassword=render-only-password
        --set-string secrets.jwtSecret=render-only-jwt-secret-0123456789abcdef)
helm template virtfoundry "${ROOT}/charts/virtfoundry" "${RENDER[@]}" > "${TMP}/rendered.yaml"

python3 - "${TMP}/contract.yaml" "${TMP}/rendered.yaml" <<'PY'
import sys, yaml

contract = yaml.safe_load(open(sys.argv[1]))
docs = [d for d in yaml.safe_load_all(open(sys.argv[2])) if d]

# The API identity: the ClusterRole and any Role named after it (e.g. *-api-secrets).
cluster_rules, role_rules = [], []
for d in docs:
    name = d.get("metadata", {}).get("name", "")
    if d.get("kind") == "ClusterRole" and name.endswith("-api"):
        cluster_rules += d.get("rules", [])
    elif d.get("kind") == "Role" and "-api" in name:
        role_rules += d.get("rules", [])
if not cluster_rules:
    sys.exit("FAIL: no API ClusterRole (name ending in -api) found in the rendered chart")

def granted(rules, group, resource, verb):
    for r in rules:
        if group not in r.get("apiGroups", []) and "*" not in r.get("apiGroups", []):
            continue
        res = r.get("resources", [])
        if resource not in res and "*" not in res:
            continue
        v = r.get("verbs", [])
        if verb in v or "*" in v:
            return True
    return False

failures, warnings = [], []
for rule in contract["rules"]:
    group, resource = rule["apiGroup"], rule["resource"]
    namespaced = rule.get("scope", "cluster") == "namespaced"
    pool = cluster_rules + (role_rules if namespaced else [])
    where = "ClusterRole or Role" if namespaced else "ClusterRole"
    label = f"{group or 'core'}/{resource}"
    for verb in rule.get("verbs", []):
        if not granted(pool, group, resource, verb):
            failures.append(f"{label}: missing '{verb}' (required by the code; grant it in the {where})")
    for verb in rule.get("bestEffortVerbs", []):
        if granted(pool, group, resource, verb):
            failures.append(f"{label}: '{verb}' is granted but is best-effort only (least privilege; remove it or move it to verbs in core's contract)")
    allowed = set(rule.get("verbs", [])) | set(rule.get("bestEffortVerbs", []))
    extra = sorted(v for v in {x for r in pool
                                if (group in r.get("apiGroups", []) or "*" in r.get("apiGroups", []))
                                and (resource in r.get("resources", []))
                                for x in r.get("verbs", [])} if v not in allowed and v != "*")
    if extra:
        warnings.append(f"{label}: chart also grants {extra} which the typed calls do not use")

for w in warnings:
    print(f"WARN: {w}")
if failures:
    for f in failures:
        print(f"FAIL: {f}")
    sys.exit(1)
print(f"OK: rendered API RBAC satisfies core's rbac-contract ({len(contract['rules'])} resources checked, {len(warnings)} over-grant warnings)")
PY
