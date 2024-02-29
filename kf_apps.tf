
resource "helm_release" "central_dashboard" {
  name      = "centraldashboard"
  namespace = "argo-cd"
  chart     = "${path.module}/charts/argo_app"
  depends_on = [
    module.kubeflow_istio_resources,
  ]
  values = [
    <<EOF
    name: centraldashboard
    repoURL: https://github.com/kubeflow/manifests
    path: apps/centraldashboard/upstream/overlays/kserve
    targetRevision: 776d4f4
    EOF
  ]
}

resource "helm_release" "admission_webhook" {
  name      = "admission-webhook"
  namespace = "argo-cd"
  chart     = "${path.module}/charts/argo_app"
  depends_on = [
    helm_release.central_dashboard
  ]
  values = [
    <<EOF
    name: admission-webhook
    repoURL: https://github.com/kubeflow/manifests
    path: apps/admission-webhook/upstream/overlays/cert-manager
    targetRevision: 776d4f4
    EOF
  ]
}

resource "helm_release" "notebook_controller" {
  name      = "notebook-controller"
  namespace = "argo-cd"
  chart     = "${path.module}/charts/argo_app"
  depends_on = [
    helm_release.admission_webhook
  ]
  values = [
    <<EOF
    name: notebook-controller
    repoURL: https://github.com/kubeflow/manifests
    path: apps/jupyter/notebook-controller/upstream/overlays/kubeflow
    targetRevision: 776d4f4
    EOF
  ]
}

resource "helm_release" "jupyter_web_app" {
  name      = "jupyter-web-app"
  namespace = "argo-cd"
  chart     = "${path.module}/charts/argo_app"
  depends_on = [
    helm_release.notebook_controller
  ]
  values = [
    <<EOF
    name: jupyter-web-app
    repoURL: https://github.com/kubeflow/manifests
    path: apps/jupyter/jupyter-web-app/upstream/overlays/istio
    targetRevision: 776d4f4
    EOF
  ]
}

resource "helm_release" "pvc_viewer_controller" {
  name      = "pvcviewer-controller"
  namespace = "argo-cd"
  chart     = "${path.module}/charts/argo_app"
  depends_on = [
    helm_release.jupyter_web_app
  ]
  values = [
    <<EOF
    name: pvcviewer-controller
    repoURL: https://github.com/kubeflow/manifests
    path: pps/pvcviewer-controller/upstream/default
    targetRevision: 776d4f4
    EOF
  ]
}

resource "helm_release" "profiles_kfam" {
  name      = "profiles-kfam"
  namespace = "argo-cd"
  chart     = "${path.module}/charts/argo_app"
  depends_on = [
    helm_release.pvc_viewer_controller
  ]
  values = [
    <<EOF
    name: profiles-kfam
    repoURL: https://github.com/kubeflow/manifests
    path: apps/profiles/upstream/overlays/kubeflow
    targetRevision: 776d4f4
    EOF
  ]
}

resource "helm_release" "volumes_web_app" {
  name      = "volumes-web-app"
  namespace = "argo-cd"
  chart     = "${path.module}/charts/argo_app"
  depends_on = [
    helm_release.profiles_kfam
  ]
  values = [
    <<EOF
    name: volumes-web-app
    repoURL: https://github.com/kubeflow/manifests
    path: apps/volumes-web-app/upstream/overlays/istio
    targetRevision: 776d4f4
    EOF
  ]
}

resource "helm_release" "kubeflow_profile" {
  name      = "kubeflow-profile"
  namespace = "argo-cd"
  chart     = "${path.module}/charts/profile"
  depends_on = [
    helm_release.volumes_web_app
  ]
  values = [
    <<EOF
EOF
  ]
}