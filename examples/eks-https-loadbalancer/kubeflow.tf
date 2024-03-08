module "treebeardkf" {
  count  = var.enable_treebeardkf ? 1 : 0
  source = "../.."
  kubeflow_values = [
    <<EOF
certManager:
  enabled: false
istioBase:
  enabled: false
istiod:
  enabled: false
istioResources:
  spec:
    source:
      kustomize:
        patches:
        - target:
            kind: Gateway
            name: kubeflow-gateway
          patch: |-
            - op: replace
              path: /spec/servers/0
              value:
                hosts:
                - ${var.host}
                port:
                  name: https
                  number: 443
                  protocol: HTTPS
                tls:
                  credentialName: gateway-cert
                  mode: SIMPLE
EOF
  ]
  depends_on = [
    null_resource.cluster_ready,
    null_resource.core_addons,
    null_resource.istio
  ]
}