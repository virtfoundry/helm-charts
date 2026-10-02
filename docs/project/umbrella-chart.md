# Future platform umbrella chart (`virtfoundry-platform`)

**Status:** Design only — **not shipped in 0.9.x**. Install and GitOps paths stay unchanged until a dedicated release cuts the umbrella chart and migrates Argo Applications.

## 0.9.x (current)

VirtFoundry **0.9.x** ships and deploys as **three independent Helm charts** and **three Argo CD Applications** (homelab and docs assume this model):

| Order | Helm chart | Typical Argo Application | Namespace |
|-------|------------|--------------------------|-----------|
| 1 | `virtfoundry-operator` | `virtfoundry-operator` | `virtfoundry-system` |
| 2 | `virtfoundry` (core API + UI) | `virtfoundry` | `virtfoundry-system` |
| 3 | `virtfoundry-vks` | `virtfoundry-vks` | `virtfoundry-system` |

Install docs, [Versioning](versioning.md), and sync waves (operator before core before VKS) remain **operator-first, three releases**. No umbrella chart is published to the Helm index in 0.9.x.

The VKS chart source today lives in the [`virtfoundry/vks`](https://github.com/virtfoundry/vks) repository (`charts/virtfoundry-vks`); operator and core charts live in [`virtfoundry/helm-charts`](https://github.com/virtfoundry/helm-charts). A future umbrella release may vendor or depend on packaged charts from one or both repos — details TBD when the chart is implemented.

## Future: `virtfoundry-platform`

**Chart name (locked):** `virtfoundry-platform`

**Type:** Umbrella (`type: application`) with Helm **dependencies** on the three application charts, pinned to the **same product version** (e.g. `0.10.0` across operator, core, and VKS).

Sketch of `Chart.yaml`:

```yaml
apiVersion: v2
name: virtfoundry-platform
description: VirtFoundry platform — operator, core, and VKS in one release
type: application
version: 0.10.0
appVersion: "0.10.0"
dependencies:
  - name: virtfoundry-operator
    version: 0.10.0
    repository: https://virtfoundry.github.io/helm-charts
    alias: operator
  - name: virtfoundry
    version: 0.10.0
    repository: https://virtfoundry.github.io/helm-charts
    alias: core
  - name: virtfoundry-vks
    version: 0.10.0
    repository: https://virtfoundry.github.io/helm-charts  # or OCI/repo TBD
    alias: vks
```

Aliases map subchart values to stable top-level keys (see below). Exact `repository` URLs and whether `virtfoundry-vks` is co-packaged in `helm-charts` will be decided when the chart is added.

### Nested values keys

Umbrella `values.yaml` passes configuration to subcharts under **`operator`**, **`core`**, and **`vks`** (via dependency aliases):

```yaml
operator:
  # virtfoundry-operator values (CRDs, controller image, watch scope, …)

core:
  # virtfoundry chart values (API/UI images, secrets, store, ingress, …)

vks:
  # virtfoundry-vks values (VKS controller, Kamaji/CAPI settings, …)
```

Homelab overlays today split across `values-operator-homelab.yaml`, `values-homelab.yaml`, and VKS homelab values — a migration flattens those into one file (or one Argo `$values` ref) with the three keys above.

**Install order** is still operator → core → VKS; the umbrella chart should encode that with Helm **`dependencies` conditions** and/or **`tags`** if any component is optional, matching current sync-wave semantics.

### CRD upgrade caveat (unchanged)

**Helm does not upgrade CRDs** on `helm upgrade` when CRDs are installed from chart templates (the default Helm CRD behavior). That limitation **does not go away** with an umbrella chart:

- **`virtfoundry.io` CRDs** remain owned by the **operator** subchart (or an explicit CRD install Job documented in operator release notes).
- Platform upgrades that change CRD schemas still require the **same manual or scripted CRD apply** process as today (apply new CRD manifests, then upgrade the release), unless the project ships a supported automation path in operator docs.

Treat umbrella installs as **one Helm release** for app manifests, but **not** as “CRDs always roll forward automatically.”

## GitOps migration sketch

Target: **one Argo CD Application** (e.g. `virtfoundry-platform`) instead of three, without a big-bang cutover on the first day.

1. **Implement** `charts/virtfoundry-platform` in `helm-charts`, publish to the Helm index, document nested values and CRD steps in release notes.
2. **Add** a new Argo Application pointing at `virtfoundry-platform` with merged homelab values (`operator` / `core` / `vks` keys). Use sync waves or Helm dependency order so operator still lands before core and VKS.
3. **Validate** on homelab: CRDs, core API/UI, VKS controller, existing clusters unchanged; compare rendered manifests with the three-chart baseline where possible.
4. **Cut over** traffic and ops runbooks to the single Application; disable auto-sync on the legacy Apps.
5. **Retire** Applications `virtfoundry-operator`, `virtfoundry`, and `virtfoundry-vks` after a soak period; remove duplicate releases only when sure Helm history and ownership do not fight (same release name / namespace strategy must be planned to avoid double-install).

Until step 5 completes, **0.9.x documentation and support** continue to describe three separate `helm install` / three Applications.

## Related

- [Versioning](versioning.md) — release line and install pins
- [Configuration guide](../guide/configuration.md) — operator-first install and values
- Homelab Apps (reference): `argo-homelab` `apps/virtfoundry-operator.yaml`, `apps/virtfoundry.yaml`, `apps/virtfoundry-vks.yaml`
