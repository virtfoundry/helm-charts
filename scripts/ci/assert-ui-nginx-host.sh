#!/usr/bin/env bash
# The UI nginx must forward the Host header WITH its port. The API compares the browser Origin
# (host:port) with the request Host for WebSocket upgrades, so "Host $host" (no port) made every
# /ws/events upgrade a 403 when the UI was served on a non-default port, such as the quickstart's
# kubectl port-forward 8080:80.
set -euo pipefail
cd "$(dirname "$0")/../.."

out="$(helm template virtfoundry charts/virtfoundry -n virtfoundry-system \
  --set-string secrets.rootPassword=ci-render-only-password \
  --set-string secrets.jwtSecret=ci-render-only-jwt-secret-0123456789abcdef)"

if grep -qE 'proxy_set_header[[:space:]]+Host[[:space:]]+\$host[[:space:]]*;' <<<"$out"; then
  echo 'FAIL: the UI nginx sends "Host $host" (no port) to the API; use $http_host' >&2
  exit 1
fi
n="$(grep -cE 'proxy_set_header[[:space:]]+Host[[:space:]]+\$http_host[[:space:]]*;' <<<"$out" || true)"
if [ "$n" -lt 2 ]; then
  echo "FAIL: expected \$http_host in both the /api/ and /ws/ locations, found $n" >&2
  exit 1
fi
echo "OK: the UI nginx keeps the port in the Host header ($n locations)"
