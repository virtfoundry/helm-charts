#!/usr/bin/env bash
# End-to-end checks of the chart install flow on a THROWAWAY cluster (Kind in CI).
# Only Helm and the API server are exercised: no KubeVirt, no nodes needed, so
# workloads are never waited for (except in the quickstart scenario, which waits for the
# control plane pods; it still cannot deploy a VM without KubeVirt).
#
#   e2e-charts.sh fresh     crds -> operator -> core from the local charts
#   e2e-charts.sh umbrella  crds -> virtfoundry-platform (local, pulls the VKS OCI chart)
#   e2e-charts.sh quickstart  the commands of docs/guide/quickstart.md, then pods ready, health and login
#   e2e-charts.sh migrate   0.10.x operator chart owns the CRDs -> adopt -> CRD chart -> operator
#                           without crds/ -> uninstall the CRD release; data must survive
#
# Safety: refuses any API server that is not on localhost.
set -euo pipefail
cd "$(dirname "${BASH_SOURCE[0]}")/../.."

NS=virtfoundry-system
OLD_OPERATOR_VERSION="${OLD_OPERATOR_VERSION:-0.10.0}"
ROOT=e2e-render-only-password
JWT=e2e-render-only-jwt-secret-0123456789abcdef
EXPECTED_CRDS=16

if [ "${1:-}" != print-quickstart ]; then # print-quickstart touches no cluster
  server="$(kubectl config view --minify -o jsonpath='{.clusters[0].cluster.server}')"
  case "$server" in
    https://127.0.0.1:*|https://localhost:*|https://\[::1\]:*) ;;
    *) echo "REFUSING: API server $server is not local. This script deletes CRDs." >&2; exit 2 ;;
  esac
fi

fail() { echo "FAIL: $*" >&2; exit 1; }
ok()   { echo "OK: $*"; }
crd_count() { kubectl get crd -o name | grep -c '\.virtfoundry\.io$' || true; }
secrets=(--set-string "secrets.rootPassword=$ROOT" --set-string "secrets.jwtSecret=$JWT")
# The core chart patches the KubeVirt CR in a post-install Job by default; there is no KubeVirt here.
no_kubevirt=(--set platform.kubevirt.cpuAllocationRatio=0 --set platform.kubevirt.featureGates.enabled=false)

reset() { # no releases and no CRDs (the namespace stays: Kind jobs start on a fresh cluster)
  helm list -n "$NS" -q 2>/dev/null | xargs -r -n1 helm uninstall -n "$NS" >/dev/null 2>&1 || true
  kubectl get crd -o name | grep '\.virtfoundry\.io$' | xargs -r kubectl delete --wait=false >/dev/null 2>&1 || true
  for _ in $(seq 1 30); do [ "$(crd_count)" = 0 ] && break; sleep 2; done
}

new_tenant() {
  kubectl apply -f - >/dev/null <<EOF
apiVersion: virtfoundry.io/v1alpha1
kind: Tenant
metadata: { name: e2e }
spec: { name: E2E, slug: e2e }
EOF
}

scenario_fresh() {
  helm install virtfoundry-crds charts/virtfoundry-crds -n "$NS" --create-namespace >/dev/null
  [ "$(crd_count)" = "$EXPECTED_CRDS" ] || fail "expected $EXPECTED_CRDS CRDs after the CRD chart, got $(crd_count)"
  ok "CRD chart installs $EXPECTED_CRDS CRDs"
  helm install virtfoundry-operator charts/virtfoundry-operator -n "$NS" >/dev/null
  # *.tgz subchart tarballs are gitignored, so the e2e runner downloads
  # them on demand. Required as long as the chart declares `dependencies:`.
  helm repo add metrics-server https://kubernetes-sigs.github.io/metrics-server >/dev/null 2>&1 || true
  helm dependency update charts/virtfoundry >/dev/null
  helm install virtfoundry charts/virtfoundry -n "$NS" "${secrets[@]}" "${no_kubevirt[@]}" >/dev/null
  [ "$(helm list -n "$NS" --deployed -q | wc -l | tr -d ' ')" = 3 ] || fail "expected 3 deployed releases"
  ok "crds, operator and core releases deployed"
  [ "$(helm get manifest virtfoundry-operator -n "$NS" | grep -c '^kind: CustomResourceDefinition')" = 0 ] \
    || fail "the operator chart must not ship CRDs"
  ok "operator chart ships no CRDs"
  new_tenant && kubectl get tenants.virtfoundry.io e2e >/dev/null && ok "a Tenant can be created"
  helm uninstall virtfoundry-crds -n "$NS" >/dev/null
  [ "$(crd_count)" = "$EXPECTED_CRDS" ] || fail "helm uninstall removed CRDs"
  kubectl get tenants.virtfoundry.io e2e >/dev/null || fail "helm uninstall removed data"
  ok "helm uninstall of the CRD release keeps the CRDs and the Tenant"
}

scenario_umbrella() {
  helm install virtfoundry-crds charts/virtfoundry-crds -n "$NS" --create-namespace >/dev/null
  helm dependency update charts/virtfoundry-platform >/dev/null
  helm install platform charts/virtfoundry-platform -n "$NS" \
    --set-string "core.secrets.rootPassword=$ROOT" --set-string "core.secrets.jwtSecret=$JWT" \
    --set core.platform.kubevirt.cpuAllocationRatio=0 --set core.platform.kubevirt.featureGates.enabled=false >/dev/null
  [ "$(helm get manifest platform -n "$NS" | grep -c '^kind: CustomResourceDefinition')" = 0 ] \
    || fail "the umbrella chart must not ship CRDs"
  [ "$(crd_count)" = "$EXPECTED_CRDS" ] || fail "expected $EXPECTED_CRDS CRDs, got $(crd_count)"
  ok "umbrella chart installs on top of the CRD chart, ships no CRDs"
}

prereq_crds() { # the CRDs the quickstart asks for in step 0, without their controllers
  # Schema-less stubs: enough for the control plane to start and write its objects.
  # Nothing reconciles them, so no VM can run on this cluster.
  local group version kind plural
  while read -r group version kind plural; do
    kubectl apply -f - >/dev/null <<EOF
apiVersion: apiextensions.k8s.io/v1
kind: CustomResourceDefinition
metadata: { name: $plural.$group }
spec:
  group: $group
  scope: Namespaced
  names: { kind: $kind, plural: $plural, singular: $(echo "$kind" | tr '[:upper:]' '[:lower:]') }
  versions:
    - name: $version
      served: true
      storage: true
      subresources: { status: {} }
      schema: { openAPIV3Schema: { type: object, x-kubernetes-preserve-unknown-fields: true } }
EOF
  done <<'CRDS'
k8s.cni.cncf.io v1 NetworkAttachmentDefinition network-attachment-definitions
kubevirt.io v1 VirtualMachine virtualmachines
kubevirt.io v1 VirtualMachineInstance virtualmachineinstances
cdi.kubevirt.io v1beta1 DataVolume datavolumes
snapshot.kubevirt.io v1beta1 VirtualMachineSnapshot virtualmachinesnapshots
CRDS
  kubectl wait --for=condition=Established crd --timeout=60s \
    network-attachment-definitions.k8s.cni.cncf.io virtualmachines.kubevirt.io datavolumes.cdi.kubevirt.io >/dev/null
}

quickstart_install() { # the documented install commands, pointed at the local charts
  # Changes to what the reader copies: no "helm repo", local charts instead of the published
  # version, and no KubeVirt patch Job (there is no KubeVirt on this cluster).
  python3 - <<'PY'
import re
s = open("docs/guide/quickstart.md").read()
block = re.search(r"```bash\n(.*?)```", s[s.index("## 1. Install VirtFoundry"):], re.S).group(1)
lines = [l for l in block.splitlines()
         if not re.match(r"helm repo (add|update)", l) and not re.match(r" *--version [0-9.]+ \\$", l)]
out = re.sub(r"virtfoundry/(virtfoundry[a-z-]*)", r"charts/\1", "\n".join(lines)).strip()
print(out + " \\\n  --set core.platform.kubevirt.cpuAllocationRatio=0 --set core.platform.kubevirt.featureGates.enabled=false")
PY
}

doc_prereq_crds() { # the CRD names step 0 of the quickstart tells the reader to check
  grep -oE '^kubectl get crd [a-z0-9.-]+' docs/guide/quickstart.md | awk '{print $4}'
}

scenario_quickstart() {
  local doc=docs/guide/quickstart.md install pf health pass token pid
  install="$(quickstart_install)"
  for want in 'helm install virtfoundry-crds charts/virtfoundry-crds' 'charts/virtfoundry-platform' 'core.secrets.rootPassword'; do
    grep -qF -- "$want" <<<"$install" || fail "the quickstart install block changed shape (no \"$want\"): update scripts/ci/e2e-charts.sh"
  done
  pf="$(grep -m1 -oE 'kubectl -n virtfoundry-system port-forward svc/[a-z-]+ [0-9]+:[0-9]+' "$doc")" || fail "no port-forward command in the quickstart"
  health="$(grep -m1 -oE 'curl -fsS http://127\.0\.0\.1:[0-9]+/[a-z0-9/]+' "$doc")" || fail "no health check command in the quickstart"
  pass="$(grep -m1 -oE "rootPassword='[^']+'" "$doc" | cut -d"'" -f2)"

  prereq_crds
  for c in $(doc_prereq_crds); do kubectl get crd "$c" >/dev/null || fail "quickstart step 0 asks for CRD $c, which the test cluster lacks"; done
  ok "prerequisite CRDs from quickstart step 0 exist (stubs, no controllers)"
  helm dependency update charts/virtfoundry-platform >/dev/null
  bash -euo pipefail -c "$install" >/dev/null || fail "the quickstart install commands failed"
  [ "$(helm list -n "$NS" --deployed -q | wc -l | tr -d ' ')" = 2 ] || fail "expected 2 deployed releases (crds, virtfoundry)"
  ok "quickstart install commands run: crds + one platform release"

  for d in $(kubectl -n "$NS" get deploy -o name); do
    kubectl -n "$NS" rollout status "$d" --timeout=300s >/dev/null \
      || { kubectl -n "$NS" get pods; kubectl -n "$NS" logs "$d" --tail=40 --previous 2>/dev/null || kubectl -n "$NS" logs "$d" --tail=40; fail "$d did not become ready"; }
  done
  ok "control plane pods ready: $(kubectl -n "$NS" get deploy -o name | tr '\n' ' ')"

  $pf >/dev/null 2>&1 & pid=$!
  trap 'kill $pid 2>/dev/null || true' RETURN
  for _ in $(seq 1 30); do $health >/dev/null 2>&1 && break; sleep 2; done
  $health | grep -q '"status":"ok"' || fail "health check from the quickstart did not answer ok: $health"
  ok "documented health check answers ok"

  token="$(curl -fsS -X POST "$(grep -oE 'http://[0-9.]+:[0-9]+' <<<"$health")/api/v1/auth/login" -H 'Content-Type: application/json' \
    -d "{\"username\":\"root\",\"password\":\"$pass\"}" | python3 -c 'import sys,json; print(json.load(sys.stdin).get("token",""))')"
  [ -n "$token" ] || fail "login as root with the documented password failed"
  ok "login as root with the documented password works"
}

scenario_migrate() {
  helm repo add virtfoundry https://virtfoundry.github.io/helm-charts --force-update >/dev/null
  helm repo update virtfoundry >/dev/null
  helm install virtfoundry-operator virtfoundry/virtfoundry-operator --version "$OLD_OPERATOR_VERSION" \
    -n "$NS" --create-namespace >/dev/null
  old="$(crd_count)"; [ "$old" -ge 15 ] || fail "the old operator chart should install CRDs, got $old"
  ok "operator $OLD_OPERATOR_VERSION installed $old CRDs"
  new_tenant; kubectl get tenants.virtfoundry.io e2e >/dev/null

  if helm install virtfoundry-crds charts/virtfoundry-crds -n "$NS" >/dev/null 2>&1; then
    fail "the CRD chart must refuse CRDs it does not own"
  fi
  ok "CRD chart refuses to take over un-adopted CRDs"

  for crd in $(kubectl get crd -o name | grep '\.virtfoundry\.io$'); do
    kubectl annotate "$crd" meta.helm.sh/release-name=virtfoundry-crds meta.helm.sh/release-namespace="$NS" --overwrite >/dev/null
    kubectl label "$crd" app.kubernetes.io/managed-by=Helm --overwrite >/dev/null
  done
  helm install virtfoundry-crds charts/virtfoundry-crds -n "$NS" >/dev/null
  [ "$(crd_count)" = "$EXPECTED_CRDS" ] || fail "expected $EXPECTED_CRDS CRDs after adoption"
  ok "adoption + CRD chart: $EXPECTED_CRDS CRDs"

  helm upgrade virtfoundry-operator charts/virtfoundry-operator -n "$NS" >/dev/null
  [ "$(crd_count)" = "$EXPECTED_CRDS" ] || fail "operator upgrade changed the CRDs"
  kubectl get tenants.virtfoundry.io e2e >/dev/null || fail "operator upgrade lost data"
  ok "operator moved to the chart without crds/; CRDs and Tenant intact"

  # A schema change in the CRD chart must reach the cluster through helm upgrade.
  tmp="$(mktemp -d)"; trap 'rm -rf "$tmp"' EXIT
  cp -R charts/virtfoundry-crds "$tmp/crds"
  python3 - "$tmp/crds/manifests/virtfoundry.io_tenants.yaml" <<'PY'
import sys, yaml
p = sys.argv[1]
d = yaml.safe_load(open(p))
d["spec"]["versions"][0]["schema"]["openAPIV3Schema"]["properties"]["spec"]["properties"]["e2eField"] = {"type": "string"}
open(p, "w").write(yaml.safe_dump(d))
PY
  helm upgrade virtfoundry-crds "$tmp/crds" -n "$NS" >/dev/null
  kubectl get crd tenants.virtfoundry.io -o jsonpath='{.spec.versions[0].schema.openAPIV3Schema.properties.spec.properties}' \
    | grep -q e2eField || fail "helm upgrade did not propagate the CRD schema change"
  helm upgrade virtfoundry-crds charts/virtfoundry-crds -n "$NS" >/dev/null
  ok "helm upgrade propagates CRD schema changes"

  helm uninstall virtfoundry-crds -n "$NS" >/dev/null
  [ "$(crd_count)" = "$EXPECTED_CRDS" ] || fail "helm uninstall removed CRDs"
  kubectl get tenants.virtfoundry.io e2e >/dev/null || fail "helm uninstall removed data"
  ok "helm uninstall of the CRD release keeps the CRDs and the Tenant"
}

case "${1:-}" in
  fresh|umbrella|migrate|quickstart) reset; "scenario_$1"; echo "PASS: $1" ;;
  print-quickstart) quickstart_install ;; # what the quickstart scenario would run, without a cluster
  *) echo "usage: $0 fresh|umbrella|migrate|quickstart|print-quickstart" >&2; exit 64 ;;
esac
