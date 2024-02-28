resource "null_resource" "dependency" {
  depends_on = [
    null_resource.cluster_ready,
    null_resource.core_addons,
    null_resource.istio,
  ]
}

module "treebeardkf" {
  count                  = var.enable_treebeardkf ? 1 : 0
  source                 = "../.."
  hostname               = var.host
  enable_https           = true
  enable_istio_base      = false
  enable_istiod          = false
  enable_istio_resources = true
  enable_cert_manager    = false
  dependency             = null_resource.dependency.id
}