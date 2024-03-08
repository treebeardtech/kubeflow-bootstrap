
variable "enable_argocd" {
  type    = bool
  default = true
}

variable "bootstrap_values" {
  description = "Extra values"
  type        = list(string)
  default     = []
}

variable "bootstrap_set" {
  description = "Value block with custom STRING values to be merged with the values yaml."
  type = list(object({
    name  = string
    value = string
  }))
  default = null
}

variable "bootstrap_set_sensitive" {
  description = "Value block with custom sensitive values to be merged with the values yaml that won't be exposed in the plan's diff."
  type = list(object({
    path  = string
    value = string
  }))
  default = null
}
