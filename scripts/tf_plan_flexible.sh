#!/bin/bash

# Flexible Terraform plan script
# Usage: ./tf_plan_flexible.sh <deployment_directory> <tfvar_path>

set -e

DEPLOYMENT_DIR=${1}
TFVAR_PATH=${2}

if [ -z "$DEPLOYMENT_DIR" ] || [ -z "$TFVAR_PATH" ]; then
    echo "Error: Both deployment directory and tfvar path parameters are required"
    echo "Usage: ./tf_plan_flexible.sh <deployment_directory> <tfvar_path>"
    echo "Example: ./tf_plan_flexible.sh deploy_basic_cluster ./deploy_basic_cluster/dev.tfvars"
    exit 1
fi

# Convert to absolute paths
DEPLOYMENT_DIR=$(realpath "$DEPLOYMENT_DIR")
TFVAR_PATH=$(realpath "$TFVAR_PATH")

# Validate inputs
if [ ! -d "$DEPLOYMENT_DIR" ]; then
    echo "Error: Deployment directory does not exist: $DEPLOYMENT_DIR"
    exit 1
fi

if [ ! -f "$TFVAR_PATH" ]; then
    echo "Error: TFVars file does not exist: $TFVAR_PATH"
    exit 1
fi

if [ ! -d "$DEPLOYMENT_DIR/terraform" ]; then
    echo "Error: Terraform directory not found: $DEPLOYMENT_DIR/terraform"
    exit 1
fi

# Extract deployment name and environment
DEPLOYMENT_NAME=$(basename "$DEPLOYMENT_DIR")
TFVAR_FILENAME=$(basename "$TFVAR_PATH")
ENV_NAME="${TFVAR_FILENAME%.tfvars}"

echo "========================================="
echo "📋 Terraform Plan (Flexible)"
echo "Deployment: $DEPLOYMENT_NAME"
echo "Environment: $ENV_NAME"
echo "TFVars: $TFVAR_PATH"
echo "========================================="

# Get script directory for relative imports
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Load environment variables using original loader
echo "📋 Loading environment configuration..."
source "${SCRIPT_DIR}/load_env.sh"

# Change to terraform directory
cd "$DEPLOYMENT_DIR/terraform"

# Verify terraform is initialized
if [ ! -d ".terraform" ]; then
    echo "Error: Terraform not initialized. Run tf_init_flexible.sh first."
    exit 1
fi

echo ""
echo "🔄 Running Terraform plan..."
echo "Working directory: $(pwd)"
echo "Variable file: $TFVAR_PATH"

# Run terraform plan with the specified tfvars file
terraform plan -var-file="$TFVAR_PATH" -out=tfplan

echo ""
echo "✅ Terraform plan complete!"
echo "Plan saved to: tfplan"
echo "Deployment: $DEPLOYMENT_NAME"
echo "Environment: $ENV_NAME"
