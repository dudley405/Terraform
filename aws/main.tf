
/*
 *   VPC Creation with vpc endpoints
 */
module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "6.5.1"

  name = "dev-vpc"
  region = var.region
  cidr = var.vpc_cidr_block

  azs = var.subnet_availability_zones
  private_subnets = local.private_subnets
  public_subnets = local.public_subnets
  manage_default_route_table = false
  manage_default_network_acl = false
  manage_default_security_group = false
  manage_default_vpc = false

  enable_nat_gateway = true
  one_nat_gateway_per_az = true

  create_igw = true

  tags = {
    Environment = "dev"
  }

}

// VPC Endpoints
module "endpoints" {
  source = "terraform-aws-modules/vpc/aws//modules/vpc-endpoints"

  vpc_id             = module.vpc.vpc_id

  create_security_group = true
  security_group_name_prefix = "${module.vpc.name}-vpc-endpoints-"
  security_group_description = "VPC endpoint security group"
  security_group_rules = {
    ingress_https = {
      description = "HTTPS from VPC"
      cidr_blocks = [module.vpc.vpc_cidr_block]
    }
  }

  endpoints = {
    s3 = {
      /* interface endpoint
      service = "s3"
      tags = { Name = "s3-vpc-endpoint" }
      */

      // Gateway Endpoint
      service = "s3"
      service_type = "Gateway"
      route_table_ids = module.vpc.private_route_table_ids
      tags = { Name = "s3-vpc-endpoint" }
    }
  }

  tags = {
    Environment = "dev"
  }
}