.PHONY: help lint template deploy-homelab setup-kubevirt setup-multus setup-cdi render-local-config

CHART := ./charts/virtforge

help: ## Show available targets
	@grep -E '^[a-zA-Z0-9_-]+:.*##' Makefile | awk 'BEGIN {FS = ":.*## "}; {printf "  %-22s %s\n", $$1, $$2}'

lint: template ## Validate chart renders (default + homelab values)

template: ## Render Helm templates locally
	helm template virtforge $(CHART)
	helm template virtforge $(CHART) -f $(CHART)/values-homelab.yaml

deploy-homelab: ## Optional: build images and deploy homelab profile
	./scripts/deploy/homelab.sh

setup-kubevirt: ## Optional: install KubeVirt prerequisite
	./scripts/setup/kubevirt.sh

setup-multus: ## Optional: install Multus (or use platform.multus.install)
	./scripts/setup/multus.sh

setup-cdi: ## Optional: install CDI (or use platform.cdi.install)
	./scripts/setup/cdi.sh

render-local-config: ## Render ../virtforge/config/config.yaml from Helm values
	./scripts/dev/render-local-config.sh
