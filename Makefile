.PHONY: help lint template security-gates verify-operator-chart-rbac verify-operator-chart-drift verify-api-rbac-contract verify-crds-chart sync-crds-chart verify-platform-parity e2e-charts setup-kubevirt setup-multus setup-cdi render-local-config docs-build docs-serve

CHART := ./charts/virtfoundry
OPERATOR_CHART := ./charts/virtfoundry-operator

# Throwaway render-only credentials. The chart ships no defaults and fails to render
# without them (helm-charts#37) — never reuse these on a cluster.
RENDER_ROOT_PASSWORD ?= render-only-password
RENDER_JWT_SECRET ?= render-only-jwt-secret-0123456789abcdef
RENDER_SECRETS := --set-string secrets.rootPassword=$(RENDER_ROOT_PASSWORD) --set-string secrets.jwtSecret=$(RENDER_JWT_SECRET)

help: ## Show available targets
	@grep -E '^[a-zA-Z0-9_-]+:.*##' Makefile | awk 'BEGIN {FS = ":.*## "}; {printf "  %-22s %s\n", $$1, $$2}'

lint: template security-gates verify-operator-chart-rbac ## Validate chart renders + security gates

template: ## Render Helm templates locally
	helm lint $(CHART) $(RENDER_SECRETS)
	helm lint $(OPERATOR_CHART)
	./scripts/ci/assert-secrets-fail-closed.sh
	./scripts/ci/assert-ui-nginx-host.sh
	helm template virtfoundry $(CHART) $(RENDER_SECRETS)
	helm template virtfoundry $(CHART) --set secrets.existingSecret=virtfoundry-credentials
	helm template virtfoundry $(CHART) -f $(CHART)/values-gateway.yaml $(RENDER_SECRETS)
	helm template virtfoundry $(CHART) -f $(CHART)/values-ingress-tls.yaml $(RENDER_SECRETS)
	@! helm template virtfoundry $(CHART) --set ingress.enabled=true $(RENDER_SECRETS) >/dev/null 2>&1 \
		|| (echo "expected fail: ingress.enabled without tls"; exit 1)

security-gates: ## PR gates for secrets fail-closed (#37) and scoped platform RBAC (#38)
	bash ./scripts/ci/security-gates.sh

verify-operator-chart-rbac: ## PR gate for least-privilege operator ClusterRole (#43)
	bash ./scripts/ci/verify-operator-chart-rbac.sh

verify-operator-chart-drift: ## PR gate: operator chart mirror matches virtfoundry/operator (needs network)
	bash ./scripts/ci/verify-operator-chart-drift.sh

verify-api-rbac-contract: ## PR gate: API RBAC satisfies core's docs/rbac-contract.yaml (needs network)
	bash ./scripts/ci/verify-api-rbac-contract.sh

verify-crds-chart: ## PR gate: CRD chart matches operator/vks and keeps CRDs on uninstall (needs network)
	bash ./scripts/ci/verify-crds-chart.sh

sync-crds-chart: ## Refresh charts/virtfoundry-crds/manifests from operator and vks
	bash ./scripts/crds/sync-crds-chart.sh

verify-platform-parity: ## PR gate: umbrella chart renders the same resources as the standalone charts (needs network)
	bash ./scripts/ci/verify-platform-parity.sh

e2e-charts: ## Chart e2e on a throwaway local cluster: make e2e-charts SCENARIO=fresh|umbrella|migrate (deletes CRDs; refuses non-local clusters)
	bash ./scripts/ci/e2e-charts.sh $(SCENARIO)

setup-kubevirt: ## Optional: install KubeVirt prerequisite
	./scripts/setup/kubevirt.sh

setup-multus: ## Optional: install Multus (or use platform.multus.install)
	./scripts/setup/multus.sh

setup-cdi: ## Optional: install CDI (or use platform.cdi.install)
	./scripts/setup/cdi.sh

render-local-config: ## Render ../virtfoundry/config/config.yaml from Helm values
	./scripts/dev/render-local-config.sh

docs-build: ## Build MkDocs site locally
	pip install -r requirements-docs.txt
	mkdocs build --strict

docs-serve: ## Serve MkDocs locally (http://127.0.0.1:8000)
	pip install -r requirements-docs.txt
	mkdocs serve
