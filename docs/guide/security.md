# Security and credentials

What to know before you put VirtFoundry in front of other people.

## The short version

- **Nothing is exposed by default.** The chart creates `ClusterIP` Services. You choose how the console is reached ([Expose the UI and API](expose.md)).
- **Use HTTPS** for anything beyond a lab. Over HTTP the root password and every token travel in clear text.
- **There is one built-in admin, `root`.** Its password is set at install and cannot be changed in the console yet ([core#241](https://github.com/virtfoundry/core/issues/241)). The procedure is [below](#change-the-root-password).
- **`root` can do everything**, on every tenant. Create tenant users and API keys for daily work and keep `root` for administration.

## Where the credentials live

| What | Where | Set by |
|------|-------|--------|
| Root password, as you typed it | Secret `virtfoundry-secrets`, key `ROOT_PASSWORD` | `secrets.rootPassword` at install, or your own Secret with `secrets.existingSecret` |
| Root password, as the API checks it | Secret `vf-user-root`, key `password_hash` (bcrypt) | The API, on its first start |
| Token signing key | Secret `virtfoundry-secrets`, key `JWT_SECRET` | `secrets.jwtSecret` at install |

Both Secrets are in the release namespace (`virtfoundry-system`). Anyone who can read Secrets there can become `root`: restrict that with Kubernetes RBAC.

The API reads `ROOT_PASSWORD` in two cases only: to create `root` on the very first start, and to rebuild `vf-user-root` when that Secret is missing. **After the first start, changing `secrets.rootPassword` does not change the password you log in with.**

The API rejects a password shorter than 12 characters and the old default `virtfoundry`. That default is in the public history of this repository: if you ever ran with it, treat it as known to everyone.

## Change the root password

Write a new bcrypt hash into `vf-user-root`. It takes effect at once, without a restart.

```bash
NEW='a-new-strong-password'   # 12 characters or more

HASH=$(htpasswd -bnBC 10 "" "$NEW" | tr -d ':\n' | sed 's/^\$2y\$/$2a$/')
kubectl -n virtfoundry-system patch secret vf-user-root --type merge \
  -p "{\"data\":{\"password_hash\":\"$(printf %s "$HASH" | base64 | tr -d '\n')\"}}"
```

`htpasswd` comes with `apache2-utils` (Debian, Ubuntu) or `httpd-tools` (RHEL, Fedora) and is already on macOS.

Then store the same password in `virtfoundry-secrets`, so that a rebuild of `vf-user-root` uses the new one and not the old:

```bash
kubectl -n virtfoundry-system patch secret virtfoundry-secrets --type merge \
  -p "{\"data\":{\"ROOT_PASSWORD\":\"$(printf %s "$NEW" | base64 | tr -d '\n')\"}}"
```

With `secrets.existingSecret`, change the value where that Secret comes from (Vault, Sealed Secrets, …) instead of patching it.

Check that the new password works and the old one does not:

```bash
curl -s -o /dev/null -w '%{http_code}\n' -X POST https://iaas.example.com/api/v1/auth/login \
  -H 'Content-Type: application/json' -d "{\"username\":\"root\",\"password\":\"$NEW\"}"   # 200
```

Tokens issued before the change stay valid until they expire. To cut them off now, rotate the signing key as well.

## Rotate the token signing key

Change `JWT_SECRET` (32 characters or more) in `virtfoundry-secrets` and restart the API so it reads the new value:

```bash
kubectl -n virtfoundry-system patch secret virtfoundry-secrets --type merge \
  -p "{\"data\":{\"JWT_SECRET\":\"$(openssl rand -hex 32 | tr -d '\n' | base64 | tr -d '\n')\"}}"
kubectl -n virtfoundry-system rollout restart deploy/virtfoundry-api
```

Every session and every token stops working. Users log in again.

## GitOps

Do not put credentials in a values file in git. Create the Secret out of band (or with your secrets operator) and point the chart at it with `secrets.existingSecret`. See [Configuration](configuration.md#option-b-existingsecret-recommended-for-gitops).

## Terraform and scripts

Use an **API key** for automation, not the root password. The Terraform provider refuses an `http://` endpoint unless you set `insecure = true`, because the credential would be sent in clear text ([Terraform provider](terraform.md)).

## What VirtFoundry does not do for you

- TLS certificates: bring them through your Ingress or Gateway.
- Protecting the Kubernetes API: a cluster admin can read every Secret and every VM disk.
- Single sign-on and multi-factor login for the console.

Verified on 0.11.3: the root password procedure (the new password logs in, the old one and `virtfoundry` are refused). The signing key rotation is described from how the API reads its Secret and was not run on a live cluster for this page.
