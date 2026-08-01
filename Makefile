.PHONY: help lint template deploy-homelab setup-kubevirt setup-multus setup-cdi deploy-windows-test-vm

CHART := ./charts/virtforge

help: ## Show available targets
	@grep -E '^[a-zA-Z0-9_-]+:.*##' Makefile | awk 'BEGIN {FS = ":.*## "}; {printf "  %-22s %s\n", $$1, $$2}'

lint: template ## Validate chart renders (default + homelab values)

template: ## Render Helm templates locally
	helm template virtforge $(CHART)
	helm template virtforge $(CHART) -f $(CHART)/values-homelab.yaml

deploy-homelab: ## Build/push images and deploy homelab profile
	./scripts/deploy/homelab.sh

setup-kubevirt: ## Install KubeVirt on the cluster (one-time)
	./scripts/setup/kubevirt.sh

setup-multus: ## Install or verify Multus CNI
	./scripts/setup/multus.sh

setup-cdi: ## Install CDI for ISO/DataVolume imports
	./scripts/setup/cdi.sh

deploy-windows-test-vm: ## Deploy optional Windows IOPS test VM
	./scripts/deploy/windows-test-vm.sh
