variable "project_id" {
  description = "MongoDB Atlas Project ID (auto-loaded from Atlas if not specified)"
  type        = string
  default     = ""
}

variable "cluster_name" {
  description = "Name of the MongoDB Atlas cluster"
  type        = string
}

variable "mongo_db_major_version" {
  description = "MongoDB version"
  type        = string
  default     = "8.0"
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


variable "timeout" {
  description = "Timeout for cluster creation operations"
  type        = string
  default     = "30s"
}

variable "shard_count" {
  description = "Number of shards for the cluster"
  type        = number
  default     = 1

  validation {
    condition     = var.shard_count >= 1 && var.shard_count <= 50
    error_message = "Number of shards must be between 1 and 50."
  }
}
