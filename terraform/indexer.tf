# https://registry.terraform.io/modules/terraform-aws-modules/ec2-instance/aws/6.1.1
module "wazuh_indexer" {
  source  = "terraform-aws-modules/ec2-instance/aws"
  version = "~> 6.1.1"

  name = "${var.project_name}-indexer"

  ami           = data.aws_ami.ubuntu_noble_numbat.id
  instance_type = "t4g.medium"

  subnet_id = module.vpc.private_subnets[0]

  # https://documentation.wazuh.com/current/getting-started/architecture.html
  # Tighten Wazuh-indexer-RESTful-API to Dashboard and Manager later
  create_security_group         = true
  security_group_description    = "Intexer SG : REST API and Endpoint SSH"
  security_group_egress_rules   = {"allow-all": { "cidr_ipv4": "0.0.0.0/0", "description": "Allow all", "ip_protocol": "-1" }}
  security_group_ingress_rules  = { "endpoint-ssh": { "referenced_security_group_id": resource.aws_security_group.ec2_instance_connect_endpoint.id, "description": "SSH-from-EC2_Instance_Connect_Endpoint", "from_port": 22, "to_port": 22, "ip_protocol": "tcp" },
                                    "Wazuh-indexer-RESTful-API": { "cidr_ipv4": module.vpc.vpc_cidr_block, "description": "RESTful API from VPC", "from_port": 9200, "to_port": 9200, "ip_protocol": "tcp" }}

  #vpc_security_group_ids = [resource.]
  key_name = var.key_name

  # Root volume: 8GB gp3, encrypted
  root_block_device = {
    type        = "gp3"
    size        = 20
    encrypted   = true
  }

  tags = {
    project = var.project_name
  }
}