output "cluster_id" {
  description = "The cluster ID"
  value       = module.cluster.cluster_id
}

output "cluster_name" {
  description = "The cluster name"
  value       = module.cluster.cluster_name
}

output "connection_strings" {
  description = "Set of connection strings for the cluster"
  value       = module.cluster.connection_strings
  sensitive   = true
}

output "state_name" {
  description = "Current state of the cluster"
  value       = module.cluster.state_name
}

output "cluster_type" {
  description = "The cluster type (REPLICASET or SHARDED)"
  value       = "SHARDED"
}

output "random_suffix" {
  description = "The random suffix used for cluster naming"
  value       = random_string.suffix.result
}
