<div align="center">
  <h1>Kubeflow Terraform Modules</h1>

  <p>Terraform module which creates a Kubeflow instance in a Kubernetes cluster</p>

  <a target="_blank" href="https://registry.terraform.io/modules/treebeardtech/kubeflow/kubernetes/0.0.3" style="background:none">
    <img alt="dagster logo" src="docs/tkf.png" width="400" height="100%">
  </a>

  <br />

  <a target="_blank" href="https://discord.gg/QFjCpMjqRY">
    <img src="https://img.shields.io/badge/chat-discord-blue?logo=discord&logoColor=white" />
  </a>

</div>

> [!Note]  
> This project is currently in beta, we recommend forking/cloning it and using from source. Bug reports and feature requests are welcome.

## About this project

This project simplifies the task of managing a Kubeflow instance with Terraform.

Kubeflow provides a cloud-native AI platform which can be used to deploy applications in
scientific computing, traditional machine learning, and generative AI.

This module is primarily focussed on the Jupyter notebook environment initially such that
* Developers can deploy and access notebook instances
* Notebook instances can use GPUs necessary for deep learning
* This can be done across different cloud providers (ranging from individual VMs to managed services like Amazon's EKS)

## Getting Started

We recommend trying out this module in a development environment first.

To do so, follow the [k3s tutorial](examples/k3s).

### Video guide

[https://www.youtube.com/watch?v=dQw4w9WgXcQ](https://www.youtube.com/watch?v=dQw4w9WgXcQ)

## Guides

In order to integrate Kubeflow with your production systems there are some changes you 
may want to make:

### Add Kubeflow to your Terraform module

```hcl
# resource or data for your k8s cluster
...

# Initialize provider

provider "helm" {
  ...
}

# Call Kubeflow module
module "treebeardkf" {
  source         = "../.."
}
```

### Install in an existing cluster

You can incrementally add Kubeflow to your K8s cluster by installing the terraform module.

Some considerations:
1. If you are calling this Terraform module from your own module, ensure you pass in resources to the `depends_on` field so that Kubeflow installs after they finish setup.
2. If you already have Istio and Cert Manager installed, you will need to ensure Kubeflow works with them. See [examples/k3s-existing-istio](examples/k3s-existing-istio) for a configuration that we have tested like this.

### Set a new password

The `user_password` variable allows you to set a non-default password. This is
essential for deploying Kubeflow.

### Make Kubeflow available securely on a network using HTTPS

Follow the [eks-https-loadbalancer](examples/eks-https-loadbalancer) example to see how you can setup an https loadbalancer for you Kubeflow deployment

### Host your Kubeflow on a domain name using DNS

This is best done by using the external DNS operator.

If you are new to external DNS, follow the [docs](https://kubernetes-sigs.github.io/external-dns/v0.14.0/) for setting up a deployment, then
use [this guide](https://kubernetes-sigs.github.io/external-dns/v0.14.0/tutorials/istio/) to connect external DNS to the istio gateway *service* for your Kubeflow deployment.

The [eks-https-loadbalancer](examples/eks-https-loadbalancer) example also shows this.

### Create Profiles for your users

Profiles are a Kubeflow abstraction that lets you securely isolate users from each other. See the [Kubeflow docs on profiles](https://www.kubeflow.org/docs/components/central-dash/profiles/)

### Teardown

1. Manually remove any manually created Kubeflow resources, e.g. Notebook Servers and Volumes
2. Remove the terraform module, e.g. with `terraform destroy` if you have installed directly from CLI
3. Clean up remaining resources, e.g. Istio leaves behind some secrets that can prevent successful re-installation. 

## Troubleshooting

## Reconfiguration challenges

Moving the deployment between different states of configuration can be challenging
due to the dependencies between components in the cluster.

If you have made a change to a dependency such as istio, or an auth component such as dex, it can be a good idea to re-create pods such that they re-initialise. This can be done by scaling to 0 then back up again, or simply deleting a pod managed by a deployment.

## Architecture

This module is built on top of the official [Kubeflow Manifests repo](https://github.com/kubeflow/manifests) which contains _Kustomizations_ for the various components of Kubeflow.

## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.3 |
| <a name="requirement_helm"></a> [helm](#requirement\_helm) | >= 2.12 |
| <a name="requirement_null"></a> [null](#requirement\_null) | >= 3.0 |
| <a name="requirement_time"></a> [time](#requirement\_time) | >= 0.9 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_helm"></a> [helm](#provider\_helm) | >= 2.12 |
| <a name="provider_null"></a> [null](#provider\_null) | >= 3.0 |
| <a name="provider_time"></a> [time](#provider\_time) | >= 0.9 |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [helm_release.admission_webhook](https://registry.terraform.io/providers/hashicorp/helm/latest/docs/resources/release) | resource |
| [helm_release.argo_cd](https://registry.terraform.io/providers/hashicorp/helm/latest/docs/resources/release) | resource |
| [helm_release.central_dashboard](https://registry.terraform.io/providers/hashicorp/helm/latest/docs/resources/release) | resource |
| [helm_release.cert_manager](https://registry.terraform.io/providers/hashicorp/helm/latest/docs/resources/release) | resource |
| [helm_release.cluster_issuer](https://registry.terraform.io/providers/hashicorp/helm/latest/docs/resources/release) | resource |
| [helm_release.dex](https://registry.terraform.io/providers/hashicorp/helm/latest/docs/resources/release) | resource |
| [helm_release.istio_base](https://registry.terraform.io/providers/hashicorp/helm/latest/docs/resources/release) | resource |
| [helm_release.istio_ingressgateway](https://registry.terraform.io/providers/hashicorp/helm/latest/docs/resources/release) | resource |
| [helm_release.istiod](https://registry.terraform.io/providers/hashicorp/helm/latest/docs/resources/release) | resource |
| [helm_release.jupyter_web_app](https://registry.terraform.io/providers/hashicorp/helm/latest/docs/resources/release) | resource |
| [helm_release.kubeflow_istio_resources](https://registry.terraform.io/providers/hashicorp/helm/latest/docs/resources/release) | resource |
| [helm_release.kubeflow_namespace](https://registry.terraform.io/providers/hashicorp/helm/latest/docs/resources/release) | resource |
| [helm_release.kubeflow_roles](https://registry.terraform.io/providers/hashicorp/helm/latest/docs/resources/release) | resource |
| [helm_release.notebook_controller](https://registry.terraform.io/providers/hashicorp/helm/latest/docs/resources/release) | resource |
| [helm_release.oidc_authservice](https://registry.terraform.io/providers/hashicorp/helm/latest/docs/resources/release) | resource |
| [helm_release.profile](https://registry.terraform.io/providers/hashicorp/helm/latest/docs/resources/release) | resource |
| [helm_release.profiles_kfam](https://registry.terraform.io/providers/hashicorp/helm/latest/docs/resources/release) | resource |
| [helm_release.pvc_viewer_controller](https://registry.terraform.io/providers/hashicorp/helm/latest/docs/resources/release) | resource |
| [helm_release.volumes_web_app](https://registry.terraform.io/providers/hashicorp/helm/latest/docs/resources/release) | resource |
| [null_resource.kf_apps_end](https://registry.terraform.io/providers/hashicorp/null/latest/docs/resources/resource) | resource |
| [null_resource.kf_apps_start](https://registry.terraform.io/providers/hashicorp/null/latest/docs/resources/resource) | resource |
| [null_resource.kf_core_end](https://registry.terraform.io/providers/hashicorp/null/latest/docs/resources/resource) | resource |
| [null_resource.kf_core_start](https://registry.terraform.io/providers/hashicorp/null/latest/docs/resources/resource) | resource |
| [null_resource.kf_dependencies_end](https://registry.terraform.io/providers/hashicorp/null/latest/docs/resources/resource) | resource |
| [null_resource.kf_dependencies_start](https://registry.terraform.io/providers/hashicorp/null/latest/docs/resources/resource) | resource |
| [time_sleep.wait](https://registry.terraform.io/providers/hashicorp/time/latest/docs/resources/sleep) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_enable_argocd"></a> [enable\_argocd](#input\_enable\_argocd) | n/a | `bool` | `true` | no |
| <a name="input_enable_cert_manager"></a> [enable\_cert\_manager](#input\_enable\_cert\_manager) | n/a | `bool` | `true` | no |
| <a name="input_enable_example_profile"></a> [enable\_example\_profile](#input\_enable\_example\_profile) | n/a | `bool` | `true` | no |
| <a name="input_enable_https"></a> [enable\_https](#input\_enable\_https) | n/a | `bool` | `false` | no |
| <a name="input_enable_istio_base"></a> [enable\_istio\_base](#input\_enable\_istio\_base) | n/a | `bool` | `true` | no |
| <a name="input_enable_istio_resources"></a> [enable\_istio\_resources](#input\_enable\_istio\_resources) | Enable istio resources for clusters with pre-existing istio | `bool` | `true` | no |
| <a name="input_enable_istiod"></a> [enable\_istiod](#input\_enable\_istiod) | n/a | `bool` | `true` | no |
| <a name="input_hostname"></a> [hostname](#input\_hostname) | n/a | `string` | `"*"` | no |
| <a name="input_issuer_name"></a> [issuer\_name](#input\_issuer\_name) | Required if enable\_https is true | `string` | `"null"` | no |
| <a name="input_user_password"></a> [user\_password](#input\_user\_password) | The password for the user | `string` | `"12341234"` | no |

## Outputs

No outputs.
