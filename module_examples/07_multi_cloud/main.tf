module "cluster" {
  source = "git::https://github.com/terraform-mongodbatlas-modules/terraform-mongodbatlas-cluster.git"

  name         = "multi-cloud"
  project_id   = var.project_id
  cluster_type = "SHARDED"
  regions = [
    {
      shard_number         = 0
      name                 = "US_WEST_2"
      node_count           = 2
      node_count_read_only = 2
      provider_name        = "AZURE"
      }, {
      shard_number         = 0
      name                 = "US_EAST_2"
      node_count           = 1
      node_count_read_only = 2
      provider_name        = "AWS"
    },
    {
      shard_number         = 1
      name                 = "US_WEST_2"
      node_count           = 2
      node_count_read_only = 2
      provider_name        = "AZURE"
      }, {
      shard_number         = 1
      name                 = "US_EAST_2"
      node_count           = 1
      node_count_read_only = 2
      provider_name        = "AWS"
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
