#!/usr/bin/env bash
set -e -u -o pipefail -x

export KUBECONFIG=$(pwd)/scratch/.kube/config
rm $KUBECONFIG || true
make k3d-delete
make k3d-create
sleep 10
cd examples/k3s
terraform init -reconfigure
terraform apply -var kubeconfig=$KUBECONFIG -auto-approve