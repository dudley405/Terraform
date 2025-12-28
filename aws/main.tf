
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


data "aws_ami" "amazon_linux_2023" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    # This value matches the standard AL2023 AMI naming convention
    values = ["al2023-ami-2023.*-x86_64"]
  }

  filter {
    name   = "architecture"
    values = ["x86_64"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

/*
    Always Define the security group next to resources, even if empty.
    That way, if another resource ingress, it can define what it needs itself.
    Once the resource that needs ingress is deleted, the rule will be too, cleaning up nicely.
 */
resource "aws_security_group" "test-sg" {
  name = "test"
  description = "Demonstrating scaleable SG method"
  vpc_id = module.vpc.vpc_id

  tags = {
    Environment = "dev"
  }
}


// Example of another resource needing ingress from a different location,
// perhaps in another file or module:
/*resource "aws_vpc_security_group_ingress_rule" "allow_http" {
  security_group_id = aws_security_group.test-sg.id // easy to reference when already created
  cidr_ipv4         = module.vpc.vpc_cidr_block
  from_port         = 8080
  ip_protocol       = "http"
  to_port           = 8080
}*/


// Randomly select subnet to evenly distribute resources
resource "random_shuffle" "subnet" {
  input        = module.vpc.private_subnets
  result_count = 1
}


resource "aws_instance" "test" {
  ami           = data.aws_ami.amazon_linux_2023.id
  instance_type = "t3.micro"
  subnet_id = random_shuffle.subnet.result[0]
  vpc_security_group_ids = flatten([aws_security_group.test-sg.id])

  tags = {
    Environment = "dev"
    Name = "test"
  }

  // ignore updated random subnets after creation
  lifecycle {
    ignore_changes = [subnet_id]
  }
}



