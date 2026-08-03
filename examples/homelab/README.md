# Homelab examples

Optional workflows for bare-metal / homelab clusters. **Not required** for a standard Helm install with a container registry.

| File | Purpose |
|------|---------|
| [`windows-iops-test-vm.sh`](windows-iops-test-vm.sh) | Deploy a Windows Server eval VM for storage IOPS benchmarking |

## Usage

```bash
export KUBECONFIG=/path/to/kubeconfig
KUBE_CONTEXT=my-cluster TENANT_NS=virtfoundry-tenant-acme ./windows-iops-test-vm.sh
```

Requires VirtFoundry already deployed, CDI, and a tenant namespace.
