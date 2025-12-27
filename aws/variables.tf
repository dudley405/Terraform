variable "region" {
  type = string
  description = "AWS Region for resources"
  default = "us-west-1"
}

variable "subnet_availability_zones" {
  type = list(string)
  description = "AWS Availability Zones for Subnets"
  default = ["us-west-1a", "us-west-1c"]
}

variable "vpc_cidr_block" {
  type = string
  description = "CIDR block for VPC"
  default = "10.0.0.0/16"
}

locals {
  private_subnets = slice(cidrsubnets(var.vpc_cidr_block, 2, 2, 2, 2), 0,2)
  public_subnets = slice(cidrsubnets(var.vpc_cidr_block, 2, 2, 2, 2), 2,4)
}
