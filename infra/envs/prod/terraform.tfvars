# PROD: larger sizing, HA, long backups, deletion protection on.
# (terraform.tfvars is loaded automatically by terraform plan/apply.)

aws_region   = "ap-south-1"
offline_plan = true # set to false for a real deployment
project      = "hotelapp"
environment  = "prod"

# Network
vpc_cidr           = "10.20.0.0/16"
azs                = ["ap-south-1a", "ap-south-1b"]
single_nat_gateway = false # one NAT gateway per AZ

# ECS / Fargate
container_image         = "public.ecr.aws/nginx/nginx:1.27-alpine"
container_port          = 80
ecs_cpu                 = 512
ecs_memory              = 1024
ecs_desired_count       = 2
ecs_min_capacity        = 2
ecs_max_capacity        = 6
log_retention_days      = 90
certificate_arn         = "arn:aws:acm:ap-south-1:123456789012:certificate/00000000-0000-0000-0000-000000000000" # placeholder: replace with a real ACM certificate
alb_deletion_protection = true

# RDS PostgreSQL
rds_instance_class               = "db.m6g.large"
rds_allocated_storage            = 100
rds_max_allocated_storage        = 500
rds_multi_az                     = true
rds_backup_retention_period      = 14
rds_deletion_protection          = true
rds_skip_final_snapshot          = false
rds_performance_insights_enabled = true
