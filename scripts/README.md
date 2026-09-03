# Scripts

Operational helpers for bare-metal and air-gapped installs. **Not required** for a normal Helm install when you pull images from GHCR or another registry.

## Who needs what

| Audience | What to use |
|----------|-------------|
| **Most users** | `helm install` / `helm upgrade` only — see root [README.md](../README.md) |
| **No registry (sideload)** | [`sideload/`](sideload/) |
| **Pre-install prerequisites** | [`setup/kubevirt.sh`](setup/kubevirt.sh) — or install KubeVirt yourself |
| **Multus / CDI** | Prefer Helm values `platform.multus.install` / `platform.cdi.install`, or run [`setup/multus.sh`](setup/multus.sh) / [`setup/cdi.sh`](setup/cdi.sh) manually before helm |

## Layout

| Path | Purpose |
|------|---------|
| [`lib/common.sh`](lib/common.sh) | Shared paths; requires `KUBECONFIG` |
| [`dev/render-local-config.sh`](dev/render-local-config.sh) | Render `virtfoundry/config/config.yaml` from Helm values |
| [`setup/kubevirt.sh`](setup/kubevirt.sh) | Install KubeVirt from stable release (idempotent) |
| [`setup/multus.sh`](setup/multus.sh) | Install or verify Multus CNI |
| [`setup/cdi.sh`](setup/cdi.sh) | Install CDI for ISO/DataVolume imports |
| [`sideload/ssh.sh`](sideload/ssh.sh) | Import images via SSH + `ctr` |
| [`detect-host-public-net.sh`](detect-host-public-net.sh) | Print a `platform.networking.public` values snippet from Node InternalIP / host default route |

## Usage

```bash
export KUBECONFIG=/path/to/kubeconfig

make lint              # validate chart templates
```

Direct sideload (no registry):

```bash
IMPORT_NODE=worker-01 IMPORT_NODE_IP=10.0.0.11 ./scripts/sideload/ssh.sh
```
