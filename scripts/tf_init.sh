#!/bin/bash

set -e

ENV=${1}

if [ -z "$ENV" ]; then
    echo "Error: Environment parameter is required"
    echo "Usage: ../scripts/tf_init.sh [dev|nonprod|prod]"
    exit 1
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/load_env.sh"

CURRENT_DIR=$(pwd)
EXAMPLE_NAME=$(basename "$CURRENT_DIR")

echo "Initializing Terraform for environment: ${ENV}"
echo "Example: ${EXAMPLE_NAME}"

# Determine run ID based on environment
if [ -n "$GITHUB_RUN_ID" ]; then
    # Running in GitHub Actions - use remote state with run isolation
    echo "🔍 Detected CI environment (GitHub Actions)"
    echo "Run ID: $GITHUB_RUN_ID"
    RUN_ID="$GITHUB_RUN_ID"
else
    # Running locally
    echo "🏠 Detected local environment"
    RUN_ID="LOCAL"
fi

# Get bucket based on environment
if [ "$RUN_ID" = "LOCAL" ]; then
    # Local environment - use production bucket
    echo "📋 Retrieving production bucket from SSM..."
    BUCKET_NAME=$(aws ssm get-parameter \
        --name "/tfvalidations/sandbox/mongodb/pipeline_tf_state_bucket" \
        --with-decryption \
        --query "Parameter.Value" \
        --output text)

    if [ -z "$BUCKET_NAME" ]; then
        echo "❌ ERROR: Failed to retrieve state bucket from SSM parameter"
        echo "Expected parameter: /tfvalidations/sandbox/mongodb/pipeline_tf_state_bucket"
        exit 1
    fi

    PROJECT_NAME="mdb-atlas-cluster"
    STATE_KEY="${PROJECT_NAME}/${EXAMPLE_NAME}/${ENV}/terraform.tfstate"
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
    STATE_KEY="${PROJECT_NAME}/${EXAMPLE_NAME}/${ENV}/${RUN_ID}/terraform.tfstate"
fi

REGION="us-east-1"

echo "🔧 Configuring Terraform backend..."
echo "Backend S3 Bucket: ${BUCKET_NAME}"
echo "State Key: ${STATE_KEY}"
echo "Region: ${REGION}"

cd terraform

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

echo "Terraform initialization complete for ${ENV} environment"
