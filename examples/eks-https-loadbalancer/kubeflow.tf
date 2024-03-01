module "treebeardkf" {
  count                  = var.enable_treebeardkf ? 1 : 0
  source                 = "../.."
  hostname               = var.host
  enable_https           = true
  issuer_name            = "treebeard-issuer"
  enable_istio_base      = false
  enable_istiod          = false
  enable_istio_resources = true
  enable_cert_manager    = false
  depends_on = [
    null_resource.cluster_ready,
    null_resource.core_addons,
    null_resource.istio
  ]
}