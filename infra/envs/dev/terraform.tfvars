# DEV: small and cheap, short backups, no deletion protection.
# (terraform.tfvars is loaded automatically by terraform plan/apply.)

aws_region   = "ap-south-1"
offline_plan = true # set to false for a real deployment
project      = "hotelapp"
environment  = "dev"

# Network
vpc_cidr           = "10.10.0.0/16"
azs                = ["ap-south-1a", "ap-south-1b"]
single_nat_gateway = true

# ECS / Fargate
container_image         = "public.ecr.aws/nginx/nginx:1.27-alpine"
container_port          = 80
ecs_cpu                 = 256
ecs_memory              = 512
ecs_desired_count       = 1
ecs_min_capacity        = 1
ecs_max_capacity        = 2
log_retention_days      = 7
certificate_arn         = "" # HTTP only in dev
alb_deletion_protection = false

# RDS PostgreSQL
rds_instance_class               = "db.t3.micro"
rds_allocated_storage            = 20
rds_max_allocated_storage        = 50
rds_multi_az                     = false
rds_backup_retention_period      = 3
rds_deletion_protection          = false
rds_skip_final_snapshot          = true
rds_performance_insights_enabled = false
