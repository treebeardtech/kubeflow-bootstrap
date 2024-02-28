
module "ebs_csi_role" {
  source                = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"
  version               = "5.34.0"
  role_name             = "irsa-ebs-csi"
  attach_ebs_csi_policy = true
  oidc_providers = {
    main = {
      provider_arn               = module.eks.oidc_provider_arn
      namespace_service_accounts = ["kube-system:ebs-csi-controller-sa"]
    }
  }
  depends_on = [
    null_resource.cluster_ready
  ]
}

resource "kubernetes_annotations" "default-storageclass" {
  api_version = "storage.k8s.io/v1"
  kind        = "StorageClass"
  force       = "true"

  metadata {
    name = "gp2"
  }
  annotations = {
    "storageclass.kubernetes.io/is-default-class" = "false"
  }
  depends_on = [
    null_resource.cluster_ready
  ]
}

resource "helm_release" "ebs_csi_driver" {
  name       = "aws-ebs-csi-driver"
  chart      = "aws-ebs-csi-driver"
  repository = "https://kubernetes-sigs.github.io/aws-ebs-csi-driver"
  namespace  = "kube-system"
  version    = "2.28.1"
  values = [
    <<EOF
controller:
  serviceAccount:
    annotations:
      eks.amazonaws.com/role-arn: ${module.ebs_csi_role.iam_role_arn}
storageClasses:
- name: ebs-sc
  annotations:
    storageclass.kubernetes.io/is-default-class: "true"
    EOF
  ]
  depends_on = [
    null_resource.cluster_ready
  ]
}

## DNS Setup

module "external_dns_role" {
  source                     = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"
  version                    = "5.34.0"
  role_name                  = "external-dns"
  attach_external_dns_policy = true
  oidc_providers = {
    main = {
      provider_arn               = module.eks.oidc_provider_arn
      namespace_service_accounts = ["external-dns:external-dns"]
    }
  }
  depends_on = [
    null_resource.cluster_ready
  ]
}

resource "helm_release" "external_dns" {
  name             = "external-dns"
  chart            = "external-dns"
  repository       = "https://kubernetes-sigs.github.io/external-dns/"
  namespace        = "external-dns"
  create_namespace = true
  version          = "1.14.0"
  values = [
    <<-EOF
    sources:
    - istio-gateway
    provider: aws
    env:
      - name: AWS_REGION
    serviceAccount:
      annotations:
        eks.amazonaws.com/role-arn: ${module.external_dns_role.iam_role_arn}
    securityContext:
      fsGroup: 1001
    EOF
  ]
  depends_on = [
    null_resource.cluster_ready
  ]
}

## HTTPS Setup

module "cert_manager_role" {
  source                     = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"
  version                    = "5.34.0"
  role_name                  = "cert-manager"
  attach_cert_manager_policy = true
  oidc_providers = {
    main = {
      provider_arn               = module.eks.oidc_provider_arn
      namespace_service_accounts = ["cert-manager:cert-manager"]
    }
  }
}

resource "helm_release" "cert_manager" {
  name             = "cert-manager"
  namespace        = "cert-manager"
  chart            = "cert-manager"
  repository       = "https://charts.jetstack.io"
  version          = "1.12.8"
  create_namespace = true
  depends_on = [
    helm_release.external_dns
  ]
  values = [
    <<EOF
    installCRDs: true
    serviceAccount:
      annotations:
        eks.amazonaws.com/role-arn: ${module.cert_manager_role.iam_role_arn}
    securityContext:
      fsGroup: 1001
    extraArgs:
      - --issuer-ambient-credentials=true
      - --cluster-issuer-ambient-credentials=true
    EOF
  ]
}

resource "null_resource" "core_addons" {
  # triggers = {
  #   always_run = "${timestamp()}"
  # }

  provisioner "local-exec" {
    when    = destroy
    command = "echo 'Waiting for addons to cleanup DNS/Loadbalancers' && sleep 60"
  }

  depends_on = [
    helm_release.cert_manager
  ]
}