output "vpc_cidr"               { value = module.vpc.vpc_cidr_block }
output "public_subnet_cidrs"    { value = module.vpc.public_subnets_cidr_blocks }
output "private_subnet_cidrs"   { value = module.vpc.private_subnets_cidr_blocks }