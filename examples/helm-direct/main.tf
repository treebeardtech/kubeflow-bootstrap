
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

resource "helm_release" "argo_cd" {
  name             = "argocd"
  namespace        = "argocd"
  chart            = "argo-cd"
  repository       = "https://argoproj.github.io/argo-helm"
  version          = "6.4.1"
  create_namespace = true
  values = [
    <<EOF
dex:
  enabled: false
EOF
  ]
}

resource "helm_release" "kubeflow" {
  name      = "kubeflow"
  namespace = "argocd"
  chart     = "${path.module}/../../helm/kubeflow"
  values = [
    <<EOF
targetRevision: 0.1-2024-03-13-T12-09-21
EOF
  ]
  depends_on = [
    helm_release.argo_cd
  ]
}