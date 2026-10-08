# Expose the UI and API

The chart creates `ClusterIP` Services only. Nothing is reachable from outside the cluster until you choose one of the paths below. The UI Service (`virtfoundry-ui`, port 80) is the single entry point: its nginx serves the console and proxies `/api/` and `/ws/` to the API, so you expose **one** host.

| Path | Use it for | TLS |
|------|-----------|-----|
| [Port-forward](#port-forward) | First login, a quick look | No (local only) |
| [Ingress](#ingress) | A cluster with an Ingress controller | Yes, required by default |
| [Gateway API](#gateway-api) | A cluster with a Gateway (Traefik, Envoy, Cilium, …) | On the Gateway listener |

Enable **one** of Ingress or Gateway, not both.

!!! note "Values prefix"
    The examples use the standalone `virtfoundry` chart. With the one-release install (`virtfoundry-platform`), put the same keys under `core.`: `--set core.gateway.enabled=true`, and upgrade `virtfoundry/virtfoundry-platform`.

## Port-forward

```bash
kubectl -n virtfoundry-system port-forward svc/virtfoundry-ui 8080:80
```

Open <http://127.0.0.1:8080>. This needs chart **0.11.3 or newer**: on older charts the realtime updates and the console fail on a non-default port ([Troubleshooting](troubleshooting.md)).

## Ingress

The chart refuses to create an Ingress without TLS. Bring a certificate Secret, or let cert-manager create it:

```bash
helm upgrade virtfoundry virtfoundry/virtfoundry -n virtfoundry-system --reuse-values \
  --set ingress.enabled=true \
  --set ingress.className=nginx \
  --set ingress.host=iaas.example.com \
  --set 'ingress.tls[0].secretName=virtfoundry-tls' \
  --set 'ingress.tls[0].hosts[0]=iaas.example.com' \
  --set-string 'ingress.annotations.cert-manager\.io/cluster-issuer=letsencrypt-prod'
```

Drop the last line when the Secret already exists. For a lab without TLS, replace the two `ingress.tls` lines with `--set ingress.allowCleartext=true`. Passwords and tokens then travel in clear text: do not do this on a network you do not control.

## Gateway API

The chart creates an `HTTPRoute` and attaches it to **your** Gateway. The certificate lives on the Gateway listener, not in the chart.

```bash
helm upgrade virtfoundry virtfoundry/virtfoundry -n virtfoundry-system --reuse-values \
  --set gateway.enabled=true \
  --set 'gateway.parentRefs[0].name=my-gateway' \
  --set 'gateway.parentRefs[0].namespace=gateway-system' \
  --set 'gateway.parentRefs[0].sectionName=websecure' \
  --set 'gateway.hostnames[0]=iaas.example.com'
```

`sectionName` is the name of the listener on your Gateway. Use the HTTPS listener. Binding the cleartext listener (often `web`) serves the console over HTTP, which is fine for a lab only. For an HTTP to HTTPS redirect see [Configuration](configuration.md#gateway-api-https).

## What your proxy must do

The console keeps two WebSocket connections open (`/ws/events` for live updates, `/ws/console` for the VM console). Whatever sits in front of the UI Service has to:

- Pass the WebSocket upgrade (`Upgrade` and `Connection` headers). Ingress-nginx, Traefik and Gateway API implementations do this by default.
- Keep the `Host` header as the browser sent it, **including the port**. The API compares it with the `Origin` header and answers 403 when they differ.
- Allow long-lived connections. The chart sets one-hour read and send timeouts for ingress-nginx; set the equivalent on other proxies, or the console disconnects.

Serving the UI and the API from **different** hosts is the only case that needs `api.security.allowedOrigins` ([Configuration](configuration.md#allowed-origins-cors-websockets)).

## Check it

```bash
curl -fsS https://iaas.example.com/api/v1/healthz
# {"status":"ok","service":"virtfoundry-iaas","hypervisor":"kubevirt"}
```

Then log in and open the browser console: there must be no `WebSocket connection ... failed` line. If there is one, go to [Troubleshooting](troubleshooting.md).

Tested: port-forward and Gateway API (HTTP listener, Traefik) on the reference cluster with 0.11.3. The Ingress examples are checked by rendering the chart, not on a live Ingress controller.
