
variable "enable_istio_ingressgateway_loadbalancer" {
  type    = bool
  default = false
}

variable "dependency" {
  type    = string
  default = "null"
}

variable "hostname" {
  type    = string
  default = "*"
}

variable enable_https {
  type    = bool
  default = false
}

variable "enable_cert_manager" {
  type    = bool
  default = true
}

variable "enable_istio_base" {
  type    = bool
  default = true
}

variable "enable_istiod" {
  type    = bool
  default = true
}

variable "enable_tensorboard" {
  type    = bool
  default = false
}

variable "enable_istio_resources" {
  type        = bool
  default     = true
  description = "Enable istio resources for clusters with pre-existing istio"
}

variable "enable_kubeflow_pipelines" {
  type    = bool
  default = false
}

variable "enable_kserve" {
  type    = bool
  default = false
}