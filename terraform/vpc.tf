
# https://registry.terraform.io/modules/terraform-aws-modules/vpc/aws/6.4.0

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 6.4.0"

  name = var.project_name

  cidr            = var.vpc_cidr
  public_subnets  = [var.public_subnet_cidr]
  private_subnets = [var.private_subnet_cidr]

  azs = [var.availability_zone]

  create_igw         = true
  enable_nat_gateway = false

  map_public_ip_on_launch = true

  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    project = var.project_name
  }
}
