#!/bin/bash

set -e

MODULE_NUM=${1}

if [ -z "$MODULE_NUM" ]; then
    echo "Error: Module number is required"
    echo "Usage: ./tf_init.sh [module_number]"
    echo ""
    echo "Available modules:"
    for dir in $(ls -d [0-9][0-9]_* 2>/dev/null | sort); do
        module_num=$(echo $dir | cut -d'_' -f1)
        module_name=$(echo $dir | cut -d'_' -f2-)
        echo "  $module_num - $module_name"
    done
    exit 1
fi

# Load environment
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../scripts/load_env.sh"

# Find the module directory that starts with the given number
MODULE_DIR=$(ls -d "${SCRIPT_DIR}"/${MODULE_NUM}_* 2>/dev/null | head -1 | xargs basename 2>/dev/null || true)

if [ -z "$MODULE_DIR" ]; then
    echo "Error: No module found matching number: ${MODULE_NUM}"
    echo ""
    echo "Available modules:"
    for dir in $(ls -d "${SCRIPT_DIR}"/[0-9][0-9]_* 2>/dev/null | sort); do
        module_num=$(basename $dir | cut -d'_' -f1)
        module_name=$(basename $dir | cut -d'_' -f2-)
        echo "  $module_num - $module_name"
    done
    exit 1
fi

PROJECT_NAME="mdb-atlas-module-examples"
BUCKET_NAME="alex-johansson-apix-tf-state"
STATE_KEY="${PROJECT_NAME}/${MODULE_DIR}/terraform.tfstate"
REGION="us-east-1"

echo "Initializing Terraform for module: ${MODULE_DIR}"
echo "Backend S3 Bucket: ${BUCKET_NAME}"
echo "State Key: ${STATE_KEY}"

cd "${SCRIPT_DIR}/${MODULE_DIR}"

# Clean up state-related files only, preserve provider/module cache
echo "🧹 Cleaning up Terraform state files..."
rm -f terraform.tfstate* tfplan 2>/dev/null || true
rm -f .terraform/terraform.tfstate 2>/dev/null || true
rm -f .terraform/environment 2>/dev/null || true
# Note: Keeping .terraform/providers and .terraform/modules to avoid re-downloading

terraform init \
    -backend=true \
    -backend-config="bucket=${BUCKET_NAME}" \
    -backend-config="key=${STATE_KEY}" \
    -backend-config="region=${REGION}" \
    -backend-config="encrypt=true" \
    -reconfigure

echo "Terraform initialization complete for module ${MODULE_DIR}"
