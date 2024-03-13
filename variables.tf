variable "enable_argocd" {
  type    = bool
  default = true
}

variable "bootstrap_values" {
  description = "Extra values"
  type        = list(string)
  default     = []
}
