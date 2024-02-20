# helm repo add community-charts https://community-charts.github.io/helm-charts
# helm repo update
# helm install my-mlflow community-charts/mlflow --version 0.7.19

variable "enable_mlflow" {
  type    = bool
  default = false
}

resource "helm_release" "mlflow" {
  count      = var.enable_mlflow ? 1 : 0
  name       = "my-mlflow"
  repository = "https://community-charts.github.io/helm-charts"
  chart      = "mlflow"
  version    = "0.7.19"
  namespace  = "kubeflow"
  depends_on = [module.central_dashboard]
  values = [
    <<EOF
    EOF
  ]
}

data "kustomization_build" "mlflow_istio" {
  count = var.enable_mlflow ? 1 : 0
  path  = "${path.module}/overlays/mlflow-istio"
}

module "mlflow_istio" {
  count  = var.enable_mlflow ? 1 : 0
  source = "./modules/kust"
  build  = data.kustomization_build.mlflow_istio[0]
  depends_on = [
    helm_release.mlflow
  ]
}