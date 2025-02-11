locals {
    # Collect the configuration
    environment_vars = read_terragrunt_config(find_in_parent_folders("environment.hcl"))
    region_vars      = read_terragrunt_config(find_in_parent_folders("region.hcl"))

    name            = "vpc-${local.environment_vars.locals.environment}"
    region          = local.region_vars.locals.region
    azs             = local.region_vars.locals.availability_zones
    cidr            = local.region_vars.locals.cidr_block
    public_subnets  = local.region_vars.locals.public_subnets
    private_subnets = local.region_vars.locals.private_subnets

    # The location of the VPC module
    base_source_url = "tfr:///terraform-aws-modules/vpc/aws"
}

# Feed inputs into the VPC module
inputs = {
    name            = local.name
    region          = local.region
    azs             = local.azs
    cidr            = local.cidr
    public_subnets  = local.public_subnets
    private_subnets = local.private_subnets

    enable_nat_gateway = true

    private_subnet_tags = {
        Tier = "Private"
    }

    public_subnet_tags = {
        Tier = "Public"
    }

    tags = {
        Terraform   = "true"
        Environment = "${local.environment_vars.locals.environment}"
    }
}