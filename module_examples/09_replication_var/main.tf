module "replication_var" {
  source = "git::https://github.com/terraform-mongodbatlas-modules/terraform-mongodbatlas-cluster.git"

  name                   = "replication-var"
  project_id             = var.project_id
  mongo_db_major_version = "8.0"
  regions                = []
  cluster_type           = "REPLICASET"
  replication_specs = [{
    region_configs = [{
      priority      = 7
      provider_name = "AWS"
      region_name   = "US_EAST_1"
      electable_specs = {
        instance_size = "M10"
        node_count    = 3
      }
      auto_scaling = {
        compute_enabled            = false
        compute_scale_down_enabled = false
        disk_gb_enabled            = false

      }
    }]
  }]
  auto_scaling = {
    compute_enabled            = false
    compute_scale_down_enabled = false
    disk_gb_enabled            = false
  }
  tags = var.tags

  # Timeout for faster test cycles
  timeouts = {
    create = var.timeout
  }
}
