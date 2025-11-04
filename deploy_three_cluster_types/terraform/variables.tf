variable "project_id" {
  description = "MongoDB Atlas Project ID (auto-loaded from Atlas if not specified)"
  type        = string
  default     = ""
}

variable "cluster_name" {
  description = "Name of the MongoDB Atlas cluster"
  type        = string
}

variable "cluster_type" {
  description = "Type of MongoDB cluster (REPLICASET, SHARDED, GEOSHARDED)"
  type        = string
}

variable "mongo_db_major_version" {
  description = "MongoDB version"
  type        = string
  default     = "8.0"
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

variable "auto_scaling" {
  description = "Auto scaling configuration"
  type = object({
    compute_enabled            = optional(bool, true)
    compute_max_instance_size  = optional(string, "M60")
    compute_min_instance_size  = optional(string, "M30")
    compute_scale_down_enabled = optional(bool, true)
    disk_gb_enabled            = optional(bool, true)
  })
  default = {
    compute_enabled            = true
    compute_max_instance_size  = "M60"
    compute_min_instance_size  = "M30"
    compute_scale_down_enabled = true
    disk_gb_enabled            = true
  }
}

variable "backup_enabled" {
  description = "Enable cloud backups"
  type        = bool
  default     = true
}

variable "pit_enabled" {
  description = "Enable Point-in-Time recovery"
  type        = bool
  default     = true
}

variable "termination_protection_enabled" {
  description = "Enable termination protection"
  type        = bool
  default     = false
}



variable "advanced_configuration" {
  description = "Advanced cluster configuration"
  type = object({
    default_write_concern        = optional(string, "majority")
    javascript_enabled           = optional(bool, false)
    minimum_enabled_tls_protocol = optional(string, "TLS1_2")
    no_table_scan                = optional(bool)
    oplog_min_retention_hours    = optional(number)
  })
  default = {
    default_write_concern        = "majority"
    javascript_enabled           = false
    minimum_enabled_tls_protocol = "TLS1_2"
  }
}

variable "environment" {
  description = "Environment name (dev, nonprod, prod)"
  type        = string

  validation {
    condition     = contains(["dev", "nonprod", "prod"], var.environment)
    error_message = "Environment must be one of: dev, nonprod, prod"
  }
}

variable "team" {
  description = "Team responsible for the cluster"
  type        = string
}

variable "application" {
  description = "Application name"
  type        = string
}

variable "department" {
  description = "Department name"
  type        = string
}

variable "app_version" {
  description = "Application version"
  type        = string
}

variable "email" {
  description = "Contact email"
  type        = string
}

variable "criticality" {
  description = "Criticality level (low, medium, high)"
  type        = string
}

variable "timeout" {
  description = "Timeout for cluster creation operations"
  type        = string
  default     = "30s"
}
