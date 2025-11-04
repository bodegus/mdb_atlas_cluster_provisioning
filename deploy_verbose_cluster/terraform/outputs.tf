output "cluster_id" {
  description = "Unique 24-hexadecimal digit string that identifies the cluster"
  value       = module.mongodb_cluster.cluster_id
}

output "cluster_name" {
  description = "Name of the cluster as it appears in MongoDB Atlas"
  value       = module.mongodb_cluster.cluster_name
}

output "config_server_type" {
  description = "Describes a sharded cluster's config server type"
  value       = module.mongodb_cluster.config_server_type
}

output "connection_strings" {
  description = "Collection of Uniform Resource Locators that point to the MongoDB database"
  value       = module.mongodb_cluster.connection_strings
  sensitive   = true
}

output "create_date" {
  description = "Date and time when MongoDB Cloud created this cluster"
  value       = module.mongodb_cluster.create_date
}

output "mongo_db_version" {
  description = "Version of MongoDB that the cluster runs"
  value       = module.mongodb_cluster.mongo_db_version
}

output "state_name" {
  description = "Human-readable label that indicates the current operating condition of this cluster"
  value       = module.mongodb_cluster.state_name
}

output "connection_string_private_endpoint" {
  description = "Private endpoint connection string if available"
  value       = try(module.mongodb_cluster.connection_string_private_endpoint, null)
  sensitive   = true
}

output "replication_specs" {
  description = "Current replication specifications for the cluster"
  value       = var.replication_specs
}

output "cluster_type" {
  description = "Type of the cluster (REPLICASET, SHARDED, or GEOSHARDED)"
  value       = var.cluster_type
}

output "backup_enabled" {
  description = "Whether cloud provider backup is enabled"
  value       = var.backup_enabled
}

output "pit_enabled" {
  description = "Whether point-in-time recovery is enabled"
  value       = var.pit_enabled
}

output "environment" {
  description = "Environment this cluster is deployed to"
  value       = var.environment
}

output "tags" {
  description = "Tags applied to the cluster"
  value       = var.tags
}
