variable "name" {
  description = "Name prefix (e.g. hotelapp-dev). Used for the DB identifier and subnet group."
  type        = string
}

variable "private_subnet_ids" {
  description = "Private subnets for the DB subnet group (at least two AZs)."
  type        = list(string)
}

variable "rds_security_group_id" {
  description = "Security group of the database (only allows traffic from ECS)."
  type        = string
}

variable "engine_version" {
  description = "PostgreSQL engine version."
  type        = string
  default     = "16.6"
}

variable "instance_class" {
  description = "RDS instance class (sizing differs per environment)."
  type        = string
}

variable "allocated_storage" {
  description = "Initial storage in GiB."
  type        = number
}

variable "max_allocated_storage" {
  description = "Upper limit in GiB for storage autoscaling (0 disables autoscaling)."
  type        = number
}

variable "db_name" {
  description = "Name of the initial database."
  type        = string
  default     = "bookings"
}

variable "master_username" {
  description = "Master user name. The password is generated and stored in AWS Secrets Manager."
  type        = string
  default     = "appadmin"
}

variable "multi_az" {
  description = "Run a standby in a second AZ."
  type        = bool
}

variable "backup_retention_period" {
  description = "Days to keep automated backups (1-35)."
  type        = number

  validation {
    condition     = var.backup_retention_period >= 1 && var.backup_retention_period <= 35
    error_message = "backup_retention_period must be between 1 and 35 days."
  }
}

variable "backup_window" {
  description = "Daily backup window (UTC)."
  type        = string
  default     = "21:00-22:00"
}

variable "maintenance_window" {
  description = "Weekly maintenance window (UTC)."
  type        = string
  default     = "sun:22:30-sun:23:30"
}

variable "deletion_protection" {
  description = "Block deletion of the DB instance (true for prod)."
  type        = bool
}

variable "skip_final_snapshot" {
  description = "Skip the final snapshot when the instance is destroyed (true for dev only)."
  type        = bool
}

variable "performance_insights_enabled" {
  description = "Enable Performance Insights (not supported on the smallest instance classes)."
  type        = bool
  default     = false
}

variable "apply_immediately" {
  description = "Apply changes immediately instead of in the next maintenance window."
  type        = bool
  default     = false
}

variable "tags" {
  description = "Tags added to every resource."
  type        = map(string)
  default     = {}
}
