SHELLOPTS := $(if $(SHELLOPTS),$(SHELLOPTS):, )xtrace pipefail errexit nounset

.PHONY: post-create
post-create:
	./scripts/post-create.sh

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
GIT_TAG := $(shell git describe --tags `git rev-list --tags --max-count=1` | sed 's/^v//')
VERSION ?= $(if $(filter $(PROD),true),$(GIT_TAG),$(GIT_TAG)-dev+$(TIMESTAMP))
build-chart:
	rm -rf helm/*.tgz
	helm package helm/kubeflow-core -d helm --version $(VERSION)
	yq eval '.targetRevision = "$(VERSION)"' -i helm/kubeflow/values.yaml
	helm package helm/kubeflow -d helm --version $(VERSION)

push-chart: build-chart
	helm push helm/kubeflow-core-$(VERSION).tgz oci://ghcr.io/treebeardtech/helm
	helm push helm/kubeflow-$(VERSION).tgz oci://ghcr.io/treebeardtech/helm

helm-repo-login:
	echo $(GHCR_PAT) | docker login ghcr.io -u $(USERNAME) --password-stdin
