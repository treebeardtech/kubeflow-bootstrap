SHELLOPTS := $(if $(SHELLOPTS),$(SHELLOPTS):, )xtrace pipefail errexit nounset

.PHONY: post-create
post-create:
	@echo "post-create"
	brew install helm-docs
	./scripts/setup-krew.sh

.PHONY: post-start
post-start:
	@echo "post-start"

.PHONY: docs
docs:
	terraform-docs markdown . > ./README.md.new
	terraform-docs markdown examples/k3s > examples/k3s/README.md.new
	terraform-docs markdown examples/k3s-existing-istio > examples/k3s-existing-istio/README.md.new
	terraform-docs markdown examples/aks > examples/aks/README.md.new
	terraform-docs markdown examples/eks-https-loadbalancer > examples/eks-https-loadbalancer/README.md.new

.PHONY: docs-rm-new
docs-rm-new:
	rm -f ./README.md.new
	rm -f examples/k3s/README.md.new
	rm -f examples/k3s-existing-istio/README.md.new
	rm -f examples/aks/README.md.new
	rm -f examples/eks-https-loadbalancer/README.md.new

fmt:
	terraform fmt . examples/*

.PHONY: k3d-create
k3d-create:
	k3d cluster create dev \
		-p "80:80@loadbalancer" \
		-p "443:443@loadbalancer" \
		--k3s-arg '--disable=traefik@server:0'

.PHONY: k3d-delete
k3d-delete:
	k3d cluster delete dev

TIMESTAMP := $(shell date -u "+%Y-%m-%d-T%H-%M-%S")
VERSION := 0.1-$(TIMESTAMP)

build-kf-apps:
	rm -rf helm/kubeflow-argo-apps-*.tgz
	helm package helm/kubeflow-argo-apps -d helm --version $(VERSION)

push-kf-apps:
	helm push helm/kubeflow-argo-apps-*.tgz oci://ghcr.io/treebeardtech

helm-repo-login:
	echo $(GHCR_PAT) | docker login ghcr.io -u alex-treebeard --password-stdin
