# Run on K3d

This example will help you try Treebeard Kubeflow in your development environment.

## Pre-reqs:

* 2 cpus and 16G memory in your dev environment (local or via SSH)
* Higher limits for file handlers (this gets reset on system restart)
    ```sh
    sudo sysctl fs.inotify.max_user_instances=1280
    sudo sysctl fs.inotify.max_user_watches=655360
    ```

* A working docker daemon (can be docker in docker if using devcontainers)
    verify with:
    ```sh
    docker run -it --rm hello-world
    ```

* A recent terraform version e.g. v1.6.2
* A recent helm e.g. v3.14.1
* A recent k3d version e.g. v5.6.0

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

First, let's setup a single node k3d cluster:

```sh
export KUBECONFIG=~/.kube/demo.yaml
k3d cluster create demo
```

Once complete, verify the API server has started:

```sh
kubectl get nodes
```

### 2. Install Treebeard Kubeflow

Initialise the terraform environment

```sh
terraform init
```

Create a plan and apply the infra install

```sh
terraform apply -var kubeconfig=$KUBECONFIG
```

### 3. Verify the installation

Once terraform has finished, connect to the central dashboard and login as the default user.

```sh
kubectl port-forward  --namespace "istio-system" svc/istio-ingressgateway 8080:http2
```

then go to http://localhost:8080/ to see the login page


## Usage

Login with user: `user@example.com`, pass: `12341234`

Try creating a Jupyter Notebook server with 0.1 CPU via the web UI.

## Next steps?

This shows you how you can start developing Treebeard Kubeflow into your infrastructure.

Customisation and deployment for your team is another matter and will be discussed in subsequent tutorials.