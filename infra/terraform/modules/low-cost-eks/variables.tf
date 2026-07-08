variable "cluster_name" {
  description = "EKS cluster name."
  type        = string
}

variable "cluster_version" {
  description = "EKS Kubernetes minor version."
  type        = string
}

variable "vpc_cidr" {
  description = "CIDR block for the cluster VPC."
  type        = string
}

variable "public_access_cidrs" {
  description = "CIDR ranges allowed to reach the EKS public API endpoint."
  type        = list(string)
}

variable "node_instance_types" {
  description = "Instance types for the low-cost managed node group."
  type        = list(string)
}

variable "node_capacity_type" {
  description = "Managed node group capacity type."
  type        = string

  validation {
    condition     = contains(["SPOT", "ON_DEMAND"], var.node_capacity_type)
    error_message = "node_capacity_type must be SPOT or ON_DEMAND."
  }
}

variable "node_min_size" {
  description = "Minimum node count."
  type        = number
}

variable "node_desired_size" {
  description = "Desired node count."
  type        = number
}

variable "node_max_size" {
  description = "Maximum node count."
  type        = number
}

variable "node_disk_size" {
  description = "Root volume size in GiB for EKS worker nodes."
  type        = number
}

variable "admin_principal_arn" {
  description = "Optional IAM principal ARN to grant EKS cluster-admin access."
  type        = string
  default     = null
  nullable    = true
}

variable "az_count" {
  description = "Number of availability zones for public subnets."
  type        = number
  default     = 2
}

variable "tags" {
  description = "Tags applied to resources created by this module."
  type        = map(string)
  default     = {}
}

