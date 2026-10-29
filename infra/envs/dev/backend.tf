# Remote state for the DEV environment (its own bucket, key and lock table).
# The bucket and DynamoDB table must exist before `terraform init`.
# For offline review (no AWS access) see README: scripts/tf-check.sh dev
terraform {
  backend "s3" {
    bucket         = "hotelapp-dev-tfstate"
    key            = "dev/terraform.tfstate"
    region         = "ap-south-1"
    dynamodb_table = "hotelapp-dev-tflock"
    encrypt        = true
  }
}
