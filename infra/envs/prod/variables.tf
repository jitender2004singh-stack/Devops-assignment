variable "aws_region" {
  description = "AWS region."
  type        = string
}

variable "offline_plan" {
  description = "true = skip AWS authentication so `terraform plan` works without credentials (review/CI). false = real deployment."
  type        = bool
  default     = true
}

variable "project" {
  description = "Project name, used as a prefix for resource names."
  type        = string
}

variable "environment" {
  description = "Environment name (dev, prod)."
  type        = string
}

# --- Network -----------------------------------------------------------------
variable "vpc_cidr" {
  description = "CIDR block of the VPC."
  type        = string
}

variable "azs" {
  description = "Availability zones to use (two or more)."
  type        = list(string)
}

variable "single_nat_gateway" {
  description = "One shared NAT gateway (cheap) instead of one per AZ (highly available)."
  type        = bool
}

# --- ECS / Fargate ---------------------------------------------------------------
variable "container_image" {
  description = "Container image for the application."
  type        = string
}

variable "container_port" {
  description = "Container port."
  type        = number
}

variable "ecs_cpu" {
  description = "Fargate task CPU units."
  type        = number
}

variable "ecs_memory" {
  description = "Fargate task memory (MiB)."
  type        = number
}

variable "ecs_desired_count" {
  description = "Initial number of tasks."
  type        = number
}

variable "ecs_min_capacity" {
  description = "Autoscaling minimum number of tasks."
  type        = number
}

variable "ecs_max_capacity" {
  description = "Autoscaling maximum number of tasks."
  type        = number
}

variable "log_retention_days" {
  description = "Retention of application logs in CloudWatch."
  type        = number
}

variable "certificate_arn" {
  description = "ACM certificate for HTTPS on the ALB. Empty string = HTTP only."
  type        = string
}

variable "alb_deletion_protection" {
  description = "Protect the ALB from deletion."
  type        = bool
}

# --- RDS -----------------------------------------------------------------------------
variable "rds_instance_class" {
  description = "RDS instance class."
  type        = string
}

variable "rds_allocated_storage" {
  description = "Initial RDS storage (GiB)."
  type        = number
}

variable "rds_max_allocated_storage" {
  description = "Maximum RDS storage for autoscaling (GiB)."
  type        = number
}

variable "rds_multi_az" {
  description = "Multi-AZ deployment."
  type        = bool
}

variable "rds_backup_retention_period" {
  description = "Days to keep automated RDS backups."
  type        = number
}

variable "rds_deletion_protection" {
  description = "Deletion protection for the RDS instance."
  type        = bool
}

variable "rds_skip_final_snapshot" {
  description = "Skip the final snapshot on destroy."
  type        = bool
}

variable "rds_performance_insights_enabled" {
  description = "Enable RDS Performance Insights."
  type        = bool
}
