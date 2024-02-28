resource "helm_release" "istio_base" {
  name             = "istio-base"
  namespace        = "istio-system"
  chart            = "base"
  repository       = "https://istio-release.storage.googleapis.com/charts"
  version          = "1.18.7"
  create_namespace = true
  values = [
    <<EOF
    EOF
  ]
  depends_on = [
    null_resource.core_addons
  ]
}

resource "helm_release" "issuer" {
  name      = "issuer"
  namespace = "istio-system"
  chart     = "${path.module}/issuer"
  values = [
    <<EOF
    certEmailOwner: ${var.cert_email_owner}
    hostedZoneId: ${var.hosted_zone_id}
    EOF
  ]
  depends_on = [
    helm_release.istio_base
  ]
}

resource "helm_release" "istiod" {
  name             = "istiod"
  namespace        = "istio-system"
  chart            = "istiod"
  repository       = "https://istio-release.storage.googleapis.com/charts"
  version          = "1.18.7"
  create_namespace = true
  values = [
    <<EOF
    EOF
  ]
  depends_on = [
    helm_release.issuer
  ]
}

resource "helm_release" "istio_ingressgateway" {
  name       = "istio-ingressgateway"
  namespace  = "istio-system"
  chart      = "gateway"
  repository = "https://istio-release.storage.googleapis.com/charts"
  version    = "1.18.7"
  values = [
    <<EOF
    service:
      type: LoadBalancer
    serviceAccount:
      name: istio-ingressgateway-service-account
    EOF
  ]
  depends_on = [
    helm_release.istiod
  ]
}

resource "null_resource" "istio" {
  # triggers = {
  #   always_run = "${timestamp()}"
  # }

  provisioner "local-exec" {
    command = "echo 'Istio is ready!'"
  }
  depends_on = [
    helm_release.istio_ingressgateway
  ]
}
