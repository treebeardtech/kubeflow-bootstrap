terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "5.28.0"
    }
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
}

data "aws_availability_zones" "available" {}

locals {
  name = basename(path.cwd)
  azs  = slice(data.aws_availability_zones.available.names, 0, 3)
  tags = {
    "tf" : "true"
    "Name" : local.name
  }
  cloud_cidr = "10.0.0.0/16"
}

variable "aws_region" {
  description = "AWS region to launch servers."
}

variable "aws_profile" {
  description = "AWS profile to use for authentication."
}

provider "aws" {
  region  = var.aws_region
  profile = var.aws_profile
  default_tags {
    tags = {
      "tf" : "true"
      "Name" : local.name
    }
  }
}


module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "5.1.2"

  name                    = "kubeflow-vpc"
  cidr                    = local.cloud_cidr
  map_public_ip_on_launch = true

  azs             = local.azs
  public_subnets  = ["10.0.1.0/24", "10.0.2.0/24"]
  private_subnets = ["10.0.3.0/24", "10.0.4.0/24"]

  enable_nat_gateway = true
  single_nat_gateway = true

  enable_dns_hostnames = true
  enable_dns_support   = true
}

module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 19.20"

  cluster_name                   = "cluster"
  cluster_version                = "1.28"
  cluster_endpoint_public_access = true

  vpc_id                      = module.vpc.vpc_id
  subnet_ids                  = module.vpc.public_subnets
  create_cloudwatch_log_group = false
  cluster_encryption_config   = {}

  node_security_group_additional_rules = {
    ssh = {
      type        = "ingress"
      description = "Allow SSH inbound traffic from anywhere"
      from_port   = 22
      to_port     = 22
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
    },
    istio_injection_webhook = {
      description                   = "Allow istio injection"
      protocol                      = "tcp"
      from_port                     = "15017"
      to_port                       = "15017"
      type                          = "ingress"
      source_cluster_security_group = true
    }
  }
  eks_managed_node_groups = {
    amzn_linux = {
      instance_types = ["t3.xlarge"]
      min_size       = 0
      max_size       = 1
      desired_size   = 1
    }
  }
  tags = local.tags
}

provider "kubernetes" {
  host                   = module.eks.cluster_endpoint
  cluster_ca_certificate = base64decode(module.eks.cluster_certificate_authority_data)
  exec {
    command     = "aws"
    api_version = "client.authentication.k8s.io/v1beta1"
    args = [
      "--region",
      var.aws_region,
      "eks",
      "get-token",
      "--cluster-name",
      module.eks.cluster_name
    ]
    env = {
      name  = "AWS_PROFILE"
      value = var.aws_profile
    }
  }
}

provider "helm" {
  kubernetes {
    host                   = module.eks.cluster_endpoint
    cluster_ca_certificate = base64decode(module.eks.cluster_certificate_authority_data)
    exec {
      command     = "aws"
      api_version = "client.authentication.k8s.io/v1beta1"
      args = [
        "--region",
        var.aws_region,
        "eks",
        "get-token",
        "--cluster-name",
        module.eks.cluster_name
      ]
      env = {
        name  = "AWS_PROFILE"
        value = var.aws_profile
      }
    }
  }
}

variable "kubeconfig" {
  description = "Path to the kubeconfig file"
  type        = string
}

provider "kustomization" {
  kubeconfig_raw = file(var.kubeconfig)
}

module "iam_eks_role" {
  source                = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"
  version               = "5.34.0"
  role_name             = "ebs-csi"
  attach_ebs_csi_policy = true
  oidc_providers = {
    main = {
      provider_arn               = module.eks.oidc_provider_arn
      namespace_service_accounts = ["kube-system:ebs-csi-controller-sa"]
    }
  }
}

resource "kubernetes_annotations" "default-storageclass" {
  api_version = "storage.k8s.io/v1"
  kind        = "StorageClass"
  force       = "true"

  metadata {
    name = "gp2"
  }
  annotations = {
    "storageclass.kubernetes.io/is-default-class" = "false"
  }
}

resource "helm_release" "ebs_csi_driver" {
  name       = "aws-ebs-csi-driver"
  chart      = "aws-ebs-csi-driver"
  repository = "https://kubernetes-sigs.github.io/aws-ebs-csi-driver"
  namespace  = "kube-system"
  version    = "2.28.1"
  values = [
    <<EOF
controller:
  serviceAccount:
    annotations:
      eks.amazonaws.com/role-arn: ${module.iam_eks_role.iam_role_arn}
storageClasses:
- name: ebs-sc
  annotations:
    storageclass.kubernetes.io/is-default-class: "true"
    EOF
  ]
}

variable "enable_treebeardkf" {
  description = "Enable Treebeard"
  type        = bool
  default     = false
}

module "treebeardkf" {
  count        = var.enable_treebeardkf ? 1 : 0
  source       = "../.."
  hostname     = "kf.example.com"
  enable_https = true
}