variable "treebeard_kubeflow_dependency" {
  description = "Configuration for Treebeard Kubeflow helm"
  type        = map(string)
  default = {
    repoURL        = "ghcr.io/treebeardtech"
    targetRevision = "0.1-2024-03-08-T12-25-15"
    chart          = "kubeflow-argo-apps"
  }
}

variable "enable_argocd" {
  type    = bool
  default = true
}

variable "kubeflow_values" {
  description = "Extra values"
  type        = list(string)
  default     = []
}

variable "kubeflow_set" {
  description = "Value block with custom STRING values to be merged with the values yaml."
  type = list(object({
    name  = string
    value = string
  }))
  default = null
}

variable "kubeflow_set_sensitive" {
  description = "Value block with custom sensitive values to be merged with the values yaml that won't be exposed in the plan's diff."
  type = list(object({
    path  = string
    value = string
  }))
  default = null
}
