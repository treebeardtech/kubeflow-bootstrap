locals {
  start_message = "⏳ Installing Kubeflow..."
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

locals {
  user_vals = "\n${var.kubeflow_values[0]}"
  default_values = [
    <<EOF
treebeardKubeflow:
  repoURL: "ghcr.io/treebeardtech"
  targetRevision: 0.1-2024-03-08-T10-50-10
  chart: 'kubeflow-argo-apps'
  values: ${indent(4, local.user_vals)}
EOF
  ]
}

resource "helm_release" "kubeflow_apps" {
  name          = "kubeflow-apps"
  namespace     = "argocd"
  chart         = "${path.module}/helm/kubeflow-bootstrap"
  wait_for_jobs = true
  values        = concat(local.default_values)

  dynamic "set" {
    iterator = item
    for_each = var.kubeflow_set == null ? [] : var.kubeflow_set

    content {
      name  = item.value.name
      value = item.value.value
    }
  }

  dynamic "set_sensitive" {
    iterator = item
    for_each = var.kubeflow_set_sensitive == null ? [] : var.kubeflow_set_sensitive

    content {
      name  = item.value.path
      value = item.value.value
    }
  }
  depends_on = [
    null_resource.start,
    helm_release.argo_cd
  ]
}