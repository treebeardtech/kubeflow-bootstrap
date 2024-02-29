
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

variable "enable_https" {
  type    = bool
  default = false
}

variable "issuer_name" {
  type        = string
  default     = "null"
  description = "Required if enable_https is true"
}

variable "enable_argocd" {
  type    = bool
  default = true
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

variable "enable_istio_resources" {
  type        = bool
  default     = true
  description = "Enable istio resources for clusters with pre-existing istio"
}
