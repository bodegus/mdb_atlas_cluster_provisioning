output "cluster_id" {
  description = "The cluster ID"
  value       = module.mongodb_cluster.cluster_id
}

output "cluster_name" {
  description = "The cluster name"
  value       = module.mongodb_cluster.cluster_name
}

output "connection_strings" {
  description = "Set of connection strings for the cluster"
  value       = module.mongodb_cluster.connection_strings
  sensitive   = true
}

output "state_name" {
  description = "Current state of the cluster"
  value       = module.mongodb_cluster.state_name
}

output "mongo_db_version" {
  description = "MongoDB version of the cluster"
  value       = module.mongodb_cluster.mongo_db_version
}
