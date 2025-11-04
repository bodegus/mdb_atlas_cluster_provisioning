module "cluster" {
  source = "git::https://github.com/terraform-mongodbatlas-modules/terraform-mongodbatlas-cluster.git"

  name         = "multi-region-multi-geo"
  project_id   = var.project_id
  cluster_type = "SHARDED"
  regions = [
    {
      name         = "US_EAST_1"
      node_count   = 3
      shard_number = 0
      }, {
      name         = "US_EAST_2"
      node_count   = 2
      shard_number = 0
    }
  ]
  auto_scaling = {
    compute_enabled = false
    disk_gb_enabled = false
  }

  provider_name = "AWS"
  instance_size = "M50"
  disk_size_gb  = 100
  tags          = var.tags

  # Timeout for faster test cycles
  timeouts = {
    create = var.timeout
  }
}
