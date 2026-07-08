variable "aws_region" {
  description = "AWS region for the demo cluster."
  type        = string
  default     = "ap-southeast-1"
}

variable "aws_profile" {
  description = "Local AWS CLI profile to use. Set to null in CI/OIDC contexts."
  type        = string
  default     = "duy.admin"
  nullable    = true
}

variable "cluster_name" {
  description = "EKS cluster name."
  type        = string
  default     = "cicd-demo"
}

variable "cluster_version" {
  description = "EKS Kubernetes minor version. Keep this on standard support to avoid extended support charges."
  type        = string
  default     = "1.36"
}

variable "vpc_cidr" {
  description = "CIDR block for the demo VPC."
  type        = string
  default     = "10.42.0.0/16"
}

variable "public_access_cidrs" {
  description = "CIDR ranges allowed to reach the EKS public API endpoint. Use your admin IP/CIDR."
  type        = list(string)
}

variable "node_instance_types" {
  description = "Instance types for the low-cost managed node group."
  type        = list(string)
  default     = ["t3.small", "t3a.small"]
}

variable "node_capacity_type" {
  description = "Managed node group capacity type. SPOT is cheaper; ON_DEMAND is more predictable."
  type        = string
  default     = "SPOT"

  validation {
    condition     = contains(["SPOT", "ON_DEMAND"], var.node_capacity_type)
    error_message = "node_capacity_type must be SPOT or ON_DEMAND."
  }
}

variable "node_min_size" {
  description = "Minimum node count. Keep at 0 when the demo is stopped."
  type        = number
  default     = 0
}

variable "node_desired_size" {
  description = "Desired node count while the demo is running."
  type        = number
  default     = 1
}

variable "node_max_size" {
  description = "Maximum node count for the demo node group."
  type        = number
  default     = 1
}

variable "node_disk_size" {
  description = "Root volume size in GiB for EKS worker nodes."
  type        = number
  default     = 10
}

variable "admin_principal_arn" {
  description = "Optional IAM principal ARN to grant EKS cluster-admin access."
  type        = string
  default     = null
  nullable    = true
}

variable "tags" {
  description = "Additional tags applied to all AWS resources."
  type        = map(string)
  default     = {}
}
