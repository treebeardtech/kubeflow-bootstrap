#!/usr/bin/env bash
set -e -u -o pipefail -x

make k3d-delete
make k3d-create
cd examples/k3s
terraform init -reconfigure
terraform apply -var kubeconfig=/home/vscode/.kube/config -auto-approve