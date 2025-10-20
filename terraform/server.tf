# https://registry.terraform.io/modules/terraform-aws-modules/ec2-instance/aws/6.1.1
module "wazuh_server" {
  source  = "terraform-aws-modules/ec2-instance/aws"
  version = "~> 6.1.1"

  name = "${var.project_name}-server"

  ami           = data.aws_ami.ubuntu_noble_numbat.id
  instance_type = "t4g.small"

  subnet_id = module.vpc.public_subnets[0]

  create_eip = true

  # https://documentation.wazuh.com/current/getting-started/architecture.html
  create_security_group         = true
  security_group_egress_rules   = {"allow-all": { "cidr_ipv4": "0.0.0.0/0", "description": "Allow all", "ip_protocol": "-1" }}
  security_group_ingress_rules  = { "endpoint-ssh": { "referenced_security_group_id": resource.aws_security_group.ec2_instance_connect_endpoint.id, "description": "SSH-from-EC2_Instance_Connect_Endpoint", "from_port": 22, "to_port": 22, "ip_protocol": "tcp" },
                                    "Agent connection service": { "cidr_ipv4": var.agent_ipv4_cidr, "from_port": 1514, "to_port": 1514, "ip_protocol": "tcp" },
                                    "Agent enrollment service": { "cidr_ipv4": var.agent_ipv4_cidr, "from_port": 1515, "to_port": 1515, "ip_protocol": "tcp" },
                                    "Wazuh server RESTful API": { "referenced_security_group_id": module.wazuh_dashboard.security_group_id , "from_port": 55000, "to_port": 55000, "ip_protocol": "tcp" }}

  root_block_device = {
    type        = "gp3"
    size        = 10
    encrypted   = true
  }

  tags = {
    project = var.project_name
  }
}