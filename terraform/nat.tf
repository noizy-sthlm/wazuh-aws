# https://registry.terraform.io/modules/terraform-aws-modules/ec2-instance/aws/6.1.1
module "nat_instance" {
  source  = "terraform-aws-modules/ec2-instance/aws"
  version = "~> 6.1.1"

  name = "${var.project_name}-nat"

  ami           = data.aws_ami.al2023_arm.id
  instance_type = "t4g.nano"

  subnet_id = module.vpc.public_subnets[0]

  create_security_group         = true
  security_group_description    = "NAT SG: allow all egress, SSH in only"
  security_group_egress_rules   = {"allow-all": { "cidr_ipv4": "0.0.0.0/0", "description": "Allow all", "ip_protocol": "-1" }}
  security_group_ingress_rules  = { "allow-ssh": { "cidr_ipv4": var.allowed_ssh_cidr, "description": "SSH-from-EC2_Instance_Connect_Endpoint", "from_port": 22, "to_port": 22, "ip_protocol": "tcp" },
                                    "allow-private-subnet": { "cidr_ipv4": module.vpc.private_subnets_cidr_blocks[0], "description": "Allow all from private subnet", "from_port": 0, "to_port": 65535, "ip_protocol": "-1" }}

  key_name = var.key_name

  source_dest_check = false
  create_eip        = true

  user_data                   = file("${path.module}/../scripts/nat.sh")
  user_data_replace_on_change = true

  # Root volume: 8GB gp3, encrypted
  root_block_device = {
    type        = "gp3"
    size        = 8
    encrypted   = true
  }

  tags = {
    project = var.project_name
  }
}

# Private through the NAT instance
resource "aws_route" "private_default_via_nat" {
  route_table_id          = module.vpc.private_route_table_ids[0]
  destination_cidr_block  = "0.0.0.0/0"
  network_interface_id    = module.nat_instance.primary_network_interface_id
}