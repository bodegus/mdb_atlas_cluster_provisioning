#!/bin/bash

set -e

MODULE_NUM=${1}

if [ -z "$MODULE_NUM" ]; then
    echo "Error: Module number is required"
    echo "Usage: ./tf_plan.sh [module_number]"
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

echo "Running Terraform plan for module: ${MODULE_DIR}"

cd "${SCRIPT_DIR}/${MODULE_DIR}"

# Check if terraform has been initialized
if [ ! -d ".terraform" ]; then
    echo "Error: Terraform not initialized. Please run './tf_init.sh ${MODULE_NUM}' first"
    exit 1
fi

# Use project_id from environment if available
if [ -n "${MONGODB_ATLAS_PROJECT_ID}" ]; then
    terraform plan -var="project_id=${MONGODB_ATLAS_PROJECT_ID}"
else
    terraform plan
fi

echo ""
echo "Terraform plan complete for module ${MODULE_DIR}"
