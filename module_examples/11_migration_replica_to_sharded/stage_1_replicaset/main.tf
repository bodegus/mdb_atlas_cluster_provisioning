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

# Random suffix for unique cluster naming
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

# Stage 1: Deploy as REPLICASET
module "cluster" {
  source = "git::https://github.com/terraform-mongodbatlas-modules/terraform-mongodbatlas-cluster.git"

  project_id             = var.project_id
  name                   = "${var.cluster_name}-${random_string.suffix.result}"
  mongo_db_major_version = var.mongo_db_major_version

  # Stage 1: REPLICASET configuration
  cluster_type  = "REPLICASET"
  provider_name = "AWS"

  regions = [
    {
      name       = "US_EAST_1"
      node_count = 3
      # Using M30 from the start since we plan to migrate to sharded
      # (sharding requires M30 minimum)
    }
  ]

  # Auto-scaling with M30 minimum for future sharding compatibility
  auto_scaling = {
    compute_enabled            = true
    compute_max_instance_size  = "M60"
    compute_min_instance_size  = "M30" # Required for sharding
    compute_scale_down_enabled = true
    disk_gb_enabled            = true
  }

  # Backup configuration
  backup_enabled = var.backup_enabled
  pit_enabled    = var.pit_enabled

  # Security
  termination_protection_enabled = var.termination_protection_enabled
  redact_client_log_data         = var.environment == "prod"

  # Advanced configuration
  advanced_configuration = var.advanced_configuration

  tags = {
    environment = var.environment
    team        = var.team
    application = var.application
    stage       = "replicaset"
    migration   = "replica-to-sharded"
  }

}
