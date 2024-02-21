# Run on K3s

## Pre-reqs:

* 2 cpus and 16G memory
* A K3s cluster
  * Run the following to prevent a common issue with file handlers
      ```sh
      sudo sysctl fs.inotify.max_user_instances=1280
      sudo sysctl fs.inotify.max_user_watches=655360;sudo sysctl fs.inotify.max_user_instances=1280
    ```
* terraform apply
* port forward to istio-ingressgateway