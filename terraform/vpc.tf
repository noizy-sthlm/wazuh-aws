
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

# EC2 Instance Connect Endpoint
resource "aws_security_group" "ec2_instance_connect_endpoint" {
  name        = "ec2-instance-connect"
  description = "Allow SSH to instances in the VPC"
  vpc_id      = module.vpc.vpc_id
}

resource "aws_vpc_security_group_egress_rule" "allow_ssh_to_vpc" {
  security_group_id = aws_security_group.ec2_instance_connect_endpoint.id
  cidr_ipv4         = module.vpc.vpc_cidr_block
  from_port         = 22
  to_port           = 22
  ip_protocol       = "tcp"
}

resource "aws_ec2_instance_connect_endpoint" "ec2_instance_connect" {
  subnet_id           = module.vpc.private_subnets[0]
  security_group_ids  = [resource.aws_security_group.ec2_instance_connect_endpoint.id]
  preserve_client_ip  = false

  tags = {
    project = var.project_name
  }
}
