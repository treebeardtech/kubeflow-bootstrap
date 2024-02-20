variable "owner_email" {
  description = "The email of the owner of the Kubeflow deployment"
  type        = string
}

data "kustomization_overlay" "kubeflow_profile" {
  resources = [
    "${path.module}/overlays/profile"
  ]

  patches {
    target {
      kind = "Profile"
      name = "prod"
    }
    patch = <<EOF
apiVersion: kubeflow.org/v1
kind: Profile
metadata:
  name: prod
spec:
  owner:
    kind: User
    name: ${var.owner_email}
EOF
  }
}

module "kubeflow_profile" {
  source = "./modules/kust"
  build  = data.kustomization_overlay.kubeflow_profile
  depends_on = [
    module.profiles_kfam
  ]
}
