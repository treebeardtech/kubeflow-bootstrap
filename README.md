<div align="center">
  <h1>Treebeard Kubeflow</h1>
  <p><b>Run Jupyter in Kubernetes 🪐</b></p>

  <img src="https://raw.githubusercontent.com/treebeardtech/terraform-helm-kubeflow/3936f78f1ab1931737037d7744ef0e686fb94d30/docs/tkf.png" width="400" height="100%">

  <br />

  <a target="_blank" href="https://registry.terraform.io/modules/treebeardtech/kubeflow/helm/latest">
    <img src="https://img.shields.io/badge/terraform-module-blue?logo=terraform" />
  </a>
  <a target="_blank" href="https://discord.gg/QFjCpMjqRY">
    <img src="https://img.shields.io/badge/chat-discord-blue?logo=discord&logoColor=white" />
  </a>

  <a target="_blank" href="https://artifacthub.io/packages/search?repo=treebeard-kubeflow">
    <img src="https://img.shields.io/endpoint?url=https://artifacthub.io/badge/repository/treebeard-kubeflow" />
  </a>

</div>

## About this project

This project simplifies MLOps in Kubernetes by providing a Terraform module which creates a Kubeflow instance.

Kubeflow provides a cloud-native AI platform which can be used to deploy applications in
scientific computing, traditional machine learning, and generative AI.

This module is primarily focussed on the Jupyter notebook environment initially such that
* Developers can deploy and access notebook instances
* Notebook instances can use GPUs necessary for deep learning
* This can be done across different cloud providers (ranging from individual VMs to managed services like Amazon's EKS)

## Getting Started

We recommend trying out this module in a development environment first.

To do so, follow the [k3s tutorial](examples/k3s).

### 📺 [Youtube tutorial](https://www.youtube.com/watch?v=DtLLJqW6aG8)

<a target="_blank" href="https://www.youtube.com/watch?v=DtLLJqW6aG8" style="background:none">
  <img src="https://i3.ytimg.com/vi/91Kmsg7g5D8/maxresdefault.jpg" width="600" height="100%">
</a>

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

It's critical to not use the default password for internet-facing deployments.

See the See [examples/k3s-existing-istio](examples/k3s-existing-istio) for deployment with a non-default dex password (passed in via terraform CLI)

Note that dex will only pick up new config at start -- you may have to restart the dex pod manually for a password change to take effect.

### Make Kubeflow available securely on a network using HTTPS

Follow the [eks-https-loadbalancer](examples/eks-https-loadbalancer) example to see how you can setup an https loadbalancer for you Kubeflow deployment

### Host your Kubeflow on a domain name using DNS

This is best done by using the external DNS operator.

If you are new to external DNS, follow the [docs](https://kubernetes-sigs.github.io/external-dns/v0.14.0/) for setting up a deployment, then
use [this guide](https://kubernetes-sigs.github.io/external-dns/v0.14.0/tutorials/istio/) to connect external DNS to the istio gateway *service* for your Kubeflow deployment.

The [eks-https-loadbalancer](examples/eks-https-loadbalancer) example also shows this.

### Create Profiles for your users

Profiles are a Kubeflow abstraction that lets you securely isolate users from each other. See the [Kubeflow docs on profiles](https://www.kubeflow.org/docs/components/central-dash/profiles/)

### Manage your instance with GitOps

Lots of the config used to define your Kubeflow instance has has no dependency on
Terraform resource outputs such as role ARNs.

These may best be stored in a git repo and referenced using Argo's [multiple sources feature](https://argo-cd.readthedocs.io/en/stable/user-guide/multiple_sources/)

Using this approach you can invoke this terraform module (or the underlying bootstrap helm chart) with config like the following that combines injected values with values from a git repo:

```yaml
sources:
# - repoURL: 'https://github.com/treebeardtech/gitops-bridge-argocd-control-plane-template'
#   targetRevision: dev
#   ref: values
- repoURL: ghcr.io/treebeardtech
  targetRevision: 0.1-2024-03-08-T12-25-15
  chart: treebeard-kubeflow
  helm:
    ignoreMissingValueFiles: true
    # valueFiles:
    # - $values/some-dir/my-values-file.yaml # use your own gitops values file
    values: |
      # pass in terraform outputs from cloud resources
      # e.g. ARNs, node labels, etc.
```

### Teardown

1. Manually remove any manually created Kubeflow resources, e.g. Notebook Servers and Volumes
2. Remove the terraform module, e.g. with `terraform destroy` if you have installed directly from CLI
3. Clean up remaining resources, e.g. Istio leaves behind some secrets that can prevent successful re-installation. You may also want to clear out CRDs, persistent volumes and namespaces

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

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [helm_release.argo_bootstrap](https://registry.terraform.io/providers/hashicorp/helm/latest/docs/resources/release) | resource |
| [helm_release.argo_cd](https://registry.terraform.io/providers/hashicorp/helm/latest/docs/resources/release) | resource |
| [null_resource.start](https://registry.terraform.io/providers/hashicorp/null/latest/docs/resources/resource) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_enable_argocd"></a> [enable\_argocd](#input\_enable\_argocd) | n/a | `bool` | `true` | no |
| <a name="input_kubeflow_set"></a> [kubeflow\_set](#input\_kubeflow\_set) | Value block with custom STRING values to be merged with the values yaml. | <pre>list(object({<br>    name  = string<br>    value = string<br>  }))</pre> | `null` | no |
| <a name="input_kubeflow_set_sensitive"></a> [kubeflow\_set\_sensitive](#input\_kubeflow\_set\_sensitive) | Value block with custom sensitive values to be merged with the values yaml that won't be exposed in the plan's diff. | <pre>list(object({<br>    path  = string<br>    value = string<br>  }))</pre> | `null` | no |
| <a name="input_kubeflow_values"></a> [kubeflow\_values](#input\_kubeflow\_values) | Extra values | `list(string)` | `[]` | no |

## Outputs

No outputs.
