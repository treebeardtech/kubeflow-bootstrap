module "treebeardkf" {
  count  = var.enable_treebeardkf ? 1 : 0
  source = "../.."
  bootstrap_values = [
    <<EOF
values: |
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
  gateway:
    spec:
      sources:
        - chart: 'gateway'
          repoURL: 'https://istio-release.storage.googleapis.com/charts'
          targetRevision: "1.18.7"
          helm:
            releaseName: "istio-ingressgateway"
            ignoreMissingValueFiles: true
            valueFiles: []
            values: |
              service:
                type: LoadBalancer
              serviceAccount:
                name: istio-ingressgateway-service-account
              resources:
                requests:
                  cpu: 10m
                  memory: 64Mi
                limits:
                  cpu: 2000m
                  memory: 1024Mi
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