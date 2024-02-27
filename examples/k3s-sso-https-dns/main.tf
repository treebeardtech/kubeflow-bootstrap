
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

## DNS Setup

variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

variable "aws_access_key_id" {
  description = "AWS access key id"
  type        = string
}

variable "aws_secret_access_key" {
  description = "AWS secret access key"
  type        = string
}

resource "kubernetes_namespace" "external_dns" {
  metadata {
    name = "external-dns"
  }
}

resource "kubernetes_secret" "aws_credentials" {
  metadata {
    name      = "aws-credentials"
    namespace = "external-dns"
  }
  data = {
    aws_access_key_id     = var.aws_access_key_id
    aws_secret_access_key = var.aws_secret_access_key
  }
  type = "Opaque"
  depends_on = [
    kubernetes_namespace.external_dns
  ]
}

resource "helm_release" "external_dns" {
  name       = "external-dns"
  chart      = "external-dns"
  repository = "https://kubernetes-sigs.github.io/external-dns/"
  namespace  = "external-dns"
  version    = "1.14.0"
  values = [
    <<-EOF
    sources:
    - istio-gateway
    provider: aws
    env:
      - name: AWS_REGION
        value: ${var.aws_region}
      - name: AWS_ACCESS_KEY_ID
        valueFrom:
          secretKeyRef:
            name: aws-credentials
            key: aws_access_key_id
      - name: AWS_SECRET_ACCESS_KEY
        valueFrom:
          secretKeyRef:
            name: aws-credentials
            key: aws_secret_access_key
    EOF
  ]
  depends_on = [
    kubernetes_secret.aws_credentials
  ]
}

locals {
  issuer_spec = <<-EOF
spec:
  acme:
    email: alex@treebeard.io
    preferredChain: ''
    privateKeySecretRef:
      name: treebeard-issuer-account-key
    server: https://acme-v02.api.letsencrypt.org/directory
    solvers:
    - dns01:
        route53:
          region: eu-west-1
          hostedZoneID: Z1026422YPHVFN3SS6AV
          accessKeyIDSecretRef:
            name: aws-credentials
            key: aws_access_key_id
          secretAccessKeySecretRef:
            name: aws-credentials
            key: aws_secret_access_key
EOF
}

## HTTPS Setup (depends on DNS setup)

variable "issuer_ref" {
  description = "Issuer reference for cert-manager"
  type = object({
    name  = string
    kind  = string
    group = string
  })
  default = null
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
      type   = string
      id     = string
      name   = string
      config = object({
        clientID       = string
        clientSecret   = string
        redirectURI    = string
        orgs           = list(object({
          name = string
        }))
        loadAllGroups  = bool
        teamNameField  = string
        useLoginAsID   = bool
      })
    }))
  })
  default = {
    oauth2 = {
      skipApprovalScreen = false
    }
    enablePasswordDB = true
    staticPasswords = []
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
          clientID      = ""
          clientSecret  = ""
          redirectURI   = ""
          orgs          = [
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
      name    = string
      members = list(object({
        group  = string
        access = object({
          role             = string
          notebooksAccess  = bool
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
            group = "team-1--users",
            access = { role = "edit", notebooksAccess = true }
          }
        ]
      },
      {
        name = "team-1-prod",
        members = [
          {
            group = "team-1--admins",
            access = { role = "edit", notebooksAccess = true }
          },
          {
            group = "team-1--users",
            access = { role = "view", notebooksAccess = false }
          }
        ]
      }
    ]
  }
}

resource null_resource "completed" {
  depends_on = [
    helm_release.external_dns
  ]
}

module "treebeardkf" {
  source         = "../.."
  hostname       = "kf.example.com"
  protocol       = "https://"
  port           = ""
  enable_kuberay = false
  enable_mlflow  = false
  dex_config = var.dex_config
  profile_configuration = var.profile_configuration
  issuer_spec = local.issuer_spec
  completed = null_resource.completed.id
}