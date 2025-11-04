# Dev environment configuration - Ultra-simple single region cluster
cluster_name           = "verbose-cluster-dev"
mongo_db_major_version = "8.0"
cluster_type           = "REPLICASET"
environment            = "dev"

# Ultra-simple: Single region with only electable nodes
replication_specs = [{
  region_configs = [{
    priority           = 7
    provider_name      = "AWS"
    region_name        = "US_EAST_1"
    instance_size_name = "M10"
    electable_specs = {
      instance_size = "M10"
      node_count    = 3
    }

    # Auto-scaling for this region
    auto_scaling = {
      compute_enabled            = false
      compute_scale_down_enabled = false
      disk_gb_enabled            = false

  } }]
}]

# No backups for dev
backup_enabled = false
pit_enabled    = false

# Basic security settings
redact_client_log_data         = false
termination_protection_enabled = false

# Minimal advanced configuration
advanced_configuration = {}

# No BI Connector for dev
bi_connector_config = {
  enabled = false
}

# Minimal tags
tags = {
  environment = "dev"
  purpose     = "development"
  department  = "engineering"
  application = "mongodb-atlas-example"
  version     = "1.0.0"
  criticality = "low"
  email       = "example@g.com"
  team        = "example"
}
