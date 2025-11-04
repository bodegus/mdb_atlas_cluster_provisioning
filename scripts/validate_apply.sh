#!/bin/bash

# Script to validate MongoDB Atlas cluster configuration by attempting terraform apply
# with a 30-second timeout. This validates API parameters without actually creating clusters.
#
# Exit codes:
#   0 - Validation passed (timeout occurred, meaning API accepted the configuration)
#   1 - Validation failed (API rejected the configuration)
#   2 - Unexpected error

ENV=${1}
EXAMPLE_DIR=${2:-basic_cluster_deploy}

if [ -z "$ENV" ]; then
    echo "Error: Environment parameter is required"
    echo "Usage: ../scripts/validate_apply.sh [dev|nonprod|prod] [example_dir]"
    exit 2
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/load_env.sh"

# IMPORTANT: Set this AFTER sourcing load_env.sh to override any 'set -e' it might contain
# We need to continue even when terraform fails (which is expected)
set +e

echo "========================================="
echo "MongoDB Atlas Cluster Validation"
echo "Environment: ${ENV}"
echo "Example: ${EXAMPLE_DIR}"
echo "========================================="

# Navigate to the example directory
cd "${SCRIPT_DIR}/../${EXAMPLE_DIR}"

VAR_FILE="../${ENV}.tfvars"

echo "Running Terraform init..."
cd terraform

# Initialize terraform with backend config
if ! terraform init -backend-config="key=${EXAMPLE_DIR}/${ENV}/terraform.tfstate" > /dev/null 2>&1; then
    echo "❌ ERROR: Terraform init failed"
    exit 2
fi

echo "Running Terraform plan..."
PLAN_OUTPUT=$(mktemp)
terraform plan -var-file="${VAR_FILE}" -out=tfplan > "${PLAN_OUTPUT}" 2>&1
PLANNED_NAME=$(grep -A5 'module.mongodb_cluster.mongodbatlas_advanced_cluster.this will be created' "${PLAN_OUTPUT}" | grep '+ name' | sed 's/.*= //' | tr -d '"')
if [ -n "${PLANNED_NAME}" ]; then
    echo "📋 Cluster name to be created: ${PLANNED_NAME}"
else
    echo "⚠️  Could not extract planned cluster name from plan output"
fi
rm "${PLAN_OUTPUT}"

echo ""
echo "Running Terraform apply with saved plan and 30s timeout..."
echo "This will validate the cluster configuration without creating resources."
echo "Working directory: $(pwd)"

# Capture terraform apply output and exit code
APPLY_OUTPUT=$(mktemp)

# Run terraform apply with the SAVED PLAN FILE to ensure same cluster name
# Use || true to ensure the script continues even if terraform fails
terraform apply tfplan > "${APPLY_OUTPUT}" 2>&1 || APPLY_EXIT_CODE=$?
# If terraform succeeded (unlikely with 30s timeout), APPLY_EXIT_CODE will be unset, so default to 0
APPLY_EXIT_CODE=${APPLY_EXIT_CODE:-0}

# Show the terraform output
cat "${APPLY_OUTPUT}"

# Extract and display the cluster name that was attempted
echo "========================================="
CLUSTER_NAME=$(grep -o "Cluster name [^ ]*" "${APPLY_OUTPUT}" | head -1 | cut -d' ' -f3)
if [ -z "${CLUSTER_NAME}" ]; then
    # Try alternative pattern for cluster name
    CLUSTER_NAME=$(grep -o "cluster=\([^ ]*\)" "${APPLY_OUTPUT}" | head -1 | cut -d'=' -f2)
fi
if [ -z "${CLUSTER_NAME}" ]; then
    # Try to find it in the plan output
    CLUSTER_NAME=$(grep -o '"name".*=.*"[^"]*"' "${APPLY_OUTPUT}" | head -1 | sed 's/.*"\([^"]*\)"$/\1/')
fi
if [ -n "${CLUSTER_NAME}" ]; then
    echo "🔍 Attempted cluster name: ${CLUSTER_NAME}"
else
    echo "⚠️  Could not extract cluster name from output"
fi
echo "========================================="

# Analyze the output to determine validation result
if [ ${APPLY_EXIT_CODE} -eq 0 ]; then
    echo "⚠️ Unexpected success - cluster creation should have timed out"
    echo "This might indicate the timeout is not properly configured"
    rm "${APPLY_OUTPUT}"
    exit 2
fi

# Check for timeout (validation passed)
if grep -q "context deadline exceeded" "${APPLY_OUTPUT}"; then
    echo "========================================="
    echo "✅ VALIDATION PASSED"
    echo "The MongoDB Atlas API accepted the cluster configuration."
    echo "The operation timed out as expected after 30 seconds."
    echo "========================================="
    rm "${APPLY_OUTPUT}"
    rm -f tfplan
    exit 0
fi

# Check for API validation errors (validation failed)
if grep -E "(HTTP 400 Bad Request|HTTP 401|HTTP 403|HTTP 404|Error code:)" "${APPLY_OUTPUT}"; then
    echo "========================================="
    echo "❌ VALIDATION FAILED"
    echo "The MongoDB Atlas API rejected the cluster configuration."
    echo ""
    echo "Error details:"
    grep -A2 -B2 "Error" "${APPLY_OUTPUT}" | tail -20
    echo "========================================="
    rm "${APPLY_OUTPUT}"
    rm -f tfplan
    exit 1
fi

# Check for other known validation failures
if grep -q "Error in create" "${APPLY_OUTPUT}"; then
    # Extract the specific error message
    ERROR_MSG=$(grep -A5 "Error in create" "${APPLY_OUTPUT}")

    # Check if it's a non-timeout error
    if ! echo "${ERROR_MSG}" | grep -q "context deadline exceeded"; then
        echo "========================================="
        echo "❌ VALIDATION FAILED"
        echo "Cluster creation failed with API validation error:"
        echo ""
        echo "${ERROR_MSG}"
        echo "========================================="
        rm "${APPLY_OUTPUT}"
        exit 1
    fi
fi

# Unknown error
echo "========================================="
echo "⚠️  UNEXPECTED ERROR"
echo "Could not determine validation result."
echo "Exit code: ${APPLY_EXIT_CODE}"
echo ""
echo "Last 50 lines of output:"
tail -50 "${APPLY_OUTPUT}"
echo "========================================="
rm "${APPLY_OUTPUT}"
rm -f tfplan
exit 2
