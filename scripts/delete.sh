#!/bin/bash

# Delete Volumes Web App
kustomize build apps/volumes-web-app/upstream/overlays/istio | kubectl delete -f -

# Delete Profiles + KFAM
kustomize build apps/profiles/upstream/overlays/kubeflow | kubectl delete -f -

# Delete PVC Viewer Controller
kustomize build apps/pvcviewer-controller/upstream/default | kubectl delete -f -

# Delete Jupyter Web App
kustomize build apps/jupyter/jupyter-web-app/upstream/overlays/istio | kubectl delete -f -

# Delete Notebook Controller
kustomize build apps/jupyter/notebook-controller/upstream/overlays/kubeflow | kubectl delete -f -

# Delete Admission Webhook
kustomize build apps/admission-webhook/upstream/overlays/cert-manager | kubectl delete -f -

# Delete Central Dashboard
kustomize build apps/centraldashboard/upstream/overlays/kserve | kubectl delete -f -

# Delete Katib
kustomize build apps/katib/upstream/installs/katib-with-kubeflow | kubectl delete -f -

# Delete KServe and Models web app
kustomize build contrib/kserve/models-web-app/overlays/kubeflow | kubectl delete -f -
kustomize build contrib/kserve/kserve | kubectl delete -f -

# Delete Kubeflow Pipelines and related resources
kustomize build apps/pipeline/upstream/env/platform-agnostic-multi-user-pns | kubectl delete -f -
kustomize build apps/pipeline/upstream/env/cert-manager/platform-agnostic-multi-user | kubectl delete -f -

# Delete Kubeflow Istio Resources
kustomize build common/istio-1-17/kubeflow-istio-resources/base | kubectl delete -f -

# Delete Kubeflow Roles
kustomize build common/kubeflow-roles/base | kubectl delete -f -

# Delete Kubeflow Namespace
kustomize build common/kubeflow-namespace/base | kubectl delete -f -

# Delete Knative components
kustomize build common/knative/knative-eventing/base | kubectl delete -f -
kustomize build common/istio-1-17/cluster-local-gateway/base | kubectl delete -f -
kustomize build common/knative/knative-serving/overlays/gateways | kubectl delete -f -

# Delete Dex
kustomize build common/dex/overlays/istio | kubectl delete -f -

# Delete OIDC AuthService
kustomize build common/oidc-client/oidc-authservice/base | kubectl delete -f -

# Delete Istio
kustomize build common/istio-1-17/istio-install/base | kubectl delete -f -
kustomize build common/istio-1-17/istio-namespace/base | kubectl delete -f -
kustomize build common/istio-1-17/istio-crds/base | kubectl delete -f -

# Delete cert-manager components
kustomize build common/cert-manager/kubeflow-issuer/base | kubectl delete -f -
# kubectl wait --for=delete pod -l 'app in (cert-manager,webhook)' --timeout=180s -n cert-manager
kustomize build common/cert-manager/cert-manager/base | kubectl delete -f -
