module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 5.0"

  name = var.cluster_name
  cidr = var.vpc_cidr

  azs            = slice(data.aws_availability_zones.available.names, 0, var.az_count)
  public_subnets = [for index in range(var.az_count) : cidrsubnet(var.vpc_cidr, 8, index)]

  create_igw                    = true
  enable_nat_gateway            = false
  single_nat_gateway            = false
  map_public_ip_on_launch       = true
  manage_default_network_acl    = false
  manage_default_route_table    = false
  manage_default_security_group = false

  public_subnet_tags = {
    "kubernetes.io/cluster/${var.cluster_name}" = "shared"
    "kubernetes.io/role/elb"                    = "1"
  }

  tags = var.tags
}

