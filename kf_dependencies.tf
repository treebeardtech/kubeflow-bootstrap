
resource "null_resource" "kf_dependencies_start" {
  provisioner "local-exec" {
    command = "echo '⏳ Installing Kubeflow dependencies...'"
  }
}

resource "helm_release" "cert_manager" {
  count            = var.enable_cert_manager ? 1 : 0
  name             = "cert-manager"
  namespace        = "cert-manager"
  chart            = "cert-manager"
  repository       = "https://charts.jetstack.io"
  version          = "1.14.3"
  create_namespace = true
  depends_on = [
    null_resource.kf_dependencies_start
  ]
  values = [
    <<EOF
    installCRDs: true
    EOF
  ]
}

resource "helm_release" "istio_base" {
  count            = var.enable_istio_base ? 1 : 0
  name             = "istio-base"
  namespace        = "istio-system"
  chart            = "base"
  repository       = "https://istio-release.storage.googleapis.com/charts"
  version          = "1.18.7"
  create_namespace = true
  depends_on = [
    helm_release.cert_manager
  ]
  values = [
    <<EOF
    EOF
  ]
}

resource "helm_release" "istiod" {
  count            = var.enable_istiod ? 1 : 0
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
pilot:
  resources:
    requests:
      cpu: 10m
      memory: 128Mi
global:
  proxy:
    resources:
      requests:
        cpu: 10m
        memory: 64Mi
    EOF
  ]
}

resource "helm_release" "cluster_issuer" {
  name      = "kubeflow-profile"
  namespace = "cert-manager"
  chart     = "${path.module}/charts/issuer"
  values = [
    <<EOF
EOF
  ]
  depends_on = [
    helm_release.cert_manager
  ]
}

resource "helm_release" "istio_ingressgateway" {
  count      = var.enable_istiod ? 1 : 0
  name       = "istio-ingressgateway"
  namespace  = "istio-system"
  chart      = "gateway"
  repository = "https://istio-release.storage.googleapis.com/charts"
  version    = "1.18.7"
  depends_on = [
    helm_release.istiod,
    helm_release.cluster_issuer
  ]
  values = [
    <<EOF
service:
  type: ClusterIP
serviceAccount:
  name: istio-ingressgateway-service-account
resources:
  requests:
    cpu: 10m
    memory: 64Mi
  limits:
    cpu: 2000m
    memory: 1024Mi
    EOF
  ]
}

resource "helm_release" "argo_cd" {
  count = var.enable_argocd ? 1 : 0

  name             = "argo-cd"
  namespace        = "argo-cd"
  chart            = "argo-cd"
  repository       = "https://argoproj.github.io/argo-helm"
  version          = "6.4.1"
  create_namespace = true
  depends_on = [
    null_resource.kf_dependencies_start
  ]
  values = [
    <<EOF
    EOF
  ]
}

resource "time_sleep" "wait" {
  depends_on = [
    helm_release.istiod,
    helm_release.argo_cd,
  ]

  create_duration  = "10s"
  destroy_duration = "10s"
}

resource "null_resource" "kf_dependencies_end" {
  provisioner "local-exec" {
    when    = create
    command = "echo '✅ Kubeflow dependencies installed'"
  }

  provisioner "local-exec" {
    when = destroy # note, this only runs when the root module is destroyed
    # https://github.com/hashicorp/terraform/issues/13549
    command = "echo 'Tearing down kf_dependencies'"
  }

  depends_on = [
    time_sleep.wait,
    helm_release.cert_manager,
    helm_release.istio_base,
    helm_release.istiod,
    helm_release.istio_ingressgateway,
    helm_release.argo_cd,
    helm_release.cluster_issuer
  ]
}