## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_kustomization"></a> [kustomization](#requirement\_kustomization) | 0.9.5 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_kustomization"></a> [kustomization](#provider\_kustomization) | 0.9.5 |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [kustomization_resource.p0](https://registry.terraform.io/providers/kbst/kustomization/0.9.5/docs/resources/resource) | resource |
| [kustomization_resource.p1](https://registry.terraform.io/providers/kbst/kustomization/0.9.5/docs/resources/resource) | resource |
| [kustomization_resource.p2](https://registry.terraform.io/providers/kbst/kustomization/0.9.5/docs/resources/resource) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_build"></a> [build](#input\_build) | description | <pre>object({<br>    ids       = list(string)<br>    ids_prio  = list(list(string))<br>    manifests = map(string)<br>  })</pre> | n/a | yes |

## Outputs

No outputs.
