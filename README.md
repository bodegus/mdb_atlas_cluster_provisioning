# mdb_atlas_cluster_provisioning
reference for deploying MongoDB Atlas clusters with terraform at scale

## GitHub Actions - Workflow Commands

Use GitHub CLI (`gh`) to trigger the MongoDB Atlas cluster workflows:

### Trigger Validations

The validation workflow automatically runs on push and validates all cluster types across all environments:
- **Cluster Types**: `basic_cluster_deploy`, `verbose_cluster_deploy`, `module_of_modules`
- **Environments**: `dev`, `nonprod`, `prod`
- **Matrix**: Runs 9 validation jobs (3 cluster types × 3 environments)

```bash
# Manually trigger validation (runs all cluster types and environments)
gh workflow run mongodb-cluster-validation.yml

# View validation results
gh run list --workflow=mongodb-cluster-validation.yml

# Watch validation in real-time
gh run watch --workflow=mongodb-cluster-validation.yml
```

### Trigger Deployments

```bash
# Plan changes for dev environment
gh workflow run mongodb-cluster-deploy.yml \
  --field environment=dev \
  --field action=plan

# Apply changes for dev environment
gh workflow run mongodb-cluster-deploy.yml \
  --field environment=dev \
  --field action=apply

# Plan for nonprod environment
gh workflow run mongodb-cluster-deploy.yml \
  --field environment=nonprod \
  --field action=plan

# Apply for nonprod environment
gh workflow run mongodb-cluster-deploy.yml \
  --field environment=nonprod \
  --field action=apply

# Plan for prod environment
gh workflow run mongodb-cluster-deploy.yml \
  --field environment=prod \
  --field action=plan

# Apply for prod environment
gh workflow run mongodb-cluster-deploy.yml \
  --field environment=prod \
  --field action=apply

# Destroy resources (use with caution!)
gh workflow run mongodb-cluster-deploy.yml \
  --field environment=dev \
  --field action=destroy
```

### Batch Operations

Run operations for all environments or cluster types:

```bash
# Run validation for all cluster types and environments
gh workflow run mongodb-cluster-validation.yml

# Deploy to all environments (requires running each separately)
for env in dev nonprod prod; do
  echo "Planning for $env..."
  gh workflow run mongodb-cluster-deploy.yml \
    --field environment=$env \
    --field action=plan
done

# Apply to specific environments
for env in dev nonprod; do
  echo "Applying changes for $env..."
  gh workflow run mongodb-cluster-deploy.yml \
    --field environment=$env \
    --field action=apply
done
```

### Monitor Workflow Runs

```bash
# List recent deployment runs
gh run list --workflow=mongodb-cluster-deploy.yml

# List recent validation runs
gh run list --workflow=mongodb-cluster-validation.yml

# List all workflow runs
gh run list

# Watch the latest run in real-time
gh run watch

# View a specific run
gh run view <run-id>

# View logs for a specific run
gh run view <run-id> --log

# Re-run a failed workflow
gh run rerun <run-id>

# Cancel a running workflow
gh run cancel <run-id>
```

### Check Workflow Status

```bash
# Get status of the latest run
gh run list --workflow=mongodb-cluster-deploy.yml --limit 1

# Get all runs for a specific environment (using jq)
gh run list --workflow=mongodb-cluster-deploy.yml --json displayTitle,status,conclusion | \
  jq '.[] | select(.displayTitle | contains("dev"))'

# Get runs with specific status
gh run list --workflow=mongodb-cluster-deploy.yml --status failure
gh run list --workflow=mongodb-cluster-deploy.yml --status in_progress
gh run list --workflow=mongodb-cluster-deploy.yml --status completed
```

### Interactive Mode

```bash
# Select and view a run interactively
gh run list --workflow=mongodb-cluster-deploy.yml | head -10
gh run view  # Will prompt you to select from recent runs

# Watch logs interactively
gh run watch  # Will prompt you to select a running workflow
```

## Local Development

From the `basic_cluster_deploy/` directory:

```bash
# Initialize Terraform for an environment
../scripts/tf_init.sh dev

# Run Terraform plan
../scripts/tf_plan.sh dev

# Apply changes
../scripts/tf_apply.sh dev

# Destroy resources
../scripts/tf_destroy.sh dev

# Clean up Terraform files
../scripts/tf_clean.sh
```

## Required GitHub Secrets

Configure the following secrets in your GitHub repository:
- `AWS_ROLE_ARN`: The IAM role ARN for GitHub Actions to assume

## Prerequisites

- GitHub CLI installed and authenticated: `brew install gh && gh auth login`
- AWS CLI configured with appropriate profiles
- MongoDB Atlas API keys stored in AWS SSM:
  - `/tfvalidations/sandbox/mongodb/atlas_public_key`
  - `/tfvalidations/sandbox/mongodb/atlas_private_key`
- Terraform >= 1.0
