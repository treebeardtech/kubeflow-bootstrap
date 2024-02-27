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
}

variable "hostname" {
  type    = string
  default = "localhost"
}

variable "protocol" {
  type    = string
  default = "http://"
}

variable "port" {
  type    = string
  default = "8080"
}


locals {
  base_url = "${var.protocol}${var.hostname}${var.port}"
}

variable "enable_cert_manager" {
  type    = bool
  default = true
}

data "kustomization_build" "cert_manager" {
  count = var.enable_cert_manager ? 1 : 0
  path = "${path.module}/submodules/manifests/common/cert-manager/cert-manager/base"
}

module "cert_manager" {
  count = var.enable_cert_manager ? 1 : 0
  source = "./modules/kust"
  build  = one(data.kustomization_build.cert_manager)
  depends_on = [
    helm_release.gpu_operator
  ]
}

data "kustomization_build" "kubeflow_issuer" {
  path = "${path.module}/submodules/manifests/common/cert-manager/kubeflow-issuer/base"
}

module "kubeflow_issuer" {
  source = "./modules/kust"
  build  = data.kustomization_build.kubeflow_issuer
  depends_on = [
    module.cert_manager
  ]
}

variable "enable_istio_base" {
  type    = bool
  default = true
}

variable "enable_istiod" {
  type    = bool
  default = true
}

data "kustomization_build" "istio_crds" {
  count = var.enable_istio_base ? 1 : 0
  path = "${path.module}/submodules/manifests/common/istio-1-17/istio-crds/base"
}

module "istio_crds" {
  count = var.enable_istio_base ? 1 : 0
  source = "./modules/kust"
  build  = one(data.kustomization_build.istio_crds)
  depends_on = [
    module.kubeflow_issuer
  ]
}

data "kustomization_build" "istio_namespace" {
  count = var.enable_istio_base ? 1 : 0
  path = "${path.module}/submodules/manifests/common/istio-1-17/istio-namespace/base"
}

module "istio_namespace" {
  count = var.enable_istio_base ? 1 : 0
  source = "./modules/kust"
  build  = one(data.kustomization_build.istio_namespace)
  depends_on = [
    module.istio_crds
  ]
}


data "kustomization_overlay" "istio_install" {
  count = var.enable_istiod ? 1 : 0
  resources = [
    "${path.module}/overlays/istio-install"
  ]


  #   dynamic "patches" {
  #     for_each = var.enable_external_dns ? [1] : []
  #     content {
  #       target {
  #         kind      = "Service"
  #         name      = "istio-ingressgateway"
  #         namespace = "istio-system"
  #       }
  #       patch = <<EOF
  # apiVersion: v1
  # kind: Service
  # metadata:
  #   name: istio-ingressgateway
  #   namespace: istio-system
  #   annotations:
  #     external-dns.alpha.kubernetes.io/hostname: ${var.hostname}
  #     external-dns.alpha.kubernetes.io/ttl: "60" #optional
  # spec:
  #   type: LoadBalancer
  # EOF
  #     }
  # }
}

module "istio_install" {
  count = var.enable_istiod ? 1 : 0
  source = "./modules/kust"
  build  = one(data.kustomization_overlay.istio_install)
  depends_on = [
    module.istio_namespace
  ]
}

data "kustomization_overlay" "oidc_authservice" {
  config_map_generator {
    name     = "oidc-authservice-parameters"
    behavior = "merge"
    literals = [
      # "OIDC_PROVIDER=${var.protocol}${var.hostname}${var.port}/dex"
    ]
  }

  resources = [
    "${path.module}/submodules/manifests/common/oidc-client/oidc-authservice/base",
  ]
}

module "oidc_authservice" {
  source = "./modules/kust"
  build  = data.kustomization_overlay.oidc_authservice
  depends_on = [
    module.istio_install
  ]
}

data "kustomization_overlay" "dex" {
  resources = [
    "${path.module}/submodules/manifests/common/dex/overlays/istio"
  ]
  patches {
    patch = <<EOF
apiVersion: v1
kind: ConfigMap
metadata:
  name: dex
  namespace: auth
data:
  config.yaml: |-
    issuer: http://dex.auth.svc.cluster.local:5556/dex
    storage:
      type: kubernetes
      config:
        inCluster: true
    web:
      http: 0.0.0.0:5556
    logger:
      level: "debug"
      format: text
    oauth2:
      skipApprovalScreen: false
    enablePasswordDB: true
    staticPasswords:
    - email: user@example.com
      hash: $2y$12$4K/VkmDd1q1Orb3xAt82zu8gk7Ad6ReFR4LCP9UeYE90NLiN9Df72
      # https://github.com/dexidp/dex/pull/1601/commits
      # FIXME: Use hashFromEnv instead
      username: user
      userID: "15841185641784"
    staticClients:
    # https://github.com/dexidp/dex/pull/1664
    - idEnv: OIDC_CLIENT_ID
      redirectURIs: ["/authservice/oidc/callback"]
      name: 'Dex Login Application'
      secretEnv: OIDC_CLIENT_SECRET
    connectors: []
EOF
  }
}

module "dex" {
  source = "./modules/kust"
  build  = data.kustomization_overlay.dex
  depends_on = [
    module.istio_install
  ]
}

## knative

data "kustomization_overlay" "knative_serving" {
  count = var.enable_kserve ? 1 : 0
  resources = [
    "${path.module}/submodules/manifests/common/knative/knative-serving/overlays/gateways"
  ]
  patches {
    target {
      kind      = "Deployment"
      name      = "activator"
      namespace = "knative-serving"
    }
    patch = <<EOF
apiVersion: apps/v1
kind: Deployment
metadata:
  name: activator
  namespace: knative-serving
spec:
  template:
    spec:
      containers:
      - name: activator
        resources:
          requests:
            cpu: 40m
      EOF
  }
}

module "knative_serving" {
  count  = var.enable_kserve ? 1 : 0
  source = "./modules/kust"
  build  = data.kustomization_overlay.knative_serving[0]
  depends_on = [
    module.dex
  ]
}

data "kustomization_build" "cluster_local_gateway" {
  count = var.enable_kserve ? 1 : 0
  path  = "${path.module}/submodules/manifests/common/istio-1-17/cluster-local-gateway/base"
}

module "cluster_local_gateway" {
  count  = var.enable_kserve ? 1 : 0
  source = "./modules/kust"
  build  = data.kustomization_build.cluster_local_gateway
  depends_on = [
    module.knative_serving,
    module.dex
  ]
}

## kubeflow namespace

data "kustomization_build" "kubeflow_namespace" {
  path = "${path.module}/submodules/manifests/common/kubeflow-namespace/base"
}

module "kubeflow_namespace" {
  source = "./modules/kust"
  build  = data.kustomization_build.kubeflow_namespace
  depends_on = [
    module.dex
  ]
}

## kubeflow roles

data "kustomization_build" "kubeflow_roles" {
  path = "${path.module}/submodules/manifests/common/kubeflow-roles/base"
}

module "kubeflow_roles" {
  source = "./modules/kust"
  build  = data.kustomization_build.kubeflow_roles
  depends_on = [
    module.kubeflow_namespace
  ]
}

## kubeflow istio resources

variable "enable_istio_resources" {
  type        = bool
  default     = true
  description = "Enable istio resources for clusters with pre-existing istio"
}

data "kustomization_overlay" "kubeflow_istio_resources" {
  count = var.enable_istio_resources ? 1 : 0
  resources = [
    "${path.module}/overlays/istio-resources"
  ]
  #   patches {
  #     target {
  #       kind      = "Certificate"
  #       name      = "gateway-cert"
  #       namespace = "istio-system"
  #     }
  #     patch = <<EOF
  # apiVersion: cert-manager.io/v1
  # kind: Certificate
  # metadata:
  #   name: gateway-cert
  #   namespace: istio-system
  # spec:
  #   commonName: ${var.hostname}
  #   dnsNames:
  #     - ${var.hostname}
  # EOF
  #   }
}

module "kubeflow_istio_resources" {
  count  = var.enable_istio_resources ? 1 : 0
  source = "./modules/kust"
  build  = data.kustomization_overlay.kubeflow_istio_resources[0]
  depends_on = [
    module.kubeflow_roles
  ]
}

## kubeflow pipelines

variable "enable_kubeflow_pipelines" {
  type    = bool
  default = false
}

data "kustomization_build" "kubeflow_pipelines" {
  count = var.enable_kubeflow_pipelines ? 1 : 0
  path  = "${path.module}/submodules/manifests/apps/pipeline/upstream/env/cert-manager/platform-agnostic-multi-user"
}

module "kubeflow_pipelines" {
  count  = var.enable_kubeflow_pipelines ? 1 : 0
  source = "./modules/kust"
  build  = data.kustomization_build.kubeflow_pipelines[0]
  depends_on = [
    module.kubeflow_istio_resources
  ]
}

variable "enable_kserve" {
  type    = bool
  default = false
}

data "kustomization_build" "kserve" {
  count = var.enable_kserve ? 1 : 0
  path  = "${path.module}/submodules/manifests/contrib/kserve/kserve"
}

module "kserve" {
  count  = var.enable_kserve ? 1 : 0
  source = "./modules/kust"
  build  = data.kustomization_build.kserve[0]
  depends_on = [
    module.kubeflow_istio_resources
  ]
}

data "kustomization_build" "models_web_app" {
  count = var.enable_kserve ? 1 : 0
  path  = "${path.module}/submodules/manifests/contrib/kserve/models-web-app/overlays/kubeflow"
}

module "models_web_app" {
  count  = var.enable_kserve ? 1 : 0
  source = "./modules/kust"
  build  = data.kustomization_build.models_web_app[0]
  depends_on = [
    module.kubeflow_istio_resources
  ]
}

data "kustomization_build" "central_dashboard" {
  path = "${path.module}/overlays/centraldashboard"
}

module "central_dashboard" {
  source = "./modules/kust"
  build  = data.kustomization_build.central_dashboard
  depends_on = [
    module.models_web_app,
    module.kubeflow_istio_resources,
    module.kubeflow_pipelines,
    module.kserve
  ]
}

data "kustomization_build" "admission_webhook" {
  path = "${path.module}/submodules/manifests/apps/admission-webhook/upstream/overlays/cert-manager"
}

module "admission_webhook" {
  source = "./modules/kust"
  build  = data.kustomization_build.admission_webhook
  depends_on = [
    module.central_dashboard
  ]
}

data "kustomization_build" "notebook_controller" {
  path = "${path.module}/submodules/manifests/apps/jupyter/notebook-controller/upstream/overlays/kubeflow"
}

module "notebook_controller" {
  source = "./modules/kust"
  build  = data.kustomization_build.notebook_controller
  depends_on = [
    module.admission_webhook
  ]
}

data "kustomization_build" "jupyter_web_app" {
  path = "${path.module}/submodules/manifests/apps/jupyter/jupyter-web-app/upstream/overlays/istio"
}

module "jupyter_web_app" {
  source = "./modules/kust"
  build  = data.kustomization_build.jupyter_web_app
  depends_on = [
    module.notebook_controller
  ]
}

data "kustomization_build" "pvc_viewer_controller" {
  path = "${path.module}/submodules/manifests/apps/pvcviewer-controller/upstream/default"
}

module "pvc_viewer_controller" {
  source = "./modules/kust"
  build  = data.kustomization_build.pvc_viewer_controller
  depends_on = [
    module.jupyter_web_app
  ]
}

data "kustomization_build" "profiles_kfam" {
  path = "${path.module}/submodules/manifests/apps/profiles/upstream/overlays/kubeflow"
}

module "profiles_kfam" {
  source = "./modules/kust"
  build  = data.kustomization_build.profiles_kfam
  depends_on = [
    module.pvc_viewer_controller
  ]
}

data "kustomization_build" "volumes_web_app" {
  path = "${path.module}/submodules/manifests/apps/volumes-web-app/upstream/overlays/istio"
}

module "volumes_web_app" {
  source = "./modules/kust"
  build  = data.kustomization_build.volumes_web_app
  depends_on = [
    module.profiles_kfam
  ]
}

variable "enable_tensorboard" {
  type    = bool
  default = false
}

data "kustomization_build" "tensorboard_web_app" {
  count = var.enable_tensorboard ? 1 : 0
  path  = "${path.module}/submodules/manifests/apps/tensorboard/tensorboards-web-app/upstream/overlays/istio"
}

module "tensorboard_web_app" {
  count  = var.enable_tensorboard ? 1 : 0
  source = "./modules/kust"
  build  = data.kustomization_build.tensorboard_web_app[0]
  depends_on = [
    module.volumes_web_app
  ]
}

variable "enable_kuberay" {
  type    = bool
  default = false
}

resource "helm_release" "kuberay_operator" {
  count      = var.enable_kuberay ? 1 : 0
  name       = "kuberay-operator"
  chart      = "kuberay-operator"
  repository = "https://ray-project.github.io/kuberay-helm/"
  namespace  = "kubeflow"
  version    = "1.0.0"
  depends_on = [
    module.volumes_web_app
  ]
  values = [
    <<EOF
    # if you want to use istio, disable the gcs check which deadlocks on istio init
    # env:
    # - name: ENABLE_INIT_CONTAINER_INJECTION
    #   value: 'false'
    resources:
      limits:
        cpu: 10m
        memory: 64Mi
    EOF
  ]
}

data "kustomization_build" "kubeflow_ray_rbac" {
  count = var.enable_kuberay ? 1 : 0
  path  = "${path.module}/overlays/kuberay-rbac"
}

module "kubeflow_ray_rbac" {
  count  = var.enable_kuberay ? 1 : 0
  source = "./modules/kust"
  build  = data.kustomization_build.kubeflow_ray_rbac[0]
  depends_on = [
    helm_release.kuberay_operator
  ]
}
