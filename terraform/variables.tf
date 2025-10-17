variable "region" {
  type    = string
  default = "eu-central-1"
}

variable "availability_zone" {
  type    = string
  default = "euc1-az1"
}

variable "project_name" {
  type    = string
  default = "wazuh-lab"
}

variable "vpc_cidr" {
  type    = string
  default = "10.0.0.0/16"
}

variable "public_subnet_cidr" {
  type    = string
  default = "10.0.0.0/24"
}

variable "private_subnet_cidr" {
  type    = string
  default = "10.0.1.0/24"
}

variable "key_name" {
  type        = string
  description = "An existing Key Pair, for SSH access to the NAT instance"
}

variable "allowed_ssh_cidr" {
  type        = string
  description = " Allow ipv4/cidr to SSH to the NAT instance"
}

variable "agent_ipv4_cidr" {
  type = string
  description = "CIDR block for Wazuh agents to connect to the manager"
}