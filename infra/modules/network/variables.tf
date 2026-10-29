variable "name" {
  description = "Name prefix for all network resources (e.g. hotelapp-dev)."
  type        = string
}

variable "vpc_cidr" {
  description = "CIDR block of the VPC."
  type        = string
  default     = "10.0.0.0/16"
}

variable "azs" {
  description = "Availability zones to spread subnets across (one public + one private subnet per AZ)."
  type        = list(string)
}

variable "single_nat_gateway" {
  description = "true = one shared NAT gateway (cheaper, for dev). false = one NAT gateway per AZ (highly available, for prod)."
  type        = bool
  default     = true
}

variable "container_port" {
  description = "Port the application container listens on (ALB -> ECS traffic)."
  type        = number
  default     = 80
}

variable "db_port" {
  description = "Port of the database engine (5432 for PostgreSQL)."
  type        = number
  default     = 5432
}

variable "tags" {
  description = "Tags added to every resource."
  type        = map(string)
  default     = {}
}
