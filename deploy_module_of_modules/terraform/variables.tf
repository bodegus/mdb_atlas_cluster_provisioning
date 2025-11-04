variable "environment" {
  description = "Environment (dev, nonprod, prod)"
  type        = string

  validation {
    condition     = contains(["dev", "nonprod", "prod"], var.environment)
    error_message = "Environment must be one of: dev, nonprod, prod"
  }
}

variable "cluster_name" {
  description = "Name of the MongoDB Atlas cluster"
  type        = string
  default     = ""
}

variable "project_id" {
  description = "MongoDB Atlas Project ID (auto-loaded from Atlas if not specified)"
  type        = string
  default     = ""
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

variable "shard_count" {
  description = "Number of shards for the cluster"
  type        = number
  default     = 1

  validation {
    condition     = var.shard_count >= 1 && var.shard_count <= 50
    error_message = "Number of shards must be between 1 and 50."
  }
}
