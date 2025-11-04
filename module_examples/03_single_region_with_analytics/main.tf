module "cluster" {
  source = "git::https://github.com/terraform-mongodbatlas-modules/terraform-mongodbatlas-cluster.git"

  name          = "single-region-with-analytics"
  project_id    = var.project_id
  cluster_type  = "SHARDED"
  provider_name = "AWS"
  regions = [
    {
      name       = "US_EAST_1"
      node_count = 3
      #instance_size = "M30"  # comment to allow auto-scaling to set size
      shard_number         = 1
      node_count_analytics = 1
    }
  ]
  # Override auto-scaling to use M30 as minimum (required for sharded clusters)
  auto_scaling = {
    compute_enabled            = true
    compute_max_instance_size  = "M50"
    compute_min_instance_size  = "M30"
    compute_scale_down_enabled = true
    disk_gb_enabled            = true
  }
  tags = var.tags

  # Timeout for faster test cycles
  timeouts = {
    create = var.timeout
  }
}

output "cluster" {
  value = module.cluster
}
