
resource "helm_release" "argo_cd" {
  name       = "argo-cd"
  namespace  = "argo-cd"
  chart      = "argo-cd"
  repository = "https://argoproj.github.io/argo-helm"
  version    = "6.4.1"
  create_namespace = true
  depends_on = [
    var.dependency
  ]
  values = [
    <<EOF
    EOF
  ]
}


data "kustomization_build" "cert_manager" {
  count = var.enable_cert_manager ? 1 : 0
  path  = "${path.module}/submodules/manifests/common/cert-manager/cert-manager/base"
}

module "cert_manager" {
  count  = var.enable_cert_manager ? 1 : 0
  source = "./modules/kust"
  build  = one(data.kustomization_build.cert_manager)
  depends_on = [
    helm_release.argo_cd
  ]
}

data "kustomization_build" "kubeflow_issuer" {
  path = "${path.module}/submodules/manifests/common/cert-manager/kubeflow-issuer/base"
}

module "kubeflow_issuer" {
  source = "./modules/kust"
  build  = data.kustomization_build.kubeflow_issuer
  depends_on = [
    module.cert_manager,
    var.dependency
  ]
}


data "kustomization_build" "istio_crds" {
  count = var.enable_istio_base ? 1 : 0
  path  = "${path.module}/submodules/manifests/common/istio-1-17/istio-crds/base"
}

module "istio_crds" {
  count  = var.enable_istio_base ? 1 : 0
  source = "./modules/kust"
  build  = one(data.kustomization_build.istio_crds)
  depends_on = [
    module.kubeflow_issuer
  ]
}

data "kustomization_build" "istio_namespace" {
  count = var.enable_istio_base ? 1 : 0
  path  = "${path.module}/submodules/manifests/common/istio-1-17/istio-namespace/base"
}

module "istio_namespace" {
  count  = var.enable_istio_base ? 1 : 0
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


  dynamic "patches" {
    for_each = var.enable_istio_ingressgateway_loadbalancer ? [1] : []
    content {
      target {
        kind      = "Service"
        name      = "istio-ingressgateway"
        namespace = "istio-system"
      }
      patch = <<EOF
  apiVersion: v1
  kind: Service
  metadata:
    name: istio-ingressgateway
    namespace: istio-system
  spec:
    type: LoadBalancer
  EOF
    }
  }
}

module "istio_install" {
  count  = var.enable_istiod ? 1 : 0
  source = "./modules/kust"
  build  = one(data.kustomization_overlay.istio_install)
  depends_on = [
    module.istio_namespace
  ]
}