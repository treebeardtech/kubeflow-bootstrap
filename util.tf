resource "kubernetes_namespace" "tkf_system" {
  metadata {
    name = "tkf-system"
    labels = {
      "admission.gatekeeper.sh/ignore" = "no-self-managing" # this gets added by gatekeeper otherwise
    }
  }
}

variable "enable_gatekeeper" {
  type    = bool
  default = false
}

resource "helm_release" "gatekeeper" {
  count      = var.enable_gatekeeper ? 1 : 0
  name       = "gatekeeper"
  chart      = "gatekeeper"
  repository = "https://open-policy-agent.github.io/gatekeeper/charts"
  namespace  = kubernetes_namespace.tkf_system.metadata[0].name
  version    = "3.15.0-beta.0"
  depends_on = [
    kubernetes_namespace.tkf_system
  ]
  values = [
    <<EOF
    EOF
  ]
}

variable "enable_external_secrets" {
  type    = bool
  default = false
}

resource "helm_release" "external_secrets" {
  count      = var.enable_external_secrets ? 1 : 0
  name       = "external-secrets"
  chart      = "external-secrets"
  repository = "https://charts.external-secrets.io/"
  namespace  = kubernetes_namespace.tkf_system.metadata[0].name
  version    = "0.9.11"
  depends_on = [
    kubernetes_namespace.tkf_system
  ]
  values = [
    <<EOF

    EOF
  ]
}

# $ helm repo add nvdp https://nvidia.github.io/k8s-device-plugin
# $ helm repo update
# Then verify that the latest release (v0.14.3) of the plugin is available:

# $ helm search repo nvdp --devel
# NAME                         CHART VERSION  APP VERSION  DESCRIPTION
# nvdp/nvidia-device-plugin    0.14.3   0.14.3    A Helm chart for ...
# Once this repo is updated, you can begin installing packages from it to deploy the nvidia-device-plugin helm chart.

# The most basic installation command without any options is then:

# helm upgrade -i nvdp nvdp/nvidia-device-plugin \
#   --namespace nvidia-device-plugin \
#   --create-namespace \
#   --version 0.14.3

# resource "helm_release" "nvidia_device_plugin" {
#   # count      = var.enable_nvidia_device_plugin ? 1 : 0
#   name       = "nvidia-device-plugin"
#   chart      = "nvidia-device-plugin"
#   repository = "https://nvidia.github.io/k8s-device-plugin"
#   namespace  = kubernetes_namespace.tkf_system.metadata[0].name
#   version    = "0.14.3"
#   depends_on = [
#     kubernetes_namespace.tkf_system
#   ]
#   values = [
#     <<EOF
#     EOF
#   ]
# }

# helm repo add nvidia https://helm.ngc.nvidia.com/nvidia \
#     && helm repo update

# helm upgrade -i --wait --generate-name \
#     -n gpu-operator --create-namespace

# note: enabling gpus requires
# kubectl edit cm jupyter-web-app-config-<suffix> -n kubeflow and adding the commented out vendors
# updating the notebook runtimeClassName to 'nvidia'

variable "enable_gpu_operator" {
  type    = bool
  default = false
}

resource "helm_release" "gpu_operator" {
  count      = var.enable_gpu_operator ? 1 : 0
  name       = "gpu-operator"
  chart      = "gpu-operator"
  repository = "https://helm.ngc.nvidia.com/nvidia"
  namespace  = kubernetes_namespace.tkf_system.metadata[0].name
  depends_on = [
    kubernetes_namespace.tkf_system
  ]
  values = [
    <<EOF
    EOF
  ]
}

variable "enable_external_dns" {
  type    = bool
  default = true
}

variable "aws_region" {
  type    = string
  default = "eu-west-1"
}
