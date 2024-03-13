terraform {
  required_version = ">= 1.3"

  required_providers {
    helm = {
      source  = "hashicorp/helm"
      version = ">= 2.12"
    }
  }
}

variable "enable_argocd" {
  type    = bool
  default = true
}

variable "kubeflow_values" {
  description = "Extra values"
  type        = list(string)
  default     = []
}

locals {
  defaults = [
    <<EOF
targetRevision: 0.1-2024-03-11-T15-14-41
EOF
  ]
}

resource "helm_release" "argo_cd" {
  count = var.enable_argocd ? 1 : 0

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
  name          = "kubeflow"
  namespace     = "argocd"
  chart         = "${path.module}/helm/kubeflow"
  wait_for_jobs = true
  values        = concat(local.defaults, var.kubeflow_values)
  depends_on = [
    helm_release.argo_cd
  ]
}
