.PHONY: help lint template setup-kubevirt setup-multus setup-cdi render-local-config docs-build docs-serve

CHART := ./charts/virtfoundry

help: ## Show available targets
	@grep -E '^[a-zA-Z0-9_-]+:.*##' Makefile | awk 'BEGIN {FS = ":.*## "}; {printf "  %-22s %s\n", $$1, $$2}'

lint: template ## Validate chart renders (default + gateway profile)

template: ## Render Helm templates locally
	helm lint $(CHART)
	helm template virtfoundry $(CHART)
	helm template virtfoundry $(CHART) -f $(CHART)/values-gateway.yaml

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
