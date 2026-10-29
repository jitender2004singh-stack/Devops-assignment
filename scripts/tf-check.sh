#!/usr/bin/env bash
# Runs the Terraform review checks for one environment WITHOUT AWS access:
#   fmt -> init -> validate -> plan -refresh=false
#
# The real S3 backend needs AWS credentials, so this script temporarily swaps it for
# a local backend (backend_override.tf) and uses a throw-away TF_DATA_DIR. Your
# committed backend.tf and any real `.terraform` directory are left untouched.
#
# Usage: ./scripts/tf-check.sh dev|prod
set -euo pipefail

ENV_NAME="${1:?usage: $0 dev|prod}"
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ENV_DIR="$ROOT_DIR/infra/envs/$ENV_NAME"

if [ ! -d "$ENV_DIR" ]; then
  echo "ERROR: unknown environment '$ENV_NAME' (expected dev or prod)" >&2
  exit 1
fi
if ! command -v terraform > /dev/null 2>&1; then
  echo "ERROR: terraform is not installed (https://developer.hashicorp.com/terraform/install)" >&2
  exit 1
fi

export TF_DATA_DIR="$ENV_DIR/.terraform-offline"
export TF_IN_AUTOMATION=1
cleanup() {
  rm -rf "$ENV_DIR/backend_override.tf" "$ENV_DIR/offline.tfstate" "$TF_DATA_DIR"
}
trap cleanup EXIT

echo "==> terraform fmt (all of infra/)"
terraform -chdir="$ROOT_DIR/infra" fmt -check -recursive -diff

cat > "$ENV_DIR/backend_override.tf" <<'EOF'
terraform {
  backend "local" {
    path = "offline.tfstate"
  }
}
EOF

cd "$ENV_DIR"

echo "==> terraform init ($ENV_NAME, local backend)"
terraform init -input=false

echo "==> terraform validate ($ENV_NAME)"
terraform validate

echo "==> terraform plan -refresh=false ($ENV_NAME)"
terraform plan -refresh=false -input=false -no-color | tee "$ROOT_DIR/plan-$ENV_NAME.txt"

echo
echo "Plan saved to plan-$ENV_NAME.txt"
