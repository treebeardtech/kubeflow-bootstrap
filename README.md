<div align="center">
  <h1>Kubeflow Terraform Modules</h1>

Terraform module which creates a Kubeflow instance in a Kubernetes cluster

<a target="_blank" href="https://registry.terraform.io/modules/treebeardtech/kubeflow/kubernetes/0.0.3" style="background:none">
  <img alt="dagster logo" src="docs/tkf.png" width="400" height="100%">
</a>
</div>

> [!Note]  
> This repository is currently suitable for development environments only. Please report any problem you might have by opening a GitHub issue, feature requests welcome.

## About this project

This project simplifies the tasks of managing a Kubeflow instance in Terraform projects.

Kubeflow provides a cloud-native AI platform which can be used to deploy applications in
scientific computing, traditional machine learning, and generative AI.

This module is primarily focussed on the notebook environment initially such that
* Developers can deploy and access notebook instances
* Notebook instances can use GPUs necessary for deep learning
* This can be done across different cloud providers (ranging from individual VMs to managed services like Amazon's EKS)

## Getting Started

We recommend trying out this module in a development environment first.

To do so, follow the [k3s tutorial](https://github.com/treebeardtech/terraform-kubernetes-kubeflow/tree/main/examples).

## Guides

### Add Kubeflow to your Terraform module

```hcl
# resource or data for your k8s cluster
...

# Initialize provisioners
provider "kubernetes" {
  ...
}

provider "helm" {
  ...
}

provider "kustomization" {
  ...
}

# Call Kubeflow module
module "treebeardkf" {
  source         = "../.."
  hostname       = "kf.example.com"
  protocol       = "https://"
  port           = ""
  enable_kuberay = false
  enable_mlflow  = false
}
```

### Install in an existing cluster

You can incrementally add Kubeflow to your K8s cluster by installing the terraform module.

Some considerations:
1. If you are calling this Terraform module from your own module, pass in a string to the `completed` variable in order to manage Kubeflow *after* changes to your other resources. (Note that `depends_on` does not work with this module)
2. If you already have Istio and Cert Manager installed, you will need to ensure Kubeflow works with them. See [examples/k3s-existing-istio](examples/k3s-existing-istio) for a configuration that we have tested like this.

### Teardown

1. Manually remove any manually created Kubeflow resources, e.g. Notebook Servers and Volumes
2. Remove the terraform module, e.g. with `terraform destroy` if you have installed directly from CLI
3. Clean up remaining resources, e.g. Istio leaves behind some secrets that can prevent successful re-installation. 

## Architecture

This module is built on top of the official [Kubeflow Manifests repo](https://github.com/kubeflow/manifests) which contains _Kustomizations_ for the various components of Kubeflow.

## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_helm"></a> [helm](#requirement\_helm) | ~> 2.12.1 |
| <a name="requirement_kubernetes"></a> [kubernetes](#requirement\_kubernetes) | ~> 2.25.2 |
| <a name="requirement_kustomization"></a> [kustomization](#requirement\_kustomization) | ~> 0.9.5 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_helm"></a> [helm](#provider\_helm) | 2.12.1 |
| <a name="provider_kubernetes"></a> [kubernetes](#provider\_kubernetes) | 2.25.2 |
| <a name="provider_kustomization"></a> [kustomization](#provider\_kustomization) | 0.9.5 |

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_admission_webhook"></a> [admission\_webhook](#module\_admission\_webhook) | ./modules/kust | n/a |
| <a name="module_central_dashboard"></a> [central\_dashboard](#module\_central\_dashboard) | ./modules/kust | n/a |
| <a name="module_cert_manager"></a> [cert\_manager](#module\_cert\_manager) | ./modules/kust | n/a |
| <a name="module_cluster_local_gateway"></a> [cluster\_local\_gateway](#module\_cluster\_local\_gateway) | ./modules/kust | n/a |
| <a name="module_dex"></a> [dex](#module\_dex) | ./modules/kust | n/a |
| <a name="module_istio_crds"></a> [istio\_crds](#module\_istio\_crds) | ./modules/kust | n/a |
| <a name="module_istio_install"></a> [istio\_install](#module\_istio\_install) | ./modules/kust | n/a |
| <a name="module_istio_namespace"></a> [istio\_namespace](#module\_istio\_namespace) | ./modules/kust | n/a |
| <a name="module_jupyter_web_app"></a> [jupyter\_web\_app](#module\_jupyter\_web\_app) | ./modules/kust | n/a |
| <a name="module_knative_serving"></a> [knative\_serving](#module\_knative\_serving) | ./modules/kust | n/a |
| <a name="module_kserve"></a> [kserve](#module\_kserve) | ./modules/kust | n/a |
| <a name="module_kubeflow_issuer"></a> [kubeflow\_issuer](#module\_kubeflow\_issuer) | ./modules/kust | n/a |
| <a name="module_kubeflow_istio_resources"></a> [kubeflow\_istio\_resources](#module\_kubeflow\_istio\_resources) | ./modules/kust | n/a |
| <a name="module_kubeflow_namespace"></a> [kubeflow\_namespace](#module\_kubeflow\_namespace) | ./modules/kust | n/a |
| <a name="module_kubeflow_pipelines"></a> [kubeflow\_pipelines](#module\_kubeflow\_pipelines) | ./modules/kust | n/a |
| <a name="module_kubeflow_profile"></a> [kubeflow\_profile](#module\_kubeflow\_profile) | ./modules/kust | n/a |
| <a name="module_kubeflow_ray_rbac"></a> [kubeflow\_ray\_rbac](#module\_kubeflow\_ray\_rbac) | ./modules/kust | n/a |
| <a name="module_kubeflow_roles"></a> [kubeflow\_roles](#module\_kubeflow\_roles) | ./modules/kust | n/a |
| <a name="module_mlflow_istio"></a> [mlflow\_istio](#module\_mlflow\_istio) | ./modules/kust | n/a |
| <a name="module_models_web_app"></a> [models\_web\_app](#module\_models\_web\_app) | ./modules/kust | n/a |
| <a name="module_notebook_controller"></a> [notebook\_controller](#module\_notebook\_controller) | ./modules/kust | n/a |
| <a name="module_oidc_authservice"></a> [oidc\_authservice](#module\_oidc\_authservice) | ./modules/kust | n/a |
| <a name="module_profiles_kfam"></a> [profiles\_kfam](#module\_profiles\_kfam) | ./modules/kust | n/a |
| <a name="module_pvc_viewer_controller"></a> [pvc\_viewer\_controller](#module\_pvc\_viewer\_controller) | ./modules/kust | n/a |
| <a name="module_tensorboard_web_app"></a> [tensorboard\_web\_app](#module\_tensorboard\_web\_app) | ./modules/kust | n/a |
| <a name="module_volumes_web_app"></a> [volumes\_web\_app](#module\_volumes\_web\_app) | ./modules/kust | n/a |

## Resources

| Name | Type |
|------|------|
| [helm_release.external_secrets](https://registry.terraform.io/providers/hashicorp/helm/latest/docs/resources/release) | resource |
| [helm_release.gatekeeper](https://registry.terraform.io/providers/hashicorp/helm/latest/docs/resources/release) | resource |
| [helm_release.gpu_operator](https://registry.terraform.io/providers/hashicorp/helm/latest/docs/resources/release) | resource |
| [helm_release.kuberay_operator](https://registry.terraform.io/providers/hashicorp/helm/latest/docs/resources/release) | resource |
| [helm_release.mlflow](https://registry.terraform.io/providers/hashicorp/helm/latest/docs/resources/release) | resource |
| [kubernetes_namespace.tkf_system](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/namespace) | resource |
| [kustomization_build.admission_webhook](https://registry.terraform.io/providers/kbst/kustomization/latest/docs/data-sources/build) | data source |
| [kustomization_build.central_dashboard](https://registry.terraform.io/providers/kbst/kustomization/latest/docs/data-sources/build) | data source |
| [kustomization_build.cert_manager](https://registry.terraform.io/providers/kbst/kustomization/latest/docs/data-sources/build) | data source |
| [kustomization_build.cluster_local_gateway](https://registry.terraform.io/providers/kbst/kustomization/latest/docs/data-sources/build) | data source |
| [kustomization_build.istio_crds](https://registry.terraform.io/providers/kbst/kustomization/latest/docs/data-sources/build) | data source |
| [kustomization_build.istio_namespace](https://registry.terraform.io/providers/kbst/kustomization/latest/docs/data-sources/build) | data source |
| [kustomization_build.jupyter_web_app](https://registry.terraform.io/providers/kbst/kustomization/latest/docs/data-sources/build) | data source |
| [kustomization_build.kserve](https://registry.terraform.io/providers/kbst/kustomization/latest/docs/data-sources/build) | data source |
| [kustomization_build.kubeflow_issuer](https://registry.terraform.io/providers/kbst/kustomization/latest/docs/data-sources/build) | data source |
| [kustomization_build.kubeflow_namespace](https://registry.terraform.io/providers/kbst/kustomization/latest/docs/data-sources/build) | data source |
| [kustomization_build.kubeflow_pipelines](https://registry.terraform.io/providers/kbst/kustomization/latest/docs/data-sources/build) | data source |
| [kustomization_build.kubeflow_ray_rbac](https://registry.terraform.io/providers/kbst/kustomization/latest/docs/data-sources/build) | data source |
| [kustomization_build.kubeflow_roles](https://registry.terraform.io/providers/kbst/kustomization/latest/docs/data-sources/build) | data source |
| [kustomization_build.mlflow_istio](https://registry.terraform.io/providers/kbst/kustomization/latest/docs/data-sources/build) | data source |
| [kustomization_build.models_web_app](https://registry.terraform.io/providers/kbst/kustomization/latest/docs/data-sources/build) | data source |
| [kustomization_build.notebook_controller](https://registry.terraform.io/providers/kbst/kustomization/latest/docs/data-sources/build) | data source |
| [kustomization_build.profiles_kfam](https://registry.terraform.io/providers/kbst/kustomization/latest/docs/data-sources/build) | data source |
| [kustomization_build.pvc_viewer_controller](https://registry.terraform.io/providers/kbst/kustomization/latest/docs/data-sources/build) | data source |
| [kustomization_build.tensorboard_web_app](https://registry.terraform.io/providers/kbst/kustomization/latest/docs/data-sources/build) | data source |
| [kustomization_build.volumes_web_app](https://registry.terraform.io/providers/kbst/kustomization/latest/docs/data-sources/build) | data source |
| [kustomization_overlay.dex](https://registry.terraform.io/providers/kbst/kustomization/latest/docs/data-sources/overlay) | data source |
| [kustomization_overlay.istio_install](https://registry.terraform.io/providers/kbst/kustomization/latest/docs/data-sources/overlay) | data source |
| [kustomization_overlay.knative_serving](https://registry.terraform.io/providers/kbst/kustomization/latest/docs/data-sources/overlay) | data source |
| [kustomization_overlay.kubeflow_istio_resources](https://registry.terraform.io/providers/kbst/kustomization/latest/docs/data-sources/overlay) | data source |
| [kustomization_overlay.kubeflow_profile](https://registry.terraform.io/providers/kbst/kustomization/latest/docs/data-sources/overlay) | data source |
| [kustomization_overlay.oidc_authservice](https://registry.terraform.io/providers/kbst/kustomization/latest/docs/data-sources/overlay) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_completed"></a> [completed](#input\_completed) | n/a | `string` | `false` | no |
| <a name="input_enable_cert_manager"></a> [enable\_cert\_manager](#input\_enable\_cert\_manager) | n/a | `bool` | `true` | no |
| <a name="input_enable_external_dns"></a> [enable\_external\_dns](#input\_enable\_external\_dns) | n/a | `bool` | `true` | no |
| <a name="input_enable_external_secrets"></a> [enable\_external\_secrets](#input\_enable\_external\_secrets) | n/a | `bool` | `false` | no |
| <a name="input_enable_gatekeeper"></a> [enable\_gatekeeper](#input\_enable\_gatekeeper) | n/a | `bool` | `false` | no |
| <a name="input_enable_gpu_operator"></a> [enable\_gpu\_operator](#input\_enable\_gpu\_operator) | n/a | `bool` | `false` | no |
| <a name="input_enable_istio_base"></a> [enable\_istio\_base](#input\_enable\_istio\_base) | n/a | `bool` | `true` | no |
| <a name="input_enable_istio_resources"></a> [enable\_istio\_resources](#input\_enable\_istio\_resources) | Enable istio resources for clusters with pre-existing istio | `bool` | `true` | no |
| <a name="input_enable_istiod"></a> [enable\_istiod](#input\_enable\_istiod) | n/a | `bool` | `true` | no |
| <a name="input_enable_kserve"></a> [enable\_kserve](#input\_enable\_kserve) | n/a | `bool` | `false` | no |
| <a name="input_enable_kubeflow_pipelines"></a> [enable\_kubeflow\_pipelines](#input\_enable\_kubeflow\_pipelines) | n/a | `bool` | `false` | no |
| <a name="input_enable_kuberay"></a> [enable\_kuberay](#input\_enable\_kuberay) | n/a | `bool` | `false` | no |
| <a name="input_enable_mlflow"></a> [enable\_mlflow](#input\_enable\_mlflow) | n/a | `bool` | `false` | no |
| <a name="input_enable_tensorboard"></a> [enable\_tensorboard](#input\_enable\_tensorboard) | n/a | `bool` | `false` | no |
| <a name="input_hostname"></a> [hostname](#input\_hostname) | n/a | `string` | `"localhost"` | no |
| <a name="input_port"></a> [port](#input\_port) | n/a | `string` | `"8080"` | no |
| <a name="input_protocol"></a> [protocol](#input\_protocol) | n/a | `string` | `"http://"` | no |

## Outputs

No outputs.
