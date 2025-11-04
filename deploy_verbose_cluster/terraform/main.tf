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

# add a 6 random letter string
resource "random_string" "prefix" {
  length  = 6
  special = false # Exclude special characters
  upper   = false # Include uppercase letters (default: true)
  lower   = true  # Include lowercase letters (default: true)
  numeric = true  # Include numbers (default: true)

  # This ensures a new random string is generated whenever the cluster would be recreated
  # Using uuid() ensures uniqueness even for rapid successive runs
  keepers = {
    cluster_config = jsonencode({
      timestamp = timestamp()
      uuid      = uuid()
    })
  }
}

module "mongodb_cluster" {
  source = "git::https://github.com/terraform-mongodbatlas-modules/terraform-mongodbatlas-cluster.git"

  project_id             = var.project_id
  name                   = "${var.cluster_name}-${random_string.prefix.result}"
  mongo_db_major_version = var.mongo_db_major_version

  # Using verbose replication_specs instead of simplified regions interface
  # When using replication_specs, regions must be set to empty array
  regions           = var.regions
  replication_specs = var.replication_specs

  # Cluster type and sharding configuration
  cluster_type = var.cluster_type

  # Auto-scaling configuration
  # auto_scaling = var.auto_scaling

  # Backup configuration
  backup_enabled = var.backup_enabled
  pit_enabled    = var.pit_enabled

  # Security configuration
  redact_client_log_data         = var.redact_client_log_data
  termination_protection_enabled = var.termination_protection_enabled

  # Advanced configuration
  advanced_configuration = var.advanced_configuration

  # Bi-connector configuration
  bi_connector_config = var.bi_connector_config

  # Tags
  tags = var.tags

  # Timeout would normally not be set, this value is intended to optimize ci test cycles
  timeouts = {
    create = var.timeout
  }
}
