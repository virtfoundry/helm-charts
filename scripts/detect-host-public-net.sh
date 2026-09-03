#!/usr/bin/env bash
# Print a Helm values snippet for platform.networking.public from this host or cluster.
# Does not enable public or set uplink — those are still operator choices (see docs).
set -euo pipefail

cidr=""
gateway=""
node_ip=""

if command -v kubectl >/dev/null 2>&1 && kubectl get nodes >/dev/null 2>&1; then
  node_ip=$(kubectl get nodes -o jsonpath='{range .items[*]}{range .status.addresses[?(@.type=="InternalIP")]}{.address}{"\n"}{end}{end}' \
    | grep -E '^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$' | head -1 || true)
fi

if [ -z "$node_ip" ] && command -v ip >/dev/null 2>&1; then
  node_ip=$(ip -4 route get 1.1.1.1 2>/dev/null | awk '{for (i=1;i<=NF;i++) if ($i=="src") print $(i+1)}' | head -1 || true)
  gateway=$(ip -4 route show default 2>/dev/null | awk '{for (i=1;i<=NF;i++) if ($i=="via") print $(i+1)}' | head -1 || true)
fi

if [ -z "$node_ip" ]; then
  echo "Could not detect a node IPv4. Set platform.networking.public.* by hand." >&2
  exit 1
fi

IFS=. read -r a b c d <<EOF
$node_ip
EOF
cidr="${a}.${b}.${c}.0/24"
: "${gateway:=${a}.${b}.${c}.1}"
start="${a}.${b}.${c}.20"
end="${a}.${b}.${c}.80"

cat <<EOF
# Generated from host/cluster IPv4 ${node_ip}
# Review gateway vs your router. Do NOT set uplink to the Kubernetes NIC.
# Enable public only after you have a second NIC, VLAN iface, or existing br0.
platform:
  networking:
    public:
      autoFromCluster: false
      cidr: ${cidr}
      gateway: ${gateway}
      dns:
        - ${gateway}
      ipPool:
        start: ${start}
        end: ${end}
EOF
