data "kustomization_build" "kubeflow_namespace" {
  path = "${path.module}/submodules/manifests/common/kubeflow-namespace/base"
}

module "kubeflow_namespace" {
  source = "./modules/kust"
  build  = data.kustomization_build.kubeflow_namespace
  depends_on = [
    module.dex
  ]
}

data "kustomization_build" "kubeflow_roles" {
  path = "${path.module}/submodules/manifests/common/kubeflow-roles/base"
}

module "kubeflow_roles" {
  source = "./modules/kust"
  build  = data.kustomization_build.kubeflow_roles
  depends_on = [
    module.kubeflow_namespace
  ]
}

data "kustomization_overlay" "kubeflow_istio_resources" {
  count = var.enable_istio_resources ? 1 : 0
  resources = [
    "${path.module}/overlays/istio-resources"
  ]
  patches {
    patch = <<EOF
apiVersion: cert-manager.io/v1
kind: Certificate
metadata:
  name: gateway-cert
  namespace: istio-system
spec:
  commonName: ${var.hostname}
  dnsNames:
    - ${var.hostname}
EOF
  }

  patches {
    patch = <<EOF
apiVersion: networking.istio.io/v1alpha3
kind: Gateway
metadata:
  name: kubeflow-gateway
  namespace: kubeflow
spec:
  selector:
    istio: ingressgateway
  servers:
    - hosts:
        - ${var.hostname}
      port:
        name: https
        number: 443
        protocol: HTTPS
      tls:
        credentialName: gateway-cert
        mode: SIMPLE
    # enable for port forwarding to work with HTTP
    # - hosts:
    #     - '*'
    #   port:
    #     name: http
    #     number: 80
    #     protocol: HTTP
EOF
  }
}

module "kubeflow_istio_resources" {
  count  = var.enable_istio_resources ? 1 : 0
  source = "./modules/kust"
  build  = data.kustomization_overlay.kubeflow_istio_resources[0]
  depends_on = [
    module.kubeflow_roles
  ]
}