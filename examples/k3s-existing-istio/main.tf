
terraform {
  required_providers {
    kustomization = {
      source  = "kbst/kustomization"
      version = "~> 0.9.5"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.12.1"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.25.2"
    }
  }
  backend "local" {
  }
}

variable "kubeconfig" {
  type = string
}

provider "kustomization" {
  kubeconfig_path = var.kubeconfig
}

provider "helm" {
  kubernetes {
    config_path = var.kubeconfig
  }
}

provider "kubernetes" {
  config_path = var.kubeconfig
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

# resource "time_sleep" "wait_30_seconds" {
#   depends_on = [
#     helm_release.istio_ingressgateway
#   ]
#   create_duration = "30s"
# }

resource null_resource "completed" {
  depends_on = [
    helm_release.istio_ingressgateway
  ]
}

module "treebeardkf" {
  source                 = "../.."
  hostname               = "kf.example.com"
  protocol               = "https://"
  port                   = ""
  enable_kuberay         = false
  enable_mlflow          = false
  enable_istio_base      = false
  enable_istiod          = false
  enable_istio_resources = true
  enable_cert_manager    = false
  completed = null_resource.completed.id
}