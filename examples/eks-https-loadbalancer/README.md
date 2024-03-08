## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_helm"></a> [helm](#requirement\_helm) | ~> 2.12.1 |
| <a name="requirement_kubernetes"></a> [kubernetes](#requirement\_kubernetes) | ~> 2.25.2 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | 5.38.0 |
| <a name="provider_helm"></a> [helm](#provider\_helm) | 2.12.1 |
| <a name="provider_kubernetes"></a> [kubernetes](#provider\_kubernetes) | 2.25.2 |
| <a name="provider_null"></a> [null](#provider\_null) | 3.2.2 |

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_cert_manager_role"></a> [cert\_manager\_role](#module\_cert\_manager\_role) | terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks | 5.34.0 |
| <a name="module_ebs_csi_role"></a> [ebs\_csi\_role](#module\_ebs\_csi\_role) | terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks | 5.34.0 |
| <a name="module_eks"></a> [eks](#module\_eks) | terraform-aws-modules/eks/aws | ~> 19.20 |
| <a name="module_external_dns_role"></a> [external\_dns\_role](#module\_external\_dns\_role) | terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks | 5.34.0 |
| <a name="module_treebeardkf"></a> [treebeardkf](#module\_treebeardkf) | ../.. | n/a |
| <a name="module_vpc"></a> [vpc](#module\_vpc) | terraform-aws-modules/vpc/aws | 5.1.2 |

## Resources

| Name | Type |
|------|------|
| [helm_release.cert_manager](https://registry.terraform.io/providers/hashicorp/helm/latest/docs/resources/release) | resource |
| [helm_release.ebs_csi_driver](https://registry.terraform.io/providers/hashicorp/helm/latest/docs/resources/release) | resource |
| [helm_release.external_dns](https://registry.terraform.io/providers/hashicorp/helm/latest/docs/resources/release) | resource |
| [helm_release.issuer](https://registry.terraform.io/providers/hashicorp/helm/latest/docs/resources/release) | resource |
| [helm_release.istio_base](https://registry.terraform.io/providers/hashicorp/helm/latest/docs/resources/release) | resource |
| [helm_release.istio_ingressgateway](https://registry.terraform.io/providers/hashicorp/helm/latest/docs/resources/release) | resource |
| [helm_release.istiod](https://registry.terraform.io/providers/hashicorp/helm/latest/docs/resources/release) | resource |
| [kubernetes_annotations.default-storageclass](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/annotations) | resource |
| [null_resource.cluster_ready](https://registry.terraform.io/providers/hashicorp/null/latest/docs/resources/resource) | resource |
| [null_resource.core_addons](https://registry.terraform.io/providers/hashicorp/null/latest/docs/resources/resource) | resource |
| [null_resource.istio](https://registry.terraform.io/providers/hashicorp/null/latest/docs/resources/resource) | resource |
| [aws_availability_zones.available](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/availability_zones) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_aws_profile"></a> [aws\_profile](#input\_aws\_profile) | AWS profile to use for authentication. | `any` | n/a | yes |
| <a name="input_aws_region"></a> [aws\_region](#input\_aws\_region) | AWS region to launch servers. | `any` | n/a | yes |
| <a name="input_cert_email_owner"></a> [cert\_email\_owner](#input\_cert\_email\_owner) | n/a | `any` | n/a | yes |
| <a name="input_enable_treebeardkf"></a> [enable\_treebeardkf](#input\_enable\_treebeardkf) | Enable Treebeard KF | `bool` | `false` | no |
| <a name="input_host"></a> [host](#input\_host) | n/a | `any` | n/a | yes |
| <a name="input_hosted_zone_id"></a> [hosted\_zone\_id](#input\_hosted\_zone\_id) | n/a | `any` | n/a | yes |
| <a name="input_password"></a> [password](#input\_password) | password for user@example.com | `any` | n/a | yes |

## Outputs

No outputs.
