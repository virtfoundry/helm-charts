# virtfoundry-crds

The `virtfoundry.io` CustomResourceDefinitions as a Helm chart, so `helm upgrade` updates them.

Every CRD carries `helm.sh/resource-policy: keep` and the Argo CD option `Prune=false,Delete=false`. Deleting a CRD deletes all its custom resources.

`manifests/` is copied verbatim from `virtfoundry/operator` (15 CRDs) and `virtfoundry/vks` (`VKSCluster`). Do not edit it by hand: run `make sync-crds-chart`. CI (`make verify-crds-chart`) fails on drift.

Install order, adopting existing CRDs and Argo CD notes: [CRDs and upgrades](https://virtfoundry.github.io/helm-charts/docs/guide/crds/).
