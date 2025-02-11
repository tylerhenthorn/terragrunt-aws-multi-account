locals {
  # Walk the directory tree up from the unit and collect the configuration
  account_vars     = read_terragrunt_config(find_in_parent_folders("account.hcl"))
  region_vars      = read_terragrunt_config(find_in_parent_folders("region.hcl"))
  environment_vars = read_terragrunt_config(find_in_parent_folders("environment.hcl"))

  account_name = local.account_vars.locals.account_name
  account_id   = local.account_vars.locals.aws_account_id
  iam_role     = local.account_vars.locals.iam_role
  region       = local.region_vars.locals.region
  environment  = local.environment_vars.locals.environment
}

# Tell Terragrunt to assume the IAM role
iam_role = local.iam_role

# Provider configuration
generate "provider" {
  path      = "provider.tf"
  if_exists = "overwrite_terragrunt"
  contents  = <<EOF
provider "aws" {
  region = "${local.region}"

  allowed_account_ids = ["${local.account_id}"]
}
EOF
}

# Backend configuration
generate "backend" {
  path      = "backend.tf"
  if_exists = "overwrite_terragrunt"
  contents  = <<EOF
terraform {
  backend "s3" {
    bucket         = "tylerhenthorn-${local.account_name}-terraform"
    key            = "${path_relative_to_include()}/terraform.tfstate"
    region         = "${local.region}"
    encrypt        = true
    dynamodb_table = "terraform-state-lock"
  }
}
EOF
}

inputs = merge(
  local.account_vars.locals,
  local.region_vars.locals,
  local.environment_vars.locals,
)