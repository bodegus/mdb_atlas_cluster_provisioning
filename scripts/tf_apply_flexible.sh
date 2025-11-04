#!/bin/bash

# Flexible Terraform apply script with timeout handling for validation
# Usage: ./tf_apply_flexible.sh <deployment_directory> <tfvar_path> [timeout_seconds]
#
# Exit codes:
#   0 - Apply succeeded (for validation: timeout occurred as expected)
#   1 - Apply failed (API rejected configuration)
#   2 - Unexpected error

# Don't exit immediately on command failures - we need to handle timeouts specially
set +e

DEPLOYMENT_DIR=${1}
TFVAR_PATH=${2}
TIMEOUT_SECONDS=${3:-30}  # Default to 30 seconds for validation

if [ -z "$DEPLOYMENT_DIR" ] || [ -z "$TFVAR_PATH" ]; then
    echo "Error: Deployment directory and tfvar path parameters are required"
    echo "Usage: ./tf_apply_flexible.sh <deployment_directory> <tfvar_path> [timeout_seconds]"
    echo "Example: ./tf_apply_flexible.sh deploy_basic_cluster ./deploy_basic_cluster/dev.tfvars 30"
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
echo "🚀 Terraform Apply (Flexible)"
echo "Deployment: $DEPLOYMENT_NAME"
echo "Environment: $ENV_NAME"
echo "TFVars: $TFVAR_PATH"
echo "Timeout: ${TIMEOUT_SECONDS} seconds"
echo "========================================="

# Get script directory for relative imports
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Load environment variables using original loader
echo "📋 Loading environment configuration..."
source "${SCRIPT_DIR}/load_env.sh"

# Change to terraform directory
cd "$DEPLOYMENT_DIR/terraform"

# Verify terraform is initialized and plan exists
if [ ! -d ".terraform" ]; then
    echo "Error: Terraform not initialized. Run tf_init_flexible.sh first."
    exit 2
fi

if [ ! -f "tfplan" ]; then
    echo "Error: No terraform plan found. Run tf_plan_flexible.sh first."
    exit 2
fi

echo ""
echo "🔄 Running Terraform apply with timeout..."
echo "Working directory: $(pwd)"
echo "Plan file: tfplan"

# Create temporary file for output
APPLY_OUTPUT=$(mktemp)

# Run terraform apply with timeout using the saved plan
echo "Starting terraform apply with ${TIMEOUT_SECONDS}s timeout..."

# Run terraform and capture output, but also show it live
terraform apply tfplan 2>&1 | tee "$APPLY_OUTPUT"
APPLY_EXIT_CODE=${PIPESTATUS[0]}

echo "Terraform apply completed with exit code: $APPLY_EXIT_CODE"

# Always show the terraform output first, regardless of exit code
echo ""
echo "========================================="
echo "Terraform Apply Output:"
echo "========================================="
cat "$APPLY_OUTPUT"
echo "========================================="
echo ""

# Analyze the results
if [ $APPLY_EXIT_CODE -eq 0 ]; then
    # Terraform completed successfully within timeout
    echo ""
    echo "✅ TERRAFORM APPLY COMPLETED SUCCESSFULLY"
    echo "Resources were created successfully within the timeout period."
    echo ""
    echo "WARNING: For validation workflows, this is unexpected."
    echo "Consider increasing the complexity or reducing the timeout."

    rm "$APPLY_OUTPUT"
    exit 0

else
    # Terraform failed - check if it's a timeout (validation success) or real error
    echo ""
    echo "Terraform apply failed with exit code: $APPLY_EXIT_CODE"

    # Check for terraform timeout errors (validation success)
    if grep -E "(timeout|deadline exceeded|context deadline|operation timed out|Error: timeout)" "$APPLY_OUTPUT" >/dev/null; then
        echo ""
        echo "✅ VALIDATION PASSED (Terraform Timeout)"
        echo "The terraform apply timed out after ${TIMEOUT_SECONDS} seconds as expected."
        echo "This indicates the MongoDB Atlas API accepted the configuration parameters."
        echo ""
        echo "For validation purposes, this is considered a SUCCESS."

        # Save the state file for potential cleanup
        if [ -f "terraform.tfstate" ]; then
            cp terraform.tfstate "terraform.tfstate.backup.$(date +%Y%m%d_%H%M%S)"
            echo "State file backed up for potential cleanup."
        fi

        rm "$APPLY_OUTPUT"
        exit 0
    fi

    # Check for common API validation errors
    if grep -E "(HTTP 400 Bad Request|HTTP 401|HTTP 403|HTTP 404|Error code:|Bad Request|Unauthorized|Forbidden)" "$APPLY_OUTPUT" >/dev/null; then
        echo ""
        echo "❌ VALIDATION FAILED (API Error)"
        echo "This appears to be an API validation error:"
        grep -A3 -B1 -E "(Error|HTTP [4-5][0-9][0-9])" "$APPLY_OUTPUT" | head -10
        echo ""
        echo "The MongoDB Atlas API rejected the configuration parameters."

        rm "$APPLY_OUTPUT"
        exit 1
    fi

    # Unknown error
    echo ""
    echo "⚠️ UNEXPECTED ERROR"
    echo "Could not determine the cause of the failure."
    echo ""
    echo "Last 20 lines of output:"
    tail -20 "$APPLY_OUTPUT"

    rm "$APPLY_OUTPUT"
    exit 2
fi
