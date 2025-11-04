#!/bin/bash

# Flexible Terraform initialization script
# Usage: ./tf_init_flexible.sh <deployment_directory> <tfvar_path>

set -e

DEPLOYMENT_DIR=${1}
TFVAR_PATH=${2}

if [ -z "$DEPLOYMENT_DIR" ] || [ -z "$TFVAR_PATH" ]; then
    echo "Error: Both deployment directory and tfvar path parameters are required"
    echo "Usage: ./tf_init_flexible.sh <deployment_directory> <tfvar_path>"
    echo "Example: ./tf_init_flexible.sh deploy_basic_cluster ./deploy_basic_cluster/dev.tfvars"
    exit 1
fi

# Convert to absolute paths (macOS compatible)
DEPLOYMENT_DIR=$(cd "$DEPLOYMENT_DIR" && pwd)
TFVAR_PATH=$(cd "$(dirname "$TFVAR_PATH")" && pwd)/$(basename "$TFVAR_PATH")

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
echo "🚀 Terraform Initialization (Flexible)"
echo "Deployment: $DEPLOYMENT_NAME"
echo "Environment: $ENV_NAME"
echo "TFVars: $TFVAR_PATH"
echo "========================================="

# Get script directory for relative imports
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Load environment variables using original loader
echo "📋 Loading environment configuration..."
source "${SCRIPT_DIR}/load_env.sh"

# Run pre-commit hooks for this deployment
echo ""
echo "🔍 Running pre-commit hooks..."
"${SCRIPT_DIR}/run_pre_commit.sh" "$DEPLOYMENT_DIR"

# Determine run ID based on environment
if [ -n "$GITHUB_RUN_ID" ]; then
    # Running in GitHub Actions - use remote state with run isolation
    echo ""
    echo "🔍 Detected CI environment (GitHub Actions)"
    echo "Run ID: $GITHUB_RUN_ID"
    RUN_ID="$GITHUB_RUN_ID"
else
    # Running locally
    echo ""
    echo "🏠 Detected local environment"
    RUN_ID="LOCAL"
fi

# Get bucket based on environment
if [ "$RUN_ID" = "LOCAL" ]; then
    # Local environment - use local backend
    USE_REMOTE_BACKEND=false
else
    # CI environment - use validation bucket with run isolation
    echo "📋 Retrieving validation bucket from SSM..."
    BUCKET_NAME=$(aws ssm get-parameter \
        --name "/tfvalidations/sandbox/mongodb/pipeline_tf_state_bucket" \
        --with-decryption \
        --query "Parameter.Value" \
        --output text)

    if [ -z "$BUCKET_NAME" ]; then
        echo "❌ ERROR: Failed to retrieve validation bucket from SSM parameter"
        echo "Expected parameter: /tfvalidations/sandbox/mongodb/pipeline_tf_state_bucket"
        exit 1
    fi

    PROJECT_NAME="mdb-atlas-cluster-validation"
    STATE_KEY="${PROJECT_NAME}/${DEPLOYMENT_NAME}/${ENV_NAME}/${RUN_ID}/terraform.tfstate"
    REGION="us-east-1"
    USE_REMOTE_BACKEND=true
fi

echo ""
if [ "$USE_REMOTE_BACKEND" = "true" ]; then
    echo "🔧 Configuring Terraform remote backend..."
    echo "Backend S3 Bucket: ${BUCKET_NAME}"
    echo "State Key: ${STATE_KEY}"
    echo "Region: ${REGION}"
else
    echo "🔧 Configuring Terraform local backend..."
fi

# Change to terraform directory
cd "$DEPLOYMENT_DIR/terraform"

# Clean up state-related files only, preserve provider/module cache
echo ""
echo "🧹 Cleaning up previous Terraform state files..."
rm -f terraform.tfstate* tfplan* 2>/dev/null || true
rm -f .terraform/terraform.tfstate 2>/dev/null || true
rm -f .terraform/environment 2>/dev/null || true
# Note: Keeping .terraform/providers and .terraform/modules to avoid re-downloading

# Initialize terraform
echo ""
if [ "$USE_REMOTE_BACKEND" = "true" ]; then
    echo "🔄 Initializing Terraform with remote backend..."
    terraform init \
        -backend=true \
        -backend-config="bucket=${BUCKET_NAME}" \
        -backend-config="key=${STATE_KEY}" \
        -backend-config="region=${REGION}" \
        -backend-config="encrypt=true" \
        -reconfigure
else
    echo "🔄 Initializing Terraform with local backend..."
    terraform init -backend=false -reconfigure
fi

echo ""
echo "✅ Terraform initialization complete!"
echo "Deployment: $DEPLOYMENT_NAME"
echo "Environment: $ENV_NAME"
echo "Working directory: $(pwd)"
