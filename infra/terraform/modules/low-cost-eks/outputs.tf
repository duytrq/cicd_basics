output "cluster_name" {
  description = "EKS cluster name."
  value       = module.eks.cluster_name
}

output "cluster_endpoint" {
  description = "EKS API endpoint."
  value       = module.eks.cluster_endpoint
}

output "aws_load_balancer_controller_role_arn" {
  description = "IAM role ARN for the aws-load-balancer-controller service account."
  value       = module.aws_load_balancer_controller_irsa_role.iam_role_arn
}

output "vpc_id" {
  description = "VPC ID."
  value       = module.vpc.vpc_id
}

output "public_subnet_ids" {
  description = "Public subnet IDs used by EKS nodes and load balancers."
  value       = module.vpc.public_subnets
}

