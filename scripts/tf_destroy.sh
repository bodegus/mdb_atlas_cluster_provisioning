#!/bin/bash

set -e

ENV=${1}

if [ -z "$ENV" ]; then
    echo "Error: Environment parameter is required"
    echo "Usage: ../scripts/tf_destroy.sh [dev|nonprod|prod]"
    exit 1
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/load_env.sh"

CURRENT_DIR=$(pwd)
EXAMPLE_NAME=$(basename "$CURRENT_DIR")

VAR_FILE="../${ENV}.tfvars"

echo "WARNING: This will destroy all resources for environment: ${ENV}"
echo "Example: ${EXAMPLE_NAME}"
echo "Variable file: ${VAR_FILE}"
echo ""
read -p "Are you sure you want to destroy these resources? Type 'yes' to confirm: " confirm

if [ "$confirm" != "yes" ]; then
    echo "Destroy operation cancelled"
    exit 0
fi

cd terraform

terraform destroy -var-file="${VAR_FILE}" -auto-approve

echo "Terraform destroy complete for ${ENV} environment"
