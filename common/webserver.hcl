locals {
  # Collect the configuration
  environment_vars = read_terragrunt_config(find_in_parent_folders("environment.hcl"))
  region_vars      = read_terragrunt_config(find_in_parent_folders("region.hcl"))

  environment             = local.environment_vars.locals.environment
  webserver_instance_type = local.environment_vars.locals.webserver_instance_type

  # The location of the webserver module
  source_path = "${dirname(find_in_parent_folders("root.hcl"))}/modules/webserver/"
}

# Read outputs from the VPC module
dependency "vpc" {
  config_path = "${dirname(find_in_parent_folders("environment.hcl"))}/vpc"
}

# Feed inputs into the webserver module
inputs = {
  name          = "webserver-${local.environment}" 
  instance_type = local.webserver_instance_type

  vpc_id = dependency.vpc.outputs.vpc_id

  min_size = 2
  max_size = 2

  server_port = 8080
  alb_port    = 80
}
