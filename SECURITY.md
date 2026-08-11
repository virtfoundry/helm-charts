# Security Policy

Please follow the security process documented in [virtfoundry/core SECURITY.md](https://github.com/virtfoundry/core/blob/main/SECURITY.md).

**Do not open public GitHub issues for security vulnerabilities.**

Helm-specific notes:

- Never commit real `secrets.rootPassword` / `secrets.jwtSecret` values
- Prefer external secrets for non-lab installs
- Review RBAC templates under `charts/virtfoundry/templates/` before production
