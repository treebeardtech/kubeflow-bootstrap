
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

module "treebeardkf" {
  source         = "../.."
  hostname       = "kf.example.com"
  protocol       = "https://"
  port           = ""
  enable_kuberay = false
  enable_mlflow  = false
}