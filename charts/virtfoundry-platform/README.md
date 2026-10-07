# virtfoundry-platform

One Helm release for the VirtFoundry control plane: the operator, core (API + UI) and, optionally, VKS.

| Subchart | Values key | Default |
|----------|------------|---------|
| `virtfoundry-operator` | `operator` | enabled |
| `virtfoundry` (API + UI) | `core` | enabled |
| `virtfoundry-vks` | `vks` | **disabled** |

Kamaji and the platform prerequisites (KubeVirt, Multus, CDI, storage) are **not** part of this chart. See [Platform prerequisites](https://virtfoundry.github.io/helm-charts/docs/guide/prerequisites/).

Install the CRDs first ([CRDs and upgrades](https://virtfoundry.github.io/helm-charts/docs/guide/crds/)); this chart does not include them.

```bash
helm repo add virtfoundry https://virtfoundry.github.io/helm-charts
helm install virtfoundry-crds virtfoundry/virtfoundry-crds --version 0.11.2 -n virtfoundry-system --create-namespace
helm install virtfoundry virtfoundry/virtfoundry-platform \
  --version 0.11.2 -n virtfoundry-system \
  --set-string core.secrets.rootPassword='...' \
  --set-string core.secrets.jwtSecret="$(openssl rand -hex 32)"
```

Enable VKS after Kamaji is installed: `--set vks.enabled=true`.

Values are the standalone charts' values, nested under `operator`, `core` and `vks`. Resource names are identical to the standalone charts (`make verify-platform-parity` checks this), so an existing install can be adopted.

Helm does not upgrade CRDs. The CRD limitation of the standalone charts applies here too.
