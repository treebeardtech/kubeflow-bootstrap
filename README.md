<div align="center">
  <h1>Kubeflow Helm</h1>
  <p><b>🪐 1-click Kubeflow</b></p>

  <img src="https://raw.githubusercontent.com/treebeardtech/terraform-helm-kubeflow/main/docs/tkf.png" width="400" height="100%">

  <br />

  <a target="_blank" href="https://artifacthub.io/packages/helm/treebeard-kubeflow/treebeard-kubeflow">
    <img src="https://img.shields.io/endpoint?url=https://artifacthub.io/badge/repository/kubeflow" />
  </a>
  <a target="_blank" href="https://registry.terraform.io/modules/treebeardtech/kubeflow/helm/latest">
    <img src="https://img.shields.io/badge/terraform-module-blue?logo=terraform" />
  </a>
  <a target="_blank" href="https://discord.gg/QFjCpMjqRY">
    <img src="https://img.shields.io/badge/chat-discord-blue?logo=discord&logoColor=white" />
  </a>

</div>

<br/>

**As both Kubernetes and AI usage grows, how do we keep operations consistent and simple?**

## About this project

This project simplifies MLOps in Kubernetes by providing Kubeflow in Helm and Terraform package formats. This allows scaling Kubeflow usage with the rest of your production systems.

Kubeflow provides a cloud-native AI platform which can be used to deploy applications in
scientific computing, traditional machine learning, and generative AI.

This module is primarily focussed on the Jupyter notebook environment initially such that
* Developers can deploy and access notebook instances
* Notebook instances can use GPUs necessary for deep learning
* This can be done across different cloud providers (ranging from individual VMs to managed services like Amazon's EKS)

## Architecture

This system is built on top of the official [Kubeflow Manifests repo](https://github.com/kubeflow/manifests) which contains _Kustomizations_ for the various components of Kubeflow.

We provide a terraform and helm-based interface for managing Kubeflow via GitOps. Because Kubeflow is a collection of modular components, this project relies on ArgoCD for combining them.

### Design Tenets

1. Integrate with production systems that already use Terraform and Helm
2. Embrace GitOps for Kubernetes resources on the popular ArgoCD project
3. Enable adoption of cloud-native/AI tools beyond the scope of Kubeflow (e.g. Ray, MLFlow)

<img src="https://raw.githubusercontent.com/treebeardtech/terraform-helm-kubeflow/main/docs/arch.png" width="650" height="100%">

### Packages

1. Terraform module: A simple entrypoint for those new to Argo and looking for a 1-click experience
2. kubeflow chart: A high-level helm entrypoint for setting up Kubeflow Argo Apps
3. kubeflow-core chart: A lower-level argo apps chart which can be invoked in the "argo app-of-apps" pattern.

### System Requirements

The default configuration of Kubeflow provided is designed to run on a cluster with 2cpus and 8G memory.

## Getting Started

Note that as all of our examples are implemented in Terraform, we recommend using the Terraform module to start off. The [helm charts](helm) are likely to be a more viable interface as you move into production.

We recommend trying out this module in a development environment first.

To do so, follow the [k3s tutorial](examples/k3s).

### 📺 [Youtube tutorial](https://www.youtube.com/watch?v=DtLLJqW6aG8)

<a target="_blank" href="https://www.youtube.com/watch?v=DtLLJqW6aG8" style="background:none">
  <img src="https://i3.ytimg.com/vi/91Kmsg7g5D8/maxresdefault.jpg" width="600" height="100%">
</a>

## Guides

### Install via helm CLI

```sh
# install argo (necessary for orchestration)
helm repo add argo-cd https://argoproj.github.io/argo-helm
helm install -n argocd --create-namespace argo-cd argo-cd/argo-cd

# install kubeflow
helm install kubeflow -n argocd oci://ghcr.io/treebeardtech/helm/kubeflow --version x.y.z
```

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

See the See [examples/eks-https-loadbalancer](examples/eks-https-loadbalancer) for deployment with a non-default dex password (passed in via terraform CLI)

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

Using this approach you can invoke this terraform module (or the underlying bootstrap helm chart) with config like the following that combines injected values with values from a git repo.

See the [gitops example](examples/k3s-gitops) for details.

### Teardown

1. Manually remove any manually created Kubeflow resources, e.g. Notebook Servers and Volumes
2. Remove the terraform module, e.g. with `terraform destroy` if you have installed directly from CLI
3. Clean up remaining resources, e.g. Istio leaves behind some secrets that can prevent successful re-installation. You may also want to clear out CRDs, persistent volumes and namespaces

## Troubleshooting

### Reconfiguration challenges

Moving the deployment between different states of configuration can be challenging
due to the dependencies between components in the cluster.

If you have made a change to a dependency such as istio, or an auth component such as dex, it can be a good idea to re-create pods such that they re-initialise. This can be done by scaling to 0 then back up again, or simply deleting a pod managed by a deployment.
