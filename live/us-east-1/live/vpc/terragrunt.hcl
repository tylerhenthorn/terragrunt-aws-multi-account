include "root" {
  path = find_in_parent_folders("root.hcl")
}

include "envcommon" {
  path   = "${dirname(find_in_parent_folders("root.hcl"))}/common/vpc.hcl"
  expose = true
}

terraform {
  source = "${include.envcommon.locals.base_source_url}?version=5.18.1"
}