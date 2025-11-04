variable "project_id" {
  description = "MongoDB Atlas Project ID"
  type        = string
  default     = ""
}

variable "cluster_name" {
  description = "Name of the MongoDB Atlas cluster"
  type        = string
  default     = "migration-example"
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
  description = "Environment name (dev, staging, prod)"
  type        = string
  default     = "dev"
}

variable "team" {
  description = "Team responsible for the cluster"
  type        = string
  default     = "DevOps"
}

variable "application" {
  description = "Application name"
  type        = string
  default     = "Migration Example"
}
