# Production environment configuration - Sharded cluster with multi-region redundancy
cluster_name           = "verbose-cluster-prod"
mongo_db_major_version = "8.0"
cluster_type           = "SHARDED"
environment            = "prod"

# Sharded cluster with multiple shards and geo-distributed configuration
replication_specs = [
  # Shard 0 - Primary in US East, Secondary in US West and Europe
  {
    zone_name = "shard-0"
    region_configs = [
      {
        priority      = 7
        provider_name = "AWS"
        region_name   = "US_EAST_1"

        electable_specs = {
          instance_size   = "M30"
          node_count      = 3
          disk_size_gb    = 200
          disk_iops       = 3000
          ebs_volume_type = "PROVISIONED"
        }

        analytics_specs = {
          instance_size   = "M30"
          node_count      = 2
          disk_size_gb    = 200
          disk_iops       = 3000
          ebs_volume_type = "PROVISIONED"
        }

        auto_scaling = {
          compute_enabled            = true
          compute_max_instance_size  = "M60"
          compute_min_instance_size  = "M30"
          compute_scale_down_enabled = true
          disk_gb_enabled            = true
        }

        analytics_auto_scaling = {
          compute_enabled            = true
          compute_max_instance_size  = "M50"
          compute_min_instance_size  = "M30"
          compute_scale_down_enabled = true
          disk_gb_enabled            = true
        }
      },
      {
        priority      = 6
        provider_name = "AWS"
        region_name   = "US_WEST_2"

        electable_specs = {
          instance_size   = "M30"
          node_count      = 2
          disk_size_gb    = 200
          disk_iops       = 3000
          ebs_volume_type = "PROVISIONED"
        }

        read_only_specs = {
          instance_size = "M30"
          node_count    = 2
          disk_size_gb  = 200
        }

        auto_scaling = {
          compute_enabled            = true
          compute_max_instance_size  = "M60"
          compute_min_instance_size  = "M30"
          compute_scale_down_enabled = true
          disk_gb_enabled            = true
        }
      },
      {
        priority      = 5
        provider_name = "AWS"
        region_name   = "EU_WEST_1"

        electable_specs = {
          instance_size   = "M30"
          node_count      = 2
          disk_size_gb    = 200
          disk_iops       = 3000
          ebs_volume_type = "PROVISIONED"
        }

        read_only_specs = {
          instance_size = "M30"
          node_count    = 2
          disk_size_gb  = 200
        }

        auto_scaling = {
          compute_enabled            = true
          compute_max_instance_size  = "M60"
          compute_min_instance_size  = "M30"
          compute_scale_down_enabled = true
          disk_gb_enabled            = true
        }

      }
    ]
  },
  # Shard 1 - Similar configuration for data distribution
  {
    zone_name = "shard-1"
    region_configs = [
      {
        priority      = 7
        provider_name = "AWS"
        region_name   = "US_EAST_1"

        electable_specs = {
          instance_size   = "M30"
          node_count      = 3
          disk_size_gb    = 200
          disk_iops       = 3000
          ebs_volume_type = "PROVISIONED"
        }

        auto_scaling = {
          compute_enabled            = true
          compute_max_instance_size  = "M60"
          compute_min_instance_size  = "M30"
          compute_scale_down_enabled = true
          disk_gb_enabled            = true
        }
      },
      {
        priority      = 6
        provider_name = "AWS"
        region_name   = "US_WEST_2"

        electable_specs = {
          instance_size   = "M30"
          node_count      = 2
          disk_size_gb    = 200
          disk_iops       = 3000
          ebs_volume_type = "PROVISIONED"
        }

        auto_scaling = {
          compute_enabled            = true
          compute_max_instance_size  = "M60"
          compute_min_instance_size  = "M30"
          compute_scale_down_enabled = true
          disk_gb_enabled            = true
        }

      },
      {
        priority      = 5
        provider_name = "AWS"
        region_name   = "EU_WEST_1"

        electable_specs = {
          instance_size   = "M30"
          node_count      = 2
          disk_size_gb    = 200
          disk_iops       = 3000
          ebs_volume_type = "PROVISIONED"
        }

        auto_scaling = {
          compute_enabled            = true
          compute_max_instance_size  = "M60"
          compute_min_instance_size  = "M30"
          compute_scale_down_enabled = true
          disk_gb_enabled            = true
        }

      }
    ]
  }
]


# Backup and recovery enabled for production
backup_enabled = true
pit_enabled    = true

# Security settings - maximum protection for production
redact_client_log_data         = true
termination_protection_enabled = false

# Advanced configuration for production
advanced_configuration = {
  javascript_enabled                 = false
  minimum_enabled_tls_protocol       = "TLS1_2"
  no_table_scan                      = false
  oplog_size_mb                      = 4096
  oplog_min_retention_hours          = 72
  default_read_concern               = "majority"
  default_write_concern              = "majority"
  fail_index_key_too_long            = true
  transaction_lifetime_limit_seconds = 60
}

# Tags
tags = {
  environment = "prod"
  team        = "platform"
  application = "verbose-example"
  department  = "engineering"
  version     = "1.0.0"
  email       = "platform@example.com"
  criticality = "high"
  compliance  = "pci-dss"
  backup      = "enabled"
  dr_region   = "us-west-2"
}
