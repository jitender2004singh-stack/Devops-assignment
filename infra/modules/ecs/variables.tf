variable "name" {
  description = "Name prefix (e.g. hotelapp-dev). Keep it short: it is used in ALB/target group names (32 char limit)."
  type        = string
}

variable "aws_region" {
  description = "AWS region (used for the CloudWatch Logs driver)."
  type        = string
}

variable "vpc_id" {
  description = "VPC of the target group."
  type        = string
}

variable "public_subnet_ids" {
  description = "Public subnets for the ALB."
  type        = list(string)
}

variable "private_subnet_ids" {
  description = "Private subnets for the Fargate tasks."
  type        = list(string)
}

variable "alb_security_group_id" {
  description = "Security group attached to the ALB."
  type        = string
}

variable "ecs_security_group_id" {
  description = "Security group attached to the Fargate tasks."
  type        = string
}

variable "container_image" {
  description = "Container image to run. Any simple image works for this exercise."
  type        = string
  default     = "public.ecr.aws/nginx/nginx:1.27-alpine"
}

variable "container_port" {
  description = "Port the container listens on."
  type        = number
  default     = 80
}

variable "health_check_path" {
  description = "HTTP path the ALB uses to check the tasks."
  type        = string
  default     = "/"
}

variable "cpu" {
  description = "Fargate task CPU units (256, 512, 1024, ...)."
  type        = number
}

variable "memory" {
  description = "Fargate task memory in MiB (must be a valid combination with cpu)."
  type        = number
}

variable "desired_count" {
  description = "Initial number of tasks."
  type        = number
}

variable "min_capacity" {
  description = "Autoscaling: minimum number of tasks."
  type        = number
}

variable "max_capacity" {
  description = "Autoscaling: maximum number of tasks."
  type        = number
}

variable "cpu_target_percent" {
  description = "Autoscaling: target average CPU utilisation."
  type        = number
  default     = 60
}

variable "certificate_arn" {
  description = "ACM certificate ARN. When set, the ALB serves HTTPS on 443 and redirects HTTP to HTTPS. Leave empty for plain HTTP."
  type        = string
  default     = ""
}

variable "alb_deletion_protection" {
  description = "Protect the ALB from accidental deletion."
  type        = bool
  default     = false
}

variable "log_retention_days" {
  description = "CloudWatch Logs retention for the application logs."
  type        = number
  default     = 30
}

variable "db_host" {
  description = "Database hostname passed to the container as DB_HOST."
  type        = string
}

variable "db_port" {
  description = "Database port passed to the container as DB_PORT."
  type        = number
}

variable "db_name" {
  description = "Database name passed to the container as DB_NAME."
  type        = string
}

variable "db_secret_arn" {
  description = "Secrets Manager secret with the DB credentials (JSON keys: username, password)."
  type        = string
}

variable "tags" {
  description = "Tags added to every resource."
  type        = map(string)
  default     = {}
}
