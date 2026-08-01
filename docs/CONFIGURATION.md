# Configuration

VirtForge runtime config is YAML with sections: `server`, `logger`, `security`, `kubevirt`, `database`, `observability`.

**In Kubernetes, this repo is the source of truth.** Helm renders `templates/configmap.yaml` from `values.yaml` (or a profile like `values-homelab.yaml`).

## Values → ConfigMap

| Helm value | Config field | Notes |
|------------|--------------|-------|
| `config.logLevel` | `logger.level` | |
| `config.jwtExpire` | `security.jwt_expire` | |
| `config.kubevirtEnabled` | `kubevirt.enabled` | |
| `mysql.auth.*` | `database.dsn` | Built in template when MySQL enabled |
| `secrets.jwtSecret` | — | **Not** in ConfigMap; injected as `JWT_SECRET` env on API |
| `secrets.rootPassword` | — | **Not** in ConfigMap; injected as `ROOT_PASSWORD` env on API |

## Profiles

| File | Use case |
|------|----------|
| [`values.yaml`](../charts/virtforge/values.yaml) | Generic / production defaults |
| [`values-homelab.yaml`](../charts/virtforge/values-homelab.yaml) | Homelab: Gateway API, GHCR images, platform hooks |

## Local dev parity

To generate `virtforge/config/config.yaml` from Helm values (sibling repo layout):

```bash
make render-local-config
make render-local-config VALUES=./charts/virtforge/values-homelab.yaml
```

Or set `APP_CONFIG=/path/to/config.yaml` when repos are not siblings.

## Secrets

Never commit real secrets in values files. Use:

```bash
helm upgrade --install virtforge ./charts/virtforge \
  --set secrets.jwtSecret='...' \
  --set secrets.rootPassword='...'
```

Or `--set-file` / external secret management in production.
