locals {
  cert_resource = var.enable_https ? yamlencode({
    apiVersion: "cert-manager.io/v1",
    kind: "Certificate",
    metadata: {
      name: "gateway-cert",
      namespace: "istio-system"
    },
    spec: {
      commonName: var.hostname,
      dnsNames: [var.hostname]
      issuerRef: {
        kind: "Issuer",
        name: "treebeard-issuer"
      }
      secretName: "gateway-cert"
    }
  }) : ""

  gateway_patch = yamlencode({
    apiVersion: "networking.istio.io/v1alpha3",
    kind: "Gateway",
    metadata: {
      name: "kubeflow-gateway",
      namespace: "kubeflow",
    },
    spec: {
      selector: {
        istio: "ingressgateway",
      },
      servers: [{
        hosts: [var.hostname],
        port: {
          name: var.enable_https ? "https" : "http",
          number: var.enable_https ? 443 : 80,
          protocol: var.enable_https ? "HTTPS" : "HTTP",
        },
        tls: var.enable_https ? {
          credentialName: "gateway-cert",
          mode: "SIMPLE",
        } : null,
      }],
    },
  })
}

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
    patch = local.gateway_patch
  }
  
  patches {
    patch = local.cert_resource
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