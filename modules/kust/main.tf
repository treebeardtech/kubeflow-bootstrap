terraform {
  required_providers {
    kustomization = {
      source  = "kbst/kustomization"
      version = "0.9.5"
    }
  }
}

variable "build" {
  type = object({
    ids       = list(string)
    ids_prio  = list(list(string))
    manifests = map(string)
  })

  description = "description"
}


resource "kustomization_resource" "p0" {
  for_each = toset(var.build.ids_prio[0])

  manifest = (
    contains(["_/Secret"], regex("(?P<group_kind>.*/.*)/.*/.*", each.value)["group_kind"])
    ? sensitive(var.build.manifests[each.value])
    : var.build.manifests[each.value]
  )
}

# then loop through resources in ids_prio[1]
# and set an explicit depends_on on kustomization_resource.p0
# wait 2 minutes for any deployment or daemonset to become ready
resource "kustomization_resource" "p1" {
  for_each = toset(var.build.ids_prio[1])

  manifest = (
    contains(["_/Secret"], regex("(?P<group_kind>.*/.*)/.*/.*", each.value)["group_kind"])
    ? sensitive(var.build.manifests[each.value])
    : var.build.manifests[each.value]
  )
  wait = true
  timeouts {
    create = "5m"
    update = "2m"
  }

  depends_on = [kustomization_resource.p0]
}

# finally, loop through resources in ids_prio[2]
# and set an explicit depends_on on kustomization_resource.p1
resource "kustomization_resource" "p2" {
  for_each = toset(var.build.ids_prio[2])

  manifest = (
    contains(["_/Secret"], regex("(?P<group_kind>.*/.*)/.*/.*", each.value)["group_kind"])
    ? sensitive(var.build.manifests[each.value])
    : var.build.manifests[each.value]
  )

  depends_on = [kustomization_resource.p1]
}