# Scripts

Operational helpers for homelab and bare-metal installs. **Not part of the Helm chart** — kept separate so `helm install` stays portable and registry-agnostic.

## Layout

| Path | Purpose |
|------|---------|
| [`lib/common.sh`](lib/common.sh) | Shared `CHART_ROOT`, `KUBECONFIG`, `APP_ROOT` resolution |
| [`deploy/homelab.sh`](deploy/homelab.sh) | Build images → helm upgrade → optional containerd sideload |
| [`deploy/windows-test-vm.sh`](deploy/windows-test-vm.sh) | Optional Windows Server VM for storage IOPS testing |
| [`setup/kubevirt.sh`](setup/kubevirt.sh) | Install KubeVirt from stable release (idempotent) |
| [`setup/multus.sh`](setup/multus.sh) | Install or verify Multus CNI (`--ensure-only` to skip install) |
| [`setup/cdi.sh`](setup/cdi.sh) | Install CDI for ISO/DataVolume imports |
| [`sideload/ssh.sh`](sideload/ssh.sh) | Import images via SSH + `ctr` (requires `IMPORT_NODE`, `IMPORT_NODE_IP`) |
| [`sideload/import-pod.yaml`](sideload/import-pod.yaml) | Privileged pod fallback when SSH sideload is unavailable |

## Usage

Prefer **Makefile** targets from the repo root (`make help`).

Direct invocation:

```bash
export KUBECONFIG=/path/to/kubeconfig

./scripts/setup/kubevirt.sh
./scripts/deploy/homelab.sh

# SSH sideload (no registry):
IMPORT_NODE=worker-01 IMPORT_NODE_IP=10.0.0.11 ./scripts/sideload/ssh.sh
```

## Design notes

- Scripts never mutate in-cluster state beyond what their name implies.
- Homelab-specific defaults (node names, kubespray paths) are overridable via environment variables.
- Image sideloading is intentionally outside Helm — clusters without a registry should not need chart hooks for docker saves.
