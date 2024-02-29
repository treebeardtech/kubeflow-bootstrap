SHELLOPTS := $(if $(SHELLOPTS),$(SHELLOPTS):, )xtrace pipefail errexit nounset

.PHONY: post-create
post-create:
	@echo "post-create"

.PHONY: post-start
post-start:
	@echo "post-start"
	./scripts/setup-krew.sh

.PHONY: docs
docs:
	terraform-docs markdown . > ./README.md.new
	terraform-docs markdown examples/k3s > examples/k3s/README.md.new
	terraform-docs markdown examples/k3s-existing-istio > examples/k3s-existing-istio/README.md.new
	terraform-docs markdown examples/aks > examples/aks/README.md.new

.PHONY: docs-rm-new
docs-rm-new:
	rm -f ./README.md.new
	rm -f examples/k3s/README.md.new
	rm -f examples/eks/README.md.new
	rm -f examples/aks/README.md.new

fmt:
	terraform fmt . modules/* examples/*

.PHONY: k3d-create
k3d-create:
	k3d cluster create dev \
		-p "80:80@loadbalancer" \
		-p "443:443@loadbalancer" \
		--k3s-arg '--disable=traefik@server:0'

.PHONY: k3d-delete
k3d-delete:
	k3d cluster delete dev
