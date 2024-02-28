
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
