SHELLOPTS := $(if $(SHELLOPTS),$(SHELLOPTS):, )xtrace pipefail errexit nounset

.PHONY: post-create
post-create:
	@echo "post-create"

.PHONY: post-start
post-start:
	@echo "post-start"
	./scripts/setup-krew.sh

docs:
	terraform-docs markdown ./modules/treebeardkf > ./modules/treebeardkf/README.md
	go install github.com/norwoodj/helm-docs/cmd/helm-docs@latest
	helm-docs

fmt:
	terraform fmt **/*modules
.PHONY: build