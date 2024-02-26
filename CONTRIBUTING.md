# Contributing

Thanks for considering contributing to Kubeflow Terraform Modules. We are open to contributions but please check via GitHub issues that we don't already provide the functionality you are requesting and that we are open to it being contributed.

## Creating a development environment

We recommend an Ubuntu environment running docker with 2 cpus and 16G of memory.

This can be achieved using VSCode and the `.devcontainer` directory in this repo. A cloud VM gives the best performance.

* [devcontainer docs](https://containers.dev/)
* See the `.devcontainer` directory for details on dev dependencies, the main ones are:
  * k3d
  * helm CLI
  * terraform CLI

## Install from source

While developing your change, install the K3s example into a local K3d cluster. Follow [the example](./examples/k3s/README.md) to do this.

## Make a change

You can change terraform files in the project then `terraform apply` to see them in your dev environment.

## Ensure changes work in non K3s environments

This can be validated by following examples other K8s providers such as EKS.
