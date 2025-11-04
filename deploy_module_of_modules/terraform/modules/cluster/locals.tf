locals {
  env_configs = {
    dev = {
      cluster_name_prefix = "example-cluster-dev"
      regions = [
        {
          name          = "US_EAST_1"
          node_count    = 3
          provider_name = "AWS"
          instance_size = "M30"
        }
      ]
      auto_scaling = {
        compute_enabled            = false
        compute_scale_down_enabled = false
        disk_gb_enabled            = false
      }
      termination_protection_enabled = false
      criticality                    = "low"
    }

    nonprod = {
      cluster_name_prefix = "example-cluster-nonprod"
      regions = [
        {
          name          = "US_EAST_1"
          node_count    = 3
          provider_name = "AWS"
        }
      ]
      auto_scaling = {
        compute_enabled            = true
        compute_max_instance_size  = "M60"
        compute_min_instance_size  = "M30"
        compute_scale_down_enabled = true
        disk_gb_enabled            = true
      }
      termination_protection_enabled = false
      criticality                    = "medium"
    }

    prod = {
      cluster_name_prefix = "example-cluster-prod"
      regions = [
        {
          name                 = "US_EAST_1"
          provider_name        = "AWS"
          node_count           = 2
          node_count_analytics = 1
        },
        {
          name          = "US_EAST_2"
          provider_name = "AWS"
          node_count    = 2
        },
        {
          name          = "US_WEST_1"
          provider_name = "AWS"
          node_count    = 1
        }
      ]
      auto_scaling = {
        compute_enabled            = true
        compute_max_instance_size  = "M60"
        compute_min_instance_size  = "M30"
        compute_scale_down_enabled = true
        disk_gb_enabled            = true
      }
      termination_protection_enabled = false
      criticality                    = "high"
    }
  }

  selected_config = local.env_configs[var.environment]

  # Generate shard regions by expanding base regions for each shard
  shard_regions = flatten([
    for shard_number in range(1, var.shard_count + 1) : [
      for region in local.selected_config.regions : merge(region, {
        shard_number = shard_number
      })
    ]
  ])
}
