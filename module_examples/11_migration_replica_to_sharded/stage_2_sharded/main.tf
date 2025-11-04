terraform {
  required_version = ">= 1.6"
  required_providers {
    mongodbatlas = {
      source  = "mongodb/mongodbatlas"
      version = "~> 2.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.6"
    }
  }
}

provider "mongodbatlas" {}

# IMPORTANT: Using the SAME random_string resource name to maintain state
resource "random_string" "suffix" {
  length  = 6
  special = false
  upper   = false
  lower   = true
  numeric = true

  keepers = {
    cluster_config = jsonencode({
      timestamp = timestamp()
      uuid      = uuid()
    })
  }
}

# Stage 2: Migrate to SHARDED
# IMPORTANT: Using the SAME module name "cluster" to update existing resource
module "cluster" {
  source = "git::https://github.com/terraform-mongodbatlas-modules/terraform-mongodbatlas-cluster.git"

  project_id             = var.project_id
  name                   = "${var.cluster_name}-${random_string.suffix.result}"
  mongo_db_major_version = var.mongo_db_major_version

  # Stage 2: SHARDED configuration (changed from REPLICASET)
  cluster_type  = "SHARDED"
  provider_name = "AWS"

  regions = [
    {
      name         = "US_EAST_1"
      node_count   = 3
      shard_number = 1 # Added for sharding
      # M30 minimum size enforced by auto_scaling
    }
  ]

  # Same auto-scaling configuration - M30 minimum supports sharding
  auto_scaling = {
    compute_enabled            = true
    compute_max_instance_size  = "M60"
    compute_min_instance_size  = "M30" # Required for sharding
    compute_scale_down_enabled = true
    disk_gb_enabled            = true
  }

  # Backup configuration (unchanged)
  backup_enabled = var.backup_enabled
  pit_enabled    = var.pit_enabled

  # Security (unchanged)
  termination_protection_enabled = var.termination_protection_enabled
  redact_client_log_data         = var.environment == "prod"

  # Advanced configuration (unchanged)
  advanced_configuration = var.advanced_configuration

  tags = {
    environment = var.environment
    team        = var.team
    application = var.application
    stage       = "sharded" # Updated tag
    migration   = "replica-to-sharded"
  }

}
