module "treebeardkf" {
  count  = var.enable_treebeardkf ? 1 : 0
  source = "../.."
  kubeflow_values = [
    <<EOF
sources:
- repoURL: 'https://github.com/treebeardtech/treebeard-kubeflow-gitops'
  targetRevision: 8e3369ac3720bd837f75d812b9ec9d5f9d135cef
  ref: values
valueFiles:
- $values/clusters/eks-https-loadbalancer.yaml
valuesObject:
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

  dex:
    spec:
      project: default
      source:
        kustomize:
          patches:
          - target:
              kind: Secret
              name: dex-passwords
            patch: |-
              - op: replace
                path: /stringData/DEX_USER_PASSWORD
                value: ${bcrypt(var.password)}
EOF
  ]
  depends_on = [
    null_resource.cluster_ready,
    null_resource.core_addons,
    null_resource.istio
  ]
}