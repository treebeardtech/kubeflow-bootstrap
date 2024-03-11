
terraform {
  required_providers {
    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.12.1"
    }
  }
  backend "local" {
  }
}

variable "kubeconfig" {
  type = string
}

provider "helm" {
  kubernetes {
    config_path = var.kubeconfig
  }
}

locals {
  cert_manager_enabled = false
}

resource "helm_release" "cert-manager" {
  name             = "cert-manager"
  namespace        = "cert-manager"
  chart            = "cert-manager"
  repository       = "https://charts.jetstack.io"
  version          = "1.14.3"
  create_namespace = true
  depends_on       = []
  values = [
    <<EOF
    installCRDs: true
    EOF
  ]
}

resource "helm_release" "istio_base" {
  name             = "istio-base"
  namespace        = "istio-system"
  chart            = "base"
  repository       = "https://istio-release.storage.googleapis.com/charts"
  version          = "1.18.7"
  create_namespace = true
  depends_on = [
    helm_release.cert-manager
  ]
  values = [
    <<EOF
    EOF
  ]
}

resource "helm_release" "istiod" {
  name             = "istiod"
  namespace        = "istio-system"
  chart            = "istiod"
  repository       = "https://istio-release.storage.googleapis.com/charts"
  version          = "1.18.7"
  create_namespace = true
  depends_on = [
    helm_release.istio_base
  ]
  values = [
    <<EOF
    EOF
  ]
}

resource "helm_release" "istio_ingressgateway" {
  name       = "istio-ingressgateway"
  namespace  = "istio-system"
  chart      = "gateway"
  repository = "https://istio-release.storage.googleapis.com/charts"
  version    = "1.18.7"
  depends_on = [
    helm_release.istiod
  ]
  values = [
    <<EOF
    service:
      type: ClusterIP
    serviceAccount:
      name: istio-ingressgateway-service-account
    EOF
  ]
}

resource "null_resource" "completed" {
  depends_on = [
    helm_release.istio_ingressgateway
  ]
}

module "treebeardkf" {
  source = "../.."
  bootstrap_values = [
    <<EOF
sources:
- repoURL: 'https://github.com/treebeardtech/treebeard-kubeflow-gitops'
  targetRevision: 8e3369ac3720bd837f75d812b9ec9d5f9d135cef
  ref: values
valueFiles:
# this value file should disabled istio (example of gitops config)
- $values/clusters/k3s-gitops.yaml
valuesObject:
  # example of inline config where terraform vars can be injected
  certManager:
    enabled: ${local.cert_manager_enabled}
# syncPolicy: null enable for debugging
EOF
  ]
  depends_on = [
    null_resource.completed
  ]
}