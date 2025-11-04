variable "project_id" {
  description = "The MongoDB Atlas project ID"
  type        = string
}

variable "cluster_name" {
  description = "Name of the MongoDB Atlas cluster"
  type        = string
}

variable "mongo_db_major_version" {
  description = "MongoDB major version"
  type        = string
  default     = "8.0"
}

variable "cluster_type" {
  description = "Type of the cluster (REPLICASET, SHARDED, or GEOSHARDED)"
  type        = string
  default     = "REPLICASET"
}

variable "regions" {
  description = "List of regions for the cluster configuration"
  type = list(object({
    name                    = optional(string)
    node_count              = optional(number)
    shard_number            = optional(number)
    provider_name           = optional(string)
    node_count_read_only    = optional(number)
    node_count_analytics    = optional(number)
    instance_size           = optional(string)
    instance_size_analytics = optional(string)
    zone_name               = optional(string)
  }))
  default = []
}

variable "replication_specs" {
  description = "List of settings that configure your cluster regions using verbose configuration"
  type = list(object({
    zone_name = optional(string)
    region_configs = list(object({
      priority      = number
      provider_name = string
      region_name   = string

      electable_specs = optional(object({
        instance_size   = string
        node_count      = optional(number)
        disk_iops       = optional(number)
        disk_size_gb    = optional(number)
        ebs_volume_type = optional(string)
      }))

      analytics_specs = optional(object({
        instance_size   = string
        node_count      = optional(number)
        disk_iops       = optional(number)
        disk_size_gb    = optional(number)
        ebs_volume_type = optional(string)
      }))

      read_only_specs = optional(object({
        instance_size   = string
        node_count      = optional(number)
        disk_iops       = optional(number)
        disk_size_gb    = optional(number)
        ebs_volume_type = optional(string)
      }))

      auto_scaling = optional(object({
        compute_enabled            = optional(bool)
        compute_max_instance_size  = optional(string)
        compute_min_instance_size  = optional(string)
        compute_scale_down_enabled = optional(bool)
        disk_gb_enabled            = optional(bool)
      }))

      analytics_auto_scaling = optional(object({
        compute_enabled            = optional(bool)
        compute_max_instance_size  = optional(string)
        compute_min_instance_size  = optional(string)
        compute_scale_down_enabled = optional(bool)
        disk_gb_enabled            = optional(bool)
      }))
    }))
  }))
}

#variable "auto_scaling" {
#  description = "Global auto-scaling configuration"
#  type = object({
#    compute_enabled            = optional(bool)
#    compute_scale_down_enabled = optional(bool)
#    disk_gb_enabled            = optional(bool)
#  })
#  default = {
#    compute_enabled            = false
#    compute_scale_down_enabled = false
#    disk_gb_enabled            = false
#  }
#}

variable "backup_enabled" {
  description = "Enable cloud provider backup"
  type        = bool
  default     = false
}

variable "pit_enabled" {
  description = "Enable point-in-time recovery"
  type        = bool
  default     = false
}

variable "redact_client_log_data" {
  description = "Redact client data from logs"
  type        = bool
  default     = true
}

variable "termination_protection_enabled" {
  description = "Enable termination protection"
  type        = bool
  default     = false
}

variable "advanced_configuration" {
  description = "Advanced configuration options"
  type = object({
    default_read_concern                 = optional(string)
    default_write_concern                = optional(string)
    fail_index_key_too_long              = optional(bool)
    javascript_enabled                   = optional(bool)
    minimum_enabled_tls_protocol         = optional(string)
    no_table_scan                        = optional(bool)
    oplog_size_mb                        = optional(number)
    oplog_min_retention_hours            = optional(number)
    sample_size_bi_connector             = optional(number)
    sample_refresh_interval_bi_connector = optional(number)
    transaction_lifetime_limit_seconds   = optional(number)
  })
  default = {}
}

variable "bi_connector_config" {
  description = "BI Connector configuration"
  type = object({
    enabled         = optional(bool)
    read_preference = optional(string)
  })
  default = null
}

variable "tags" {
  description = "Tags to apply to the cluster"
  type        = map(string)
  default     = {}
}

variable "environment" {
  description = "Environment name (dev, nonprod, prod)"
  type        = string

  validation {
    condition     = contains(["dev", "nonprod", "prod"], var.environment)
    error_message = "Environment must be one of: dev, nonprod, prod"
  }
}

variable "timeout" {
  description = "Timeout for cluster creation operations"
  type        = string
  default     = "30s"
}
