
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