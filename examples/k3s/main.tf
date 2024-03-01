
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

module "treebeardkf" {
  source = "../.."
}