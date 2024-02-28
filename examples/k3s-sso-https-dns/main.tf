
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

variable "host" {
}

variable "cert_email_owner" {
}

variable "hosted_zone_id" {
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

provider "kustomization" {
  kubeconfig_path = "/home/vscode/.kube/eks.yaml"
}

module "ebs_csi_role" {
  source                = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"
  version               = "5.34.0"
  role_name             = "irsa-ebs-csi"
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
      eks.amazonaws.com/role-arn: ${module.ebs_csi_role.iam_role_arn}
storageClasses:
- name: ebs-sc
  annotations:
    storageclass.kubernetes.io/is-default-class: "true"
    EOF
  ]
}

## DNS Setup

module "external_dns_role" {
  source                     = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"
  version                    = "5.34.0"
  role_name                  = "external-dns"
  attach_external_dns_policy = true
  oidc_providers = {
    main = {
      provider_arn               = module.eks.oidc_provider_arn
      namespace_service_accounts = ["external-dns:external-dns"]
    }
  }
}

resource "helm_release" "external_dns" {
  name             = "external-dns"
  chart            = "external-dns"
  repository       = "https://kubernetes-sigs.github.io/external-dns/"
  namespace        = "external-dns"
  create_namespace = true
  version          = "1.14.0"
  values = [
    <<-EOF
    sources:
    - istio-gateway
    provider: aws
    env:
      - name: AWS_REGION
    serviceAccount:
      annotations:
        eks.amazonaws.com/role-arn: ${module.external_dns_role.iam_role_arn}
    securityContext:
      fsGroup: 1001
    EOF
  ]
  depends_on = [
    module.external_dns_role
  ]
}

## HTTPS Setup

module "cert_manager_role" {
  source                     = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"
  version                    = "5.34.0"
  role_name                  = "cert-manager"
  attach_cert_manager_policy = true
  oidc_providers = {
    main = {
      provider_arn               = module.eks.oidc_provider_arn
      namespace_service_accounts = ["cert-manager:cert-manager"]
    }
  }
}

resource "helm_release" "cert_manager" {
  name             = "cert-manager"
  namespace        = "cert-manager"
  chart            = "cert-manager"
  repository       = "https://charts.jetstack.io"
  version          = "1.12.8"
  create_namespace = true
  depends_on = [
    helm_release.external_dns
  ]
  values = [
    <<EOF
    installCRDs: true
    serviceAccount:
      annotations:
        eks.amazonaws.com/role-arn: ${module.cert_manager_role.iam_role_arn}
    securityContext:
      fsGroup: 1001
    extraArgs:
      - --issuer-ambient-credentials=true
      - --cluster-issuer-ambient-credentials=true
    EOF
  ]
}

resource "helm_release" "issuer" {
  name      = "issuer"
  namespace = "cert-manager"
  chart     = "${path.module}/issuer"
  values = [
    <<EOF
    certEmailOwner: ${var.cert_email_owner}
    hostedZoneId: ${var.hosted_zone_id}
    EOF
  ]
  depends_on = [
    helm_release.cert_manager
  ]
}

# data "kustomization_build" "issuer" {
#   path  = "${path.module}/issuer"
# }

# module "issuer" {
#   source = "../../modules/kust"
#   build  = data.kustomization_build.issuer
#   depends_on = [
#     helm_release.cert_manager
#   ]
# }

resource "helm_release" "istio_base" {
  name             = "istio-base"
  namespace        = "istio-system"
  chart            = "base"
  repository       = "https://istio-release.storage.googleapis.com/charts"
  version          = "1.18.7"
  create_namespace = true
  depends_on = [
    helm_release.issuer
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
      type: LoadBalancer
    serviceAccount:
      name: istio-ingressgateway-service-account
    EOF
  ]
}

## OIDC Setup

variable "dex_config" {
  type = object({
    oauth2 = object({
      skipApprovalScreen = bool
    })
    enablePasswordDB = bool
    staticPasswords = list(object({
      email    = string
      hash     = string
      username = string
      userID   = string
    }))
    staticClients = list(object({
      idEnv        = string
      redirectURIs = list(string)
      name         = string
      secretEnv    = string
    }))
    connectors = list(object({
      type = string
      id   = string
      name = string
      config = object({
        clientID     = string
        clientSecret = string
        redirectURI  = string
        orgs = list(object({
          name = string
        }))
        loadAllGroups = bool
        teamNameField = string
        useLoginAsID  = bool
      })
    }))
  })
  default = {
    oauth2 = {
      skipApprovalScreen = false
    }
    enablePasswordDB = true
    staticPasswords  = []
    staticClients = [
      {
        idEnv        = "OIDC_CLIENT_ID"
        redirectURIs = ["/authservice/oidc/callback"]
        name         = "Dex Login Application"
        secretEnv    = "OIDC_CLIENT_SECRET"
      }
    ]
    connectors = [
      {
        type = "github"
        id   = "github"
        name = "GitHub"
        config = {
          clientID     = ""
          clientSecret = ""
          redirectURI  = ""
          orgs = [
            {
              name = ""
            }
          ]
          loadAllGroups = false
          teamNameField = "slug"
          useLoginAsID  = true
        }
      }
    ]
  }
}

## Authorization Setup

variable "profile_configuration" {
  type = object({
    users = list(object({
      id    = string
      email = string
    }))
    groups = list(object({
      id    = string
      users = list(string)
    }))
    profiles = list(object({
      name = string
      members = list(object({
        group = string
        access = object({
          role            = string
          notebooksAccess = bool
        })
      }))
    }))
  })
  default = {
    users = [
      { id = "user-1", email = "user1@example.com" },
      { id = "user-2", email = "user2@example.com" },
      { id = "user-3", email = "user3@example.com" }
    ],
    groups = [
      { id = "team-1--admins", users = ["user-1"] },
      { id = "team-1--users", users = ["user-1", "user-2", "user-3"] }
    ],
    profiles = [
      {
        name = "team-1",
        members = [
          {
            group  = "team-1--users",
            access = { role = "edit", notebooksAccess = true }
          }
        ]
      },
      {
        name = "team-1-prod",
        members = [
          {
            group  = "team-1--admins",
            access = { role = "edit", notebooksAccess = true }
          },
          {
            group  = "team-1--users",
            access = { role = "view", notebooksAccess = false }
          }
        ]
      }
    ]
  }
}

resource "null_resource" "completed" {
  depends_on = [
    helm_release.istio_ingressgateway
  ]
}

module "treebeardkf" {
  source                 = "../.."
  hostname               = var.host
  protocol               = "https://"
  port                   = ""
  enable_kuberay         = false
  enable_mlflow          = false
  enable_istio_base      = false
  enable_istiod          = false
  enable_istio_resources = true
  enable_cert_manager    = false
  dex_config             = var.dex_config
  profile_configuration  = var.profile_configuration
  completed              = null_resource.completed.id
}