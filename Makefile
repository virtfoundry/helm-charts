.PHONY: help lint template security-gates setup-kubevirt setup-multus setup-cdi render-local-config docs-build docs-serve

CHART := ./charts/virtfoundry

# Throwaway render-only credentials. The chart ships no defaults and fails to render
# without them (helm-charts#37) — never reuse these on a cluster.
RENDER_ROOT_PASSWORD ?= render-only-password
RENDER_JWT_SECRET ?= render-only-jwt-secret-0123456789abcdef
RENDER_SECRETS := --set-string secrets.rootPassword=$(RENDER_ROOT_PASSWORD) --set-string secrets.jwtSecret=$(RENDER_JWT_SECRET)

help: ## Show available targets
	@grep -E '^[a-zA-Z0-9_-]+:.*##' Makefile | awk 'BEGIN {FS = ":.*## "}; {printf "  %-22s %s\n", $$1, $$2}'

lint: template security-gates ## Validate chart renders + security gates

template: ## Render Helm templates locally
	helm lint $(CHART) $(RENDER_SECRETS)
	./scripts/ci/assert-secrets-fail-closed.sh
	helm template virtfoundry $(CHART) $(RENDER_SECRETS)
	helm template virtfoundry $(CHART) --set secrets.existingSecret=virtfoundry-credentials
	helm template virtfoundry $(CHART) -f $(CHART)/values-gateway.yaml $(RENDER_SECRETS)

security-gates: ## PR gates for secrets fail-closed (#37) and scoped platform RBAC (#38)
	bash ./scripts/ci/security-gates.sh

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
