#!/bin/bash

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Get the directory of this script
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Track if cluster was created
CLUSTER_CREATED=false

# Cleanup function that runs on any exit
cleanup() {
    local exit_code=$?

    if [ "$CLUSTER_CREATED" = true ]; then
        echo ""
        echo -e "${YELLOW}=== Cleanup Process ===${NC}"

        if [ $exit_code -eq 0 ]; then
            echo -e "${GREEN}Migration completed successfully. Proceeding with cleanup...${NC}"
        else
            echo -e "${RED}Migration failed or was interrupted. Starting cleanup...${NC}"
        fi

        echo ""
        read -p "Destroy the cluster and clean up? (yes/no): " confirm
        if [ "$confirm" != "yes" ]; then
            echo "Cleanup skipped. You can manually destroy later with:"
            echo "  cd stage_2_sharded && terraform destroy (if migration reached stage 2)"
            echo "  cd stage_1_replicaset && terraform destroy (if only stage 1 was deployed)"
            exit $exit_code
        fi

        # Try to destroy from stage_2 first (in case migration was partially successful)
        if [ -f "${SCRIPT_DIR}/stage_2_sharded/terraform.tfstate" ]; then
            echo -e "${YELLOW}Destroying cluster from stage_2_sharded...${NC}"
            cd "${SCRIPT_DIR}/stage_2_sharded"
            if [ -n "${TF_VAR_project_id}" ]; then
                terraform destroy -var="project_id=${TF_VAR_project_id}" -auto-approve || true
            else
                terraform destroy -auto-approve || true
            fi
        elif [ -f "${SCRIPT_DIR}/stage_1_replicaset/terraform.tfstate" ]; then
            echo -e "${YELLOW}Destroying cluster from stage_1_replicaset...${NC}"
            cd "${SCRIPT_DIR}/stage_1_replicaset"
            if [ -n "${TF_VAR_project_id}" ]; then
                terraform destroy -var="project_id=${TF_VAR_project_id}" -auto-approve || true
            else
                terraform destroy -auto-approve || true
            fi
        fi

        # Clean up state files
        echo -e "${YELLOW}Cleaning up Terraform state files...${NC}"
        rm -f "${SCRIPT_DIR}/stage_1_replicaset/terraform.tfstate"*
        rm -f "${SCRIPT_DIR}/stage_2_sharded/terraform.tfstate"*
        rm -rf "${SCRIPT_DIR}/stage_1_replicaset/.terraform"
        rm -rf "${SCRIPT_DIR}/stage_2_sharded/.terraform"

        echo ""
        if [ $exit_code -eq 0 ]; then
            echo -e "${GREEN}=== Cleanup Complete! ===${NC}"
            echo "The demonstration cluster has been destroyed and state files cleaned up."
        else
            echo -e "${YELLOW}=== Cleanup Attempted ===${NC}"
            echo "Cleanup process completed. Some resources may need manual verification."
        fi
    fi

    exit $exit_code
}

# Set trap to run cleanup on any exit
trap cleanup EXIT

# Load environment variables if load_env.sh exists
if [ -f "${SCRIPT_DIR}/../../scripts/load_env.sh" ]; then
    source "${SCRIPT_DIR}/../../scripts/load_env.sh"
fi

echo -e "${GREEN}=== MongoDB Atlas Cluster Migration: REPLICASET to SHARDED ===${NC}"
echo ""

# Function to run terraform commands
run_terraform() {
    local stage=$1
    local action=$2

    echo -e "${YELLOW}Running terraform ${action} in ${stage}...${NC}"
    cd "${SCRIPT_DIR}/${stage}"

    if [ -n "${TF_VAR_project_id}" ]; then
        terraform ${action} -var="project_id=${TF_VAR_project_id}" ${@:3}
    else
        terraform ${action} ${@:3}
    fi

    cd "${SCRIPT_DIR}"
}

# Step 1: Deploy Stage 1 (REPLICASET)
echo -e "${GREEN}Step 1: Deploying Stage 1 - REPLICASET Cluster${NC}"
echo "This will create a new MongoDB Atlas cluster as a REPLICASET."
read -p "Continue? (yes/no): " confirm
if [ "$confirm" != "yes" ]; then
    echo "Migration cancelled."
    exit 0
fi

# Initialize and apply stage 1
cd "${SCRIPT_DIR}/stage_1_replicaset"
terraform init
run_terraform "stage_1_replicaset" "apply" "-auto-approve"

echo -e "${GREEN}✓ Stage 1 deployed successfully!${NC}"
CLUSTER_CREATED=true
echo ""

# Step 2: Prepare for migration
echo -e "${GREEN}Step 2: Preparing for migration to SHARDED${NC}"
echo "We will now copy the Terraform state to Stage 2 directory."
echo "This simulates an in-place upgrade scenario."
read -p "Continue with migration? (yes/no): " confirm
if [ "$confirm" != "yes" ]; then
    echo "Migration cancelled."
    exit 0
fi

# Copy terraform state and provider data to stage 2
echo "Copying Terraform state and configuration..."
cp -r "${SCRIPT_DIR}/stage_1_replicaset/.terraform" "${SCRIPT_DIR}/stage_2_sharded/"
cp "${SCRIPT_DIR}/stage_1_replicaset/terraform.tfstate" "${SCRIPT_DIR}/stage_2_sharded/" 2>/dev/null || true
cp "${SCRIPT_DIR}/stage_1_replicaset/terraform.tfstate.backup" "${SCRIPT_DIR}/stage_2_sharded/" 2>/dev/null || true

# Step 3: Plan the migration
echo -e "${GREEN}Step 3: Planning migration to SHARDED${NC}"
echo "Terraform will show what changes will be made to convert to sharded cluster."
echo ""

cd "${SCRIPT_DIR}/stage_2_sharded"
terraform init -reconfigure

echo -e "${YELLOW}Running terraform plan to show migration changes...${NC}"
if [ -n "${TF_VAR_project_id}" ]; then
    terraform plan -var="project_id=${TF_VAR_project_id}"
else
    terraform plan
fi

echo ""
echo -e "${YELLOW}Review the plan above. Key changes should include:${NC}"
echo "  - cluster_type: REPLICASET → SHARDED"
echo "  - Addition of shard_number to region configuration"
echo ""
read -p "Apply the migration to SHARDED? (yes/no): " confirm
if [ "$confirm" != "yes" ]; then
    echo "Migration cancelled."
    exit 0
fi

# Step 4: Apply the migration
echo -e "${GREEN}Step 4: Applying migration to SHARDED${NC}"
run_terraform "stage_2_sharded" "apply" "-auto-approve"

echo ""
echo -e "${GREEN}=== Migration Complete! ===${NC}"
echo "Your cluster has been successfully migrated from REPLICASET to SHARDED."
echo ""
echo "To verify the migration:"
echo "  1. Check the MongoDB Atlas UI to confirm cluster type is SHARDED"
echo "  2. Run: cd stage_2_sharded && terraform show"
echo "  3. Connection strings remain the same for your applications"
echo ""
echo -e "${YELLOW}Note: This migration demonstrated Terraform's ability to manage${NC}"
echo -e "${YELLOW}infrastructure evolution while maintaining state continuity.${NC}"
echo ""
echo -e "${YELLOW}The cleanup process will now begin to destroy the demonstration cluster...${NC}"
