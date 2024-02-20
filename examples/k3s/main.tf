
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
  backend "kubernetes" {
    secret_suffix = "state"
    config_path   = "~/.kube/dev3.yaml"
  }
}

variable "kubeconfig_path" {
  type    = string
  default = "~/.kube/dev3.yaml"
}

provider "kustomization" {
  kubeconfig_path = var.kubeconfig_path
}

provider "helm" {
  kubernetes {
    config_path = var.kubeconfig_path
  }
}

provider "kubernetes" {
  config_path = var.kubeconfig_path
}

module "treebeardkf" {
  source = "../.."
  hostname    = "kf.example.com"
  protocol    = "https://"
  port        = ""
  enable_kuberay       = false
  enable_mlflow        = false
}