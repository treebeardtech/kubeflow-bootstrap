
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
  debug = true
}

module "treebeardkf" {
  source = "../.."
  kubeflow_values = [
    <<EOF
sources:
- repoURL: 'https://github.com/treebeardtech/treebeard-kubeflow-gitops'
  targetRevision: main
  ref: values
valueFiles:
- $values/clusters/k3s-gitops.yaml
valuesObject:
  # example of inline config where terraform vars can be injected
  debug: ${local.debug}
syncPolicy: null

EOF
  ]
  depends_on = [
  ]
}