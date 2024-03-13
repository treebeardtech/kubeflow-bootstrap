locals {
  bootstrap_default = [
    <<EOF
targetRevision: 0.1-2024-03-11-T15-14-41
EOF
  ]
}

resource "helm_release" "argo_cd" {
  count = var.enable_argocd ? 1 : 0

  name             = "argocd"
  namespace        = "argocd"
  chart            = "argo-cd"
  repository       = "https://argoproj.github.io/argo-helm"
  version          = "6.4.1"
  create_namespace = true
  values = [
    <<EOF
dex:
  enabled: false
EOF
  ]
}

resource "helm_release" "argo_bootstrap" {
  name          = "argo-bootstrap"
  namespace     = "argocd"
  chart         = "${path.module}/helm/bootstrap"
  wait_for_jobs = true
  values        = concat(local.bootstrap_default, var.bootstrap_values)
  depends_on = [
    helm_release.argo_cd
  ]
}
