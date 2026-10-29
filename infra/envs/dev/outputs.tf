output "alb_dns_name" {
  description = "Public DNS name of the load balancer."
  value       = module.ecs.alb_dns_name
}

output "ecs_cluster_name" {
  description = "ECS cluster name."
  value       = module.ecs.cluster_name
}

output "rds_address" {
  description = "Private RDS hostname."
  value       = module.rds.address
}

output "rds_master_user_secret_arn" {
  description = "Secrets Manager secret with the RDS master credentials."
  value       = module.rds.master_user_secret_arn
}

output "vpc_id" {
  description = "VPC ID."
  value       = module.network.vpc_id
}
