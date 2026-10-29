provider "aws" {
  region = var.aws_region

  # Offline plan support (see README): while offline_plan = true the provider does
  # not authenticate or call AWS, so `terraform plan -refresh=false` works on a
  # machine without AWS credentials. Set offline_plan = false for a real deployment.
  access_key                  = var.offline_plan ? "mock-access-key" : null
  secret_key                  = var.offline_plan ? "mock-secret-key" : null
  skip_credentials_validation = var.offline_plan
  skip_requesting_account_id  = var.offline_plan
  skip_metadata_api_check     = var.offline_plan
  skip_region_validation      = var.offline_plan
}
