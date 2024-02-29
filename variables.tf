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

variable "enable_example_profile" {
  type    = bool
  default = true
}

variable "user_password" {
  type        = string
  description = "The password for the user"
  default     = "12341234"
  sensitive   = true
}
