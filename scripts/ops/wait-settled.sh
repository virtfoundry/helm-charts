#!/usr/bin/env bash
# Waits until a rollout has settled, so the next merge or tag can go out.
# Rolling several Deployments at once on a small cluster can overload the CNI (see
# docs/guide/troubleshooting.md), so release one repository at a time and run this in between.
#
# Settled means, for MIN_QUIET seconds in a row: every pod in NS is Ready (Completed ignored),
# no pod is Terminating, every Deployment has all replicas updated and ready, and (when Argo CD
# is installed) every Application is Synced and Healthy.
#
#   NS=virtfoundry-system TIMEOUT=900 MIN_QUIET=30 scripts/ops/wait-settled.sh
set -uo pipefail

NS="${NS:-virtfoundry-system}"
TIMEOUT="${TIMEOUT:-900}"
MIN_QUIET="${MIN_QUIET:-30}"
INTERVAL=10

problems() {
  kubectl -n "$NS" get pods --no-headers 2>/dev/null \
    | awk '$3=="Completed"||$3=="Succeeded"{next} $3=="Terminating"{print "terminating: "$1; next} {split($2,r,"/")} $3!="Running"||r[1]!=r[2]{print "not ready: "$1" "$2" "$3}'
  kubectl -n "$NS" get deploy -o jsonpath='{range .items[*]}{.metadata.name}{" "}{.spec.replicas}{" "}{.status.updatedReplicas}{" "}{.status.readyReplicas}{"\n"}{end}' 2>/dev/null \
    | awk '$2!=$3||$2!=$4{print "rolling: "$1" want="$2" updated="$3" ready="$4}'
  if kubectl get crd applications.argoproj.io >/dev/null 2>&1; then
    kubectl -n argocd get app -o jsonpath='{range .items[*]}{.metadata.name}{" "}{.status.sync.status}{"/"}{.status.health.status}{"\n"}{end}' 2>/dev/null \
      | awk '$2!="Synced/Healthy"{print "argo: "$1" "$2}'
  fi
}

start=$SECONDS
quiet_since=""
while :; do
  out="$(problems)"
  if [ -z "$out" ]; then
    [ -n "$quiet_since" ] || quiet_since=$SECONDS
    if [ $((SECONDS - quiet_since)) -ge "$MIN_QUIET" ]; then
      echo "settled (quiet for ${MIN_QUIET}s, ${SECONDS}s elapsed since start)"
      exit 0
    fi
  else
    quiet_since=""
  fi
  if [ $((SECONDS - start)) -ge "$TIMEOUT" ]; then
    echo "NOT settled after ${TIMEOUT}s:" >&2
    echo "$out" >&2
    exit 1
  fi
  sleep "$INTERVAL"
done
