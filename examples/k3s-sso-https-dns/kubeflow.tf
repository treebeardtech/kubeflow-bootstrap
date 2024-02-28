module "treebeardkf" {
  count                  = var.enable_treebeardkf ? 1 : 0
  source                 = "../.."
  hostname               = var.host
  enable_istio_base      = false
  enable_istiod          = false
  enable_istio_resources = true
  enable_cert_manager    = false
  dependency             = null_resource.istio.id
}