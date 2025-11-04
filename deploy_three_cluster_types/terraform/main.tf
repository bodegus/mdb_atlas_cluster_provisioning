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
resource "random_string" "suffix" {
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
  name                   = "${var.cluster_name}-${random_string.suffix.result}"
  mongo_db_major_version = var.mongo_db_major_version
  cluster_type           = var.cluster_type
  provider_name          = "AWS"


  # Use the new regions format instead of replication_specs
  regions = var.regions

  # Auto-scaling configuration (module has good defaults)
  auto_scaling = var.auto_scaling

  # Backup configuration
  backup_enabled = var.backup_enabled
  pit_enabled    = var.pit_enabled

  # Security defaults from module
  redact_client_log_data         = var.environment == "prod"
  termination_protection_enabled = var.termination_protection_enabled

  # Advanced configuration with security defaults
  advanced_configuration = var.advanced_configuration

  tags = {
    environment = var.environment
    team        = var.team
    application = var.application
    department  = var.department
    version     = var.app_version
    email       = var.email
    criticality = var.criticality
  }


  # Timeout would normally not be set, this value is intended to optimize ci test cycles
  timeouts = {
    create = var.timeout
  }
}
