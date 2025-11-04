# MongoDB Atlas Cluster Migration: REPLICASET to SHARDED

This example demonstrates how to migrate a MongoDB Atlas cluster from a REPLICASET configuration to a SHARDED configuration using Terraform while maintaining state continuity.

## Overview

MongoDB Atlas allows in-place migration from replica set clusters to sharded clusters. This example shows how to:
1. Deploy an initial REPLICASET cluster
2. Migrate the same cluster to SHARDED configuration
3. Maintain Terraform state continuity throughout the process

## Prerequisites

- MongoDB Atlas Project ID (set as `MONGODB_ATLAS_PROJECT_ID` environment variable)
- MongoDB Atlas API keys configured
- Terraform >= 1.6
- Access to MongoDB Atlas organization

## Directory Structure

```
11_migration_replica_to_sharded/
├── stage_1_replicaset/     # Initial REPLICASET configuration
│   ├── main.tf
│   ├── variables.tf
│   └── outputs.tf
├── stage_2_sharded/         # Target SHARDED configuration
│   ├── main.tf
│   ├── variables.tf
│   └── outputs.tf
├── migration.sh             # Automated migration script
└── README.md               # This file
```

## Key Concepts

### State Continuity
- Both stages use identical resource names (`random_string.suffix` and `module.cluster`)
- Terraform state is copied from stage_1 to stage_2 before migration
- This ensures Terraform recognizes it as an UPDATE rather than CREATE/DELETE

### MongoDB Requirements
- Sharded clusters require minimum M30 instance size
- Auto-scaling configuration must support sharding requirements
- Connection strings remain unchanged after migration

## Migration Process

### Automated Migration (Recommended)

Run the migration script which handles all steps:

```bash
./migration.sh
```

The script will:
1. Deploy the REPLICASET cluster (stage_1)
2. Copy Terraform state to stage_2
3. Show the planned changes for migration
4. Apply the migration to SHARDED configuration
5. Display verification instructions

### Manual Migration Steps

If you prefer to run the migration manually:

#### Step 1: Deploy REPLICASET Cluster
```bash
cd stage_1_replicaset
terraform init
terraform apply -var="project_id=${MONGODB_ATLAS_PROJECT_ID}"
```

#### Step 2: Prepare for Migration
```bash
# Copy state and provider data to stage_2
cp -r stage_1_replicaset/.terraform stage_2_sharded/
cp stage_1_replicaset/terraform.tfstate* stage_2_sharded/
```

#### Step 3: Plan Migration
```bash
cd ../stage_2_sharded
terraform init -reconfigure
terraform plan -var="project_id=${MONGODB_ATLAS_PROJECT_ID}"
```

Review the plan. Key changes should include:
- `cluster_type`: REPLICASET → SHARDED
- Addition of `shard_number` to region configuration
- Tag updates reflecting the new stage

#### Step 4: Apply Migration
```bash
terraform apply -var="project_id=${MONGODB_ATLAS_PROJECT_ID}"
```

## Configuration Changes

### Stage 1: REPLICASET
```hcl
cluster_type = "REPLICASET"
regions = [{
  name       = "US_EAST_1"
  node_count = 3
  # No shard_number for replica sets
}]
```

### Stage 2: SHARDED
```hcl
cluster_type = "SHARDED"
regions = [{
  name         = "US_EAST_1"
  node_count   = 3
  shard_number = 1  # Required for sharded clusters
}]
```

## Important Notes

1. **Instance Size**: Both configurations use M30 minimum (via auto_scaling) as sharding requires at least M30
2. **Downtime**: The migration typically happens with minimal to no downtime
3. **Connection Strings**: Applications don't need to update connection strings
4. **Rollback**: While possible, rolling back from SHARDED to REPLICASET is more complex
5. **State Management**: The state copy is critical - without it, Terraform would try to destroy and recreate

## Verification

After migration, verify the cluster:

1. **MongoDB Atlas UI**: Confirm cluster type shows as "SHARDED"
2. **Terraform State**: Run `terraform show` in stage_2_sharded
3. **Application Connectivity**: Test that applications can still connect
4. **Monitoring**: Check cluster metrics and performance

## Cleanup

To destroy the migrated cluster:

```bash
cd stage_2_sharded
terraform destroy -var="project_id=${MONGODB_ATLAS_PROJECT_ID}"
```

## Common Issues

### Issue: State Mismatch
**Solution**: Ensure you copy the state files before running terraform init in stage_2

### Issue: Minimum Instance Size Error
**Solution**: Sharding requires M30 minimum. The configuration uses auto_scaling with M30 as minimum

### Issue: Provider Authentication
**Solution**: Ensure MongoDB Atlas API keys are properly configured in your environment

## Learning Points

This example demonstrates:
- Terraform's ability to manage infrastructure evolution
- MongoDB Atlas's in-place migration capabilities
- State management best practices during infrastructure changes
- How to structure Terraform code for phased deployments
