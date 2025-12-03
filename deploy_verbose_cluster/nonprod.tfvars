# Non-prod environment configuration - Multi-region with analytics nodes
cluster_name           = "verbose-cluster-nonprod"
mongo_db_major_version = "8.0"
cluster_type           = "REPLICASET"
environment            = "nonprod"
# Multi-region configuration with analytics nodes using verbose replication_specs
replication_specs = [{
  region_configs = [
    {
      priority           = 7
      provider_name      = "AWS"
      region_name        = "US_EAST_1"
      instance_size_name = "M10"
      electable_specs = {
        instance_size = "M10"
        node_count    = 3
        disk_size_gb  = 100
      }
      # Auto-scaling for this region
      auto_scaling = {
        compute_enabled            = true
        compute_max_instance_size  = "M40"
        compute_min_instance_size  = "M10"
        compute_scale_down_enabled = true
        disk_gb_enabled            = true
      }

    },
    {
      priority      = 6
      provider_name = "AWS"
      region_name   = "US_WEST_2"

      electable_specs = {
        instance_size = "M10"
        node_count    = 2
        disk_size_gb  = 100
      }
      # Auto-scaling for this region
      auto_scaling = {
        compute_enabled            = true
        compute_max_instance_size  = "M40"
        compute_min_instance_size  = "M10"
        compute_scale_down_enabled = true
        disk_gb_enabled            = true
      }

    }
  ]
}]

termination_protection_enabled = false


# Tags
tags = {
  environment = "nonprod"
  team        = "platform"
  application = "verbose-example"
  department  = "engineering"
  version     = "1.0.0"
  email       = "platform@example.com"
  criticality = "medium"
  purpose     = "testing"
}
