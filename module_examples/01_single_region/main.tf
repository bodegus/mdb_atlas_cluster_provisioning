module "cluster" {
  source = "git::https://github.com/terraform-mongodbatlas-modules/terraform-mongodbatlas-cluster.git"

  name                   = "single-region"
  project_id             = var.project_id
  mongo_db_major_version = "8.0"
  cluster_type           = "REPLICASET"
  regions = [
    {
      name          = "US_EAST_1"
      node_count    = 3
      provider_name = "AWS"
    }
  ]
  tags = var.tags

  # Timeout for faster test cycles
  timeouts = {
    create = var.timeout
  }
}

output "cluster" {
  value = module.cluster
}
