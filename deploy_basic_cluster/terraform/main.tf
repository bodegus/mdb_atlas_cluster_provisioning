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
  cluster_type           = "REPLICASET"
  provider_name          = "AWS"

  # Use the new regions format instead of replication_specs
  regions = var.regions

  # Security defaults from module
  termination_protection_enabled = false

  # Timeout would normally not be set, this value is intended to optimize for TF Demos
  timeouts = {
    create = var.timeout
  }
}
