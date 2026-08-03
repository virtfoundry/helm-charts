# Moved to VirtFoundry

**virtforge-chart** is now **[virtfoundry/helm-charts](https://github.com/virtfoundry/helm-charts)**.

Application source: **[virtfoundry/core](https://github.com/virtfoundry/core)**

```bash
helm repo add virtfoundry https://virtfoundry.github.io/helm-charts
helm install virtfoundry virtfoundry/virtfoundry --version 1.0.0 \
  -n virtfoundry-system --create-namespace
```

Docs: https://virtfoundry.github.io/helm-charts/docs/

This repo remains as a mirror until migration completes.
