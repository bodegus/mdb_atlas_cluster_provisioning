#!/bin/bash

# Flexible Terraform destroy script with extended timeout
# Usage: ./tf_destroy_flexible.sh <deployment_directory> <tfvar_path> [timeout_seconds] [skip_confirmation]
#
# Exit codes:
#   0 - Destroy succeeded or no resources to destroy
#   1 - Destroy failed
#   2 - Unexpected error

# Don't exit immediately on command failures
set +e

DEPLOYMENT_DIR=${1}
TFVAR_PATH=${2}
TIMEOUT_SECONDS=${3:-600}  # Default to 10 minutes for destroy
SKIP_CONFIRMATION=${4:-false}

if [ -z "$DEPLOYMENT_DIR" ] || [ -z "$TFVAR_PATH" ]; then
    echo "Error: Deployment directory and tfvar path parameters are required"
    echo "Usage: ./tf_destroy_flexible.sh <deployment_directory> <tfvar_path> [timeout_seconds] [skip_confirmation]"
    echo "Example: ./tf_destroy_flexible.sh deploy_basic_cluster ./deploy_basic_cluster/dev.tfvars 600 true"
    exit 2
fi

# Convert to absolute paths
DEPLOYMENT_DIR=$(realpath "$DEPLOYMENT_DIR")
TFVAR_PATH=$(realpath "$TFVAR_PATH")

# Validate inputs
if [ ! -d "$DEPLOYMENT_DIR" ]; then
    echo "Error: Deployment directory does not exist: $DEPLOYMENT_DIR"
    exit 2
fi

if [ ! -f "$TFVAR_PATH" ]; then
    echo "Error: TFVars file does not exist: $TFVAR_PATH"
    exit 2
fi

if [ ! -d "$DEPLOYMENT_DIR/terraform" ]; then
    echo "Error: Terraform directory not found: $DEPLOYMENT_DIR/terraform"
    exit 2
fi

# Extract deployment name and environment
DEPLOYMENT_NAME=$(basename "$DEPLOYMENT_DIR")
TFVAR_FILENAME=$(basename "$TFVAR_PATH")
ENV_NAME="${TFVAR_FILENAME%.tfvars}"

echo "========================================="
echo "🗑️  Terraform Destroy (Flexible)"
echo "Deployment: $DEPLOYMENT_NAME"
echo "Environment: $ENV_NAME"
echo "TFVars: $TFVAR_PATH"
echo "Timeout: ${TIMEOUT_SECONDS} seconds"
echo "Skip Confirmation: $SKIP_CONFIRMATION"
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
    echo "⚠️  Warning: Terraform not initialized. Attempting to initialize for destroy..."

    # Try to initialize for destroy operations
    echo "📋 Retrieving state bucket from SSM..."
    BUCKET_NAME=$(aws ssm get-parameter \
        --name "/tfvalidations/sandbox/mongodb/pipeline_tf_state_bucket" \
        --with-decryption \
        --query "Parameter.Value" \
        --output text)

    if [ -z "$BUCKET_NAME" ]; then
        echo "❌ ERROR: Failed to retrieve state bucket from SSM parameter"
        echo "Expected parameter: /tfvalidations/sandbox/mongodb/pipeline_tf_state_bucket"
        exit 2
    fi

    PROJECT_NAME="mdb-atlas-cluster"
    STATE_KEY="${PROJECT_NAME}/${DEPLOYMENT_NAME}/${ENV_NAME}/terraform.tfstate"
    REGION="us-east-1"

    terraform init \
        -backend=true \
        -backend-config="bucket=${BUCKET_NAME}" \
        -backend-config="key=${STATE_KEY}" \
        -backend-config="region=${REGION}" \
        -backend-config="encrypt=true" \
        -reconfigure

    if [ $? -ne 0 ]; then
        echo "Error: Failed to initialize terraform for destroy"
        exit 2
    fi
fi

echo ""
echo "🔍 Checking for existing resources..."

# Check if there are any resources to destroy
terraform plan -destroy -var-file="$TFVAR_PATH" -out=destroy-plan > /dev/null 2>&1
PLAN_EXIT_CODE=$?

if [ $PLAN_EXIT_CODE -ne 0 ]; then
    echo "⚠️  Warning: Could not generate destroy plan. Checking state..."

    # Check if state file exists and has resources
    terraform show > /dev/null 2>&1
    if [ $? -ne 0 ]; then
        echo "ℹ️  No state file or resources found. Nothing to destroy."
        echo "✅ Destroy operation complete (nothing to destroy)"
        exit 0
    fi
fi

# For CI environments, skip confirmation
if [ "$SKIP_CONFIRMATION" = "true" ] || [ -n "$CI" ] || [ -n "$GITHUB_ACTIONS" ]; then
    echo "ℹ️  Running in automated environment - skipping confirmation"
else
    # Interactive confirmation
    echo ""
    echo "⚠️  WARNING: This will destroy all resources for:"
    echo "   Deployment: $DEPLOYMENT_NAME"
    echo "   Environment: $ENV_NAME"
    echo ""
    read -p "Are you sure you want to destroy these resources? Type 'yes' to confirm: " confirm

    if [ "$confirm" != "yes" ]; then
        echo "Destroy operation cancelled"
        exit 0
    fi
fi

echo ""
echo "🔄 Running Terraform destroy with timeout..."
echo "Working directory: $(pwd)"
echo "Variable file: $TFVAR_PATH"

# Create temporary file for output
DESTROY_OUTPUT=$(mktemp)
echo "Debug: Output will be saved to $DESTROY_OUTPUT"

# Run terraform destroy with timeout
echo "Starting terraform destroy with ${TIMEOUT_SECONDS}s timeout..."

# Use timeout command and capture both exit code and output
timeout "${TIMEOUT_SECONDS}s" terraform destroy -var-file="$TFVAR_PATH" -auto-approve > "$DESTROY_OUTPUT" 2>&1
DESTROY_EXIT_CODE=$?

echo "Terraform destroy completed with exit code: $DESTROY_EXIT_CODE"

# Show the terraform output
echo ""
echo "========================================="
echo "Terraform Destroy Output:"
echo "========================================="
cat "$DESTROY_OUTPUT"
echo "========================================="

# Analyze the results
if [ $DESTROY_EXIT_CODE -eq 0 ]; then
    # Destroy completed successfully
    echo ""
    echo "✅ DESTROY COMPLETED SUCCESSFULLY"
    echo "All resources have been destroyed."

    # Clean up plan files
    rm -f destroy-plan tfplan terraform.tfstate.backup.* 2>/dev/null || true

    rm "$DESTROY_OUTPUT"
    exit 0

elif [ $DESTROY_EXIT_CODE -eq 124 ]; then
    # Timeout occurred
    echo ""
    echo "⚠️  DESTROY TIMED OUT"
    echo "The destroy operation exceeded the ${TIMEOUT_SECONDS} second timeout."
    echo ""
    echo "This may indicate:"
    echo "  - Large number of resources to destroy"
    echo "  - Network connectivity issues"
    echo "  - MongoDB Atlas API performance issues"
    echo ""
    echo "Check the MongoDB Atlas console to verify resource status."

    rm "$DESTROY_OUTPUT"
    exit 1

else
    # Destroy failed for other reasons
    echo ""
    echo "❌ DESTROY FAILED"
    echo "Terraform destroy failed with exit code: $DESTROY_EXIT_CODE"

    # Check for common issues
    if grep -E "(Error|FATAL|failed)" "$DESTROY_OUTPUT" >/dev/null; then
        echo ""
        echo "Error details:"
        grep -A3 -B1 -E "(Error|FATAL|failed)" "$DESTROY_OUTPUT" | head -10
    fi

    # Check if resources were partially destroyed
    if grep -q "Destroy complete" "$DESTROY_OUTPUT"; then
        echo ""
        echo "✅ Some resources were destroyed successfully."
        echo "Check the output above for details on what remains."

        rm "$DESTROY_OUTPUT"
        exit 0
    fi

    echo ""
    echo "Last 20 lines of output:"
    tail -20 "$DESTROY_OUTPUT"

    rm "$DESTROY_OUTPUT"
    exit 1
fi
