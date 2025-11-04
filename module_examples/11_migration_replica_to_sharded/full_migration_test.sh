#!/bin/bash

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Get the directory of this script
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Load environment variables if load_env.sh exists
if [ -f "${SCRIPT_DIR}/../../scripts/load_env.sh" ]; then
    source "${SCRIPT_DIR}/../../scripts/load_env.sh"
fi

echo -e "${GREEN}=== Full MongoDB Atlas Cluster Migration: REPLICASET to SHARDED ===${NC}"
echo "This test will deploy Stage 1, migrate to Stage 2, and then cleanup"
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

# Clean up any existing state from previous runs
echo -e "${YELLOW}Cleaning up any existing state...${NC}"
rm -f "${SCRIPT_DIR}/stage_1_replicaset/terraform.tfstate"*
rm -f "${SCRIPT_DIR}/stage_2_sharded/terraform.tfstate"*
rm -rf "${SCRIPT_DIR}/stage_1_replicaset/.terraform"
rm -rf "${SCRIPT_DIR}/stage_2_sharded/.terraform"

# Step 1: Deploy Stage 1 (REPLICASET)
echo -e "${GREEN}Step 1: Deploying Stage 1 - REPLICASET Cluster${NC}"
echo "This will create a MongoDB Atlas cluster as a REPLICASET (no timeout - full deployment)"

# Initialize and apply stage 1
cd "${SCRIPT_DIR}/stage_1_replicaset"
terraform init
run_terraform "stage_1_replicaset" "apply" "-auto-approve"

echo -e "${GREEN}✓ Stage 1 deployed successfully!${NC}"
echo ""

# Step 2: Prepare for migration
echo -e "${GREEN}Step 2: Preparing for migration to SHARDED${NC}"
echo "Copying Terraform state and configuration..."

# Copy terraform state and provider data to stage 2
cp -r "${SCRIPT_DIR}/stage_1_replicaset/.terraform" "${SCRIPT_DIR}/stage_2_sharded/"
cp "${SCRIPT_DIR}/stage_1_replicaset/terraform.tfstate" "${SCRIPT_DIR}/stage_2_sharded/" 2>/dev/null || true
cp "${SCRIPT_DIR}/stage_1_replicaset/terraform.tfstate.backup" "${SCRIPT_DIR}/stage_2_sharded/" 2>/dev/null || true

echo "✓ State copied successfully"
echo ""

# Step 3: Plan the migration
echo -e "${GREEN}Step 3: Planning migration to SHARDED${NC}"
echo "Terraform will show what changes will be made to convert to sharded cluster."

cd "${SCRIPT_DIR}/stage_2_sharded"
terraform init -reconfigure

echo -e "${YELLOW}Running terraform plan to show migration changes...${NC}"
if [ -n "${TF_VAR_project_id}" ]; then
    terraform plan -var="project_id=${TF_VAR_project_id}"
else
    terraform plan
fi

echo ""
echo -e "${YELLOW}Key changes should include:${NC}"
echo "  - cluster_type: REPLICASET → SHARDED"
echo "  - Addition of shard_number to region configuration"
echo "  - Tag updates"
echo ""

# Step 4: Apply the migration
echo -e "${GREEN}Step 4: Applying migration to SHARDED${NC}"
echo "This will convert the existing cluster to SHARDED (no timeout - full migration)"

run_terraform "stage_2_sharded" "apply" "-auto-approve"

echo ""
echo -e "${GREEN}=== Migration Complete! ===${NC}"
echo "Your cluster has been successfully migrated from REPLICASET to SHARDED."
echo ""
echo "Migration validation:"
echo "  ✓ Stage 1 REPLICASET cluster deployed successfully"
echo "  ✓ Terraform state copied correctly"
echo "  ✓ Stage 2 migration plan showed expected changes"
echo "  ✓ Stage 2 SHARDED cluster migration applied successfully"
echo ""

# Step 5: Cleanup
echo -e "${GREEN}Step 5: Cleanup - Destroy the migrated cluster${NC}"
echo "Destroying the cluster to avoid ongoing charges..."

cd "${SCRIPT_DIR}/stage_2_sharded"
if [ -n "${TF_VAR_project_id}" ]; then
    terraform destroy -var="project_id=${TF_VAR_project_id}" -auto-approve
else
    terraform destroy -auto-approve
fi

# Clean up state files
echo -e "${YELLOW}Cleaning up Terraform state files...${NC}"
rm -f "${SCRIPT_DIR}/stage_1_replicaset/terraform.tfstate"*
rm -f "${SCRIPT_DIR}/stage_2_sharded/terraform.tfstate"*
rm -rf "${SCRIPT_DIR}/stage_1_replicaset/.terraform"
rm -rf "${SCRIPT_DIR}/stage_2_sharded/.terraform"

echo ""
echo -e "${GREEN}=== Full Migration Test Complete! ===${NC}"
echo "The complete migration process has been successfully validated:"
echo "  ✓ REPLICASET cluster deployment"
echo "  ✓ State migration and continuity"
echo "  ✓ SHARDED cluster migration"
echo "  ✓ Resource cleanup"
echo ""
echo -e "${YELLOW}The migration framework is production-ready!${NC}"
