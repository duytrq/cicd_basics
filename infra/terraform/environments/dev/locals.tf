locals {
  common_tags = merge(
    {
      Project     = "cicd-basics"
      Environment = "demo"
      ManagedBy   = "terraform"
      CostProfile = "w4_demo"
    },
    var.tags,
  )

  az_count = 2
}

