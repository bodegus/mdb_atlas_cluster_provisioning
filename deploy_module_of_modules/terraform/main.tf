terraform {
  required_version = ">= 1.6"
}

module "mongodb_cluster" {
  source = "./modules/cluster"

  cluster_name = var.cluster_name
  environment  = var.environment
  project_id   = var.project_id
  shard_count  = var.shard_count

  # Tag values
  team        = var.team
  application = var.application
  department  = var.department
  app_version = var.app_version
  email       = var.email
}
