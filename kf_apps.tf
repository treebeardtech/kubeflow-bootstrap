
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

data "kustomization_overlay" "kubeflow_profile" {
  resources = [
    "${path.module}/overlays/profile"
  ]

  patches {
    target {
      kind = "Profile"
      name = "prod"
    }
    patch = <<EOF
apiVersion: kubeflow.org/v1
kind: Profile
metadata:
  name: prod
spec:
  owner:
    kind: User
    name: user@example.com
EOF
  }
}

module "kubeflow_profile" {
  source = "./modules/kust"
  build  = data.kustomization_overlay.kubeflow_profile
  depends_on = [
    module.profiles_kfam
  ]
}
