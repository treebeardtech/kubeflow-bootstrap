# Run on K3d

This example will help you try Kubeflow Helm in your development environment.

## Pre-reqs:

> [!Note]  
> The simplest environment setup may be to fork this repo and open it using github codespaces.


* 2 cpus and 8G memory in your dev environment (local or via SSH)
* _If you are running on a laptop/vm with docker_: Higher limits for file handlers (this gets reset on system restart)
    
    ```sh
    # Note that these must be run outside of a container
    sudo sysctl fs.inotify.max_user_instances=1280
    sudo sysctl fs.inotify.max_user_watches=655360
    ```

* A working docker daemon (can be docker in docker if using devcontainers)
    verify with:
    ```sh
    docker run -it --rm hello-world
    ```

* some CLI tools on your PATH
  * A recent terraform version e.g. v1.6.2: `terraform -version`
  * A recent helm e.g. v3.14.1: `helm version`
  * A recent k3d version e.g. v5.6.0 `k3d --version`

### Optional Pre-reqs

Some tools can make this process easier:
* K9s
* VSCode and extensions:
  * Docker
  * Resource Monitor
  * Kubernetes
  * Remote containers/Remote SSH

## Installation

### 1. Setup Kubernetes

Clone this repo (if not in codespaces) and use the makefile to setup kubernetes:

```sh
git clone https://github.com/treebeardtech/terraform-helm-kubeflow.git
cd terraform-helm-kubeflow
export KUBECONFIG=~/.kube/demo.yaml
rm $KUBECONFIG # remove if exists from previous attempts
make k3d-create
```

Once complete, verify the API server has started:

```sh
kubectl get nodes
```

### 2. Install Kubeflow Helm

Initialise the terraform environment

```sh
cd examples/k3s
terraform init
```

Create a plan and apply the infra install

```sh
terraform apply -var kubeconfig=$KUBECONFIG
```

### 3. Verify the installation

Watch k9s pods until all of them are in a ready state.

You can also check argocd with:

```
kubectl port-forward  --namespace "argocd" svc/argo-cd-argocd-server 8081:80
```

then go the localhost:8081 and enter username 'admin', password (decoded `argocd/argocd-initial-admin-secret`)

Once all is finished you can port forward into the ingress gateway:

```sh
kubectl port-forward  --namespace "istio-system" svc/istio-ingressgateway 8080:http2
```

then go to http://localhost:8080/ to see the login page

### 4. Uninstall Kubeflow

```sh
terraform destroy -var kubeconfig=$KUBECONFIG
```

## Usage

Login with user: `user@example.com`, pass: `12341234`

Try creating a Jupyter Notebook server with 0.1 CPU via the web UI.

## Next steps?

This shows you how you can start developing Kubeflow Helm into your infrastructure.

Customisation and deployment for your team is another matter and will be discussed in subsequent tutorials.

## Cleanup

```sh
k3d cluster delete demo
```

**🚨 delete your codespace if you created one, they cost money based on how long they are running**

## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_helm"></a> [helm](#requirement\_helm) | ~> 2.12.1 |

## Providers

No providers.

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_treebeardkf"></a> [treebeardkf](#module\_treebeardkf) | ../.. | n/a |

## Resources

No resources.

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_kubeconfig"></a> [kubeconfig](#input\_kubeconfig) | n/a | `string` | n/a | yes |

## Outputs

No outputs.
