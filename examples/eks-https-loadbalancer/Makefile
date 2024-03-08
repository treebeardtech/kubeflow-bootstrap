clean-state:
	mv terraform.tfstate $(shell mktemp)

apply-without-kf:
	terraform apply -var-file=./.tfvars -var enable_treebeardkf=false

apply-with-kf:
	terraform apply -var-file=./.tfvars -var enable_treebeardkf=true

get-kubeconfig:
	aws eks update-kubeconfig --name cluster --region us-east-1