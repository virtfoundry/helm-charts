# Security Policy

Please follow the security process in [virtfoundry/core SECURITY.md](https://github.com/virtfoundry/core/blob/main/SECURITY.md) and [MAINTAINERS.md](https://github.com/virtfoundry/core/blob/main/MAINTAINERS.md).

**Do not open public GitHub issues for security vulnerabilities.**

Helm-specific notes:

- Never commit real `secrets.rootPassword` / `secrets.jwtSecret` values
- The chart ships no credential defaults and refuses to render without them; do not add any
- Prefer `secrets.existingSecret` with an external secrets tool for non-lab installs
- Do not enable Ingress without TLS (`ingress.tls` or cert-manager annotations); `ingress.enabled` defaults to `false`
- Leave `api.security.allowedOrigins` empty for same-origin UI→API proxy; set it for split UI/API origins only
- API/UI pods ship Restricted-PSS-oriented contexts (non-root, drop ALL, seccomp RuntimeDefault, readOnlyRootFilesystem). UI does not mount a ServiceAccount token
- Tighten `networkPolicy.allowedIngressNamespaces` when you know the Ingress/Gateway namespaces; leave empty to allow any namespace to the HTTP ports
- Review RBAC under `charts/virtfoundry/` and `charts/virtfoundry-operator/` before production
