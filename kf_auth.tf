

data "kustomization_overlay" "oidc_authservice" {
  config_map_generator {
    name     = "oidc-authservice-parameters"
    behavior = "merge"
    literals = [
      # "OIDC_PROVIDER=${var.protocol}${var.hostname}${var.port}/dex"
    ]
  }

  resources = [
    "${path.module}/submodules/manifests/common/oidc-client/oidc-authservice/base",
  ]
}

module "oidc_authservice" {
  source = "./modules/kust"
  build  = data.kustomization_overlay.oidc_authservice
  depends_on = [
    module.istio_install,
    var.dependency
  ]
}

data "kustomization_overlay" "dex" {
  resources = [
    "${path.module}/submodules/manifests/common/dex/overlays/istio"
  ]
  patches {
    patch = <<EOF
apiVersion: v1
kind: ConfigMap
metadata:
  name: dex
  namespace: auth
data:
  config.yaml: |-
    issuer: http://dex.auth.svc.cluster.local:5556/dex
    storage:
      type: kubernetes
      config:
        inCluster: true
    web:
      http: 0.0.0.0:5556
    logger:
      level: "debug"
      format: text
    oauth2:
      skipApprovalScreen: false
    enablePasswordDB: true
    staticPasswords:
    - email: user@example.com
      hash: $2y$12$4K/VkmDd1q1Orb3xAt82zu8gk7Ad6ReFR4LCP9UeYE90NLiN9Df72
      # https://github.com/dexidp/dex/pull/1601/commits
      # FIXME: Use hashFromEnv instead
      username: user
      userID: "15841185641784"
    staticClients:
    # https://github.com/dexidp/dex/pull/1664
    - idEnv: OIDC_CLIENT_ID
      redirectURIs: ["/authservice/oidc/callback"]
      name: 'Dex Login Application'
      secretEnv: OIDC_CLIENT_SECRET
    connectors: []
EOF
  }
}

module "dex" {
  source = "./modules/kust"
  build  = data.kustomization_overlay.dex
  depends_on = [
    module.istio_install,
    module.oidc_authservice
  ]
}
