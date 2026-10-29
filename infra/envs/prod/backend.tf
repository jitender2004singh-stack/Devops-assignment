# Remote state for the PROD environment (separate bucket, key and lock table from dev).
# The bucket and DynamoDB table must exist before `terraform init`.
# For offline review (no AWS access) see README: scripts/tf-check.sh prod
terraform {
  backend "s3" {
    bucket         = "hotelapp-prod-tfstate"
    key            = "prod/terraform.tfstate"
    region         = "ap-south-1"
    dynamodb_table = "hotelapp-prod-tflock"
    encrypt        = true
  }
}
