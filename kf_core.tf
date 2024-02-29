locals {
  cert_resource = var.enable_https ? yamlencode({
    apiVersion : "cert-manager.io/v1",
    kind : "Certificate",
    metadata : {
      name : "gateway-cert",
      namespace : "istio-system"
    },
    spec : {
      commonName : var.hostname,
      dnsNames : [var.hostname]
      issuerRef : {
        kind : "Issuer",
        name : "treebeard-issuer"
      }
      secretName : "gateway-cert"
    }
  }) : ""
}

resource "null_resource" "kf_core_start" {
  provisioner "local-exec" {
    command = "echo '⏳ Installing Kubeflow core...'"
  }

  depends_on = [
    null_resource.kf_dependencies_end
  ]
}

resource "helm_release" "dex" {
  name      = "dex"
  namespace = "argo-cd"
  chart     = "${path.module}/charts/argo_app"
  wait_for_jobs = true
  values = [
    <<EOF
    name: dex
    repoURL: https://github.com/kubeflow/manifests
    path: common/dex/overlays/istio
    targetRevision: 776d4f4
    EOF
  ]
  depends_on = [
    null_resource.kf_core_start,
  ]
}

resource "helm_release" "oidc_authservice" {
  name      = "oidc-authservice"
  namespace = "argo-cd"
  chart     = "${path.module}/charts/argo_app"
  wait_for_jobs = true
  values = [
    <<EOF
    name: oidc-authservice
    repoURL: https://github.com/kubeflow/manifests
    path: common/oidc-client/oidc-authservice/base
    targetRevision: 776d4f4
    EOF
  ]
  depends_on = [
    helm_release.dex
  ]
}

resource "helm_release" "kubeflow_namespace" {
  name      = "kubeflow-namespace"
  namespace = "argo-cd"
  chart     = "${path.module}/charts/argo_app"
  wait_for_jobs = true
  values = [
    <<EOF
    name: kubeflow-namespace
    repoURL: https://github.com/kubeflow/manifests
    path: common/kubeflow-namespace/base
    targetRevision: 776d4f4
    EOF
  ]
  depends_on = [
    null_resource.kf_core_start
  ]
}

resource "helm_release" "kubeflow_roles" {
  name      = "kubeflow-roles"
  namespace = "argo-cd"
  chart     = "${path.module}/charts/argo_app"
  wait_for_jobs = true
  values = [
    <<EOF
    name: kubeflow-roles
    repoURL: https://github.com/kubeflow/manifests
    path: common/kubeflow-roles/base
    targetRevision: 776d4f4
    EOF
  ]
  depends_on = [
    helm_release.kubeflow_namespace
  ]
}

resource "helm_release" "kubeflow_istio_resources" {
  count  = var.enable_istio_resources ? 1 : 0
  name      = "kubeflow-istio-resources"
  namespace = "argo-cd"
  chart     = "${path.module}/charts/argo_app"
  wait_for_jobs = true
  values = [
    <<EOF
    name: kubeflow-istio-resources
    repoURL: https://github.com/kubeflow/manifests
    path: common/istio-1-17/kubeflow-istio-resources/base
    targetRevision: 776d4f4
    hostname: '${var.hostname}'
    enableHttps: '${var.enable_https}'
    issuerName: '${var.issuer_name}'
    EOF
  ]
  depends_on = [
    helm_release.kubeflow_namespace
  ]
}

resource "null_resource" "kf_core_end" {
  provisioner "local-exec" {
    command = "echo '✅ Kubeflow core installed'"
  }

  depends_on = [
    helm_release.kubeflow_namespace,
    helm_release.kubeflow_roles,
    helm_release.kubeflow_istio_resources,
    helm_release.oidc_authservice,
  ]
}