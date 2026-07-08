module "eks" {
  source = "../../modules/low-cost-eks"

  cluster_name        = var.cluster_name
  cluster_version     = var.cluster_version
  vpc_cidr            = var.vpc_cidr
  public_access_cidrs = var.public_access_cidrs

  node_instance_types = var.node_instance_types
  node_capacity_type  = var.node_capacity_type
  node_min_size       = var.node_min_size
  node_desired_size   = var.node_desired_size
  node_max_size       = var.node_max_size
  node_disk_size      = var.node_disk_size

  admin_principal_arn = var.admin_principal_arn
  az_count            = 2
  tags                = local.common_tags
}

