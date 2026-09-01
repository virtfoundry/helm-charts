# Security Policy

Please follow the security process in [virtfoundry/core SECURITY.md](https://github.com/virtfoundry/core/blob/main/SECURITY.md) and [MAINTAINERS.md](https://github.com/virtfoundry/core/blob/main/MAINTAINERS.md).

**Do not open public GitHub issues for security vulnerabilities.**

Helm-specific notes:

- Never commit real `secrets.rootPassword` / `secrets.jwtSecret` values
- Prefer external secrets for non-lab installs
- Review RBAC under `charts/virtfoundry/` and `charts/virtfoundry-operator/` before production
