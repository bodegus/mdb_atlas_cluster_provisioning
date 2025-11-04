#!/bin/bash

set -e

ENV=${1}

if [ -z "$ENV" ]; then
    echo "Error: Environment parameter is required"
    echo "Usage: ../scripts/tf_plan.sh [dev|nonprod|prod]"
    exit 1
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/load_env.sh"

CURRENT_DIR=$(pwd)
EXAMPLE_NAME=$(basename "$CURRENT_DIR")

VAR_FILE="../${ENV}.tfvars"

echo "Running Terraform plan for environment: ${ENV}"
echo "Example: ${EXAMPLE_NAME}"
echo "Variable file: ${VAR_FILE}"

cd terraform

terraform plan -var-file="${VAR_FILE}"

echo ""
echo "Terraform plan complete for ${ENV} environment"
