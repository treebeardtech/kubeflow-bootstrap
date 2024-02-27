SHELLOPTS := $(if $(SHELLOPTS),$(SHELLOPTS):, )xtrace pipefail errexit nounset

.PHONY: post-create
post-create:
	@echo "post-create"

.PHONY: post-start
post-start:
	@echo "post-start"
	./scripts/setup-krew.sh

docs:
	terraform-docs markdown . > ./README.md.new
	terraform-docs markdown examples/k3s > examples/k3s/README.md.new
	terraform-docs markdown examples/eks > examples/eks/README.md.new
	terraform-docs markdown examples/aks > examples/aks/README.md.new

fmt:
	terraform fmt . modules/* examples/*
.PHONY: build