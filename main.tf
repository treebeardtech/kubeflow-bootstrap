locals {
  start_message = "⏳ Installing Kubeflow..."
  bootstrap_default = [
    <<EOF
targetRevision: 0.1-2024-03-11-T15-14-41
EOF
  ]
}

resource "null_resource" "start" {
  provisioner "local-exec" {
    command = "echo ${local.start_message}"
  }
}

resource "helm_release" "argo_cd" {
  count = var.enable_argocd ? 1 : 0

  name             = "argocd"
  namespace        = "argocd"
  chart            = "argo-cd"
  repository       = "https://argoproj.github.io/argo-helm"
  version          = "6.4.1"
  create_namespace = true
  depends_on = [
    null_resource.start
  ]
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


  dynamic "set" {
    iterator = item
    for_each = var.bootstrap_set == null ? [] : var.bootstrap_set

    content {
      name  = item.value.name
      value = item.value.value
    }
  }

  dynamic "set_sensitive" {
    iterator = item
    for_each = var.bootstrap_set_sensitive == null ? [] : var.bootstrap_set_sensitive

    content {
      name  = item.value.path
      value = item.value.value
    }
  }

  depends_on = [
    helm_release.argo_cd
  ]
}
