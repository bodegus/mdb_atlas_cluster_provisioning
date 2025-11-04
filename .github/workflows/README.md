# GitHub Actions Workflows

This directory contains 4 GitHub Actions workflows that support MongoDB Atlas cluster provisioning and management.

## Workflows Overview

### 1. MongoDB Atlas Cluster Deployment (`mongodb-cluster-deploy.yml`)

**Purpose**: Manual deployment workflow for MongoDB Atlas clusters across environments

**Trigger**: Manual dispatch only (`workflow_dispatch`)

**Key Features**:
- **Environment Selection**: Choose from dev, nonprod, or prod
- **Action Selection**: Plan, apply, or destroy operations
- **AWS Integration**: Uses OIDC for secure AWS authentication
- **MongoDB Atlas CLI**: Installs and configures Atlas CLI for cluster management
- **Working Directory**: Operates on `basic_cluster_deploy/` example

**Capabilities**:
- Terraform initialization with environment-specific backends
- Plan generation for review
- Infrastructure deployment (apply)
- Resource cleanup (destroy with confirmation)
- Detailed output display and job summaries

**Security**: Uses AWS role assumption with proper OIDC authentication

---

### 2. MongoDB Atlas Cluster Validation (`mongodb-cluster-validation.yml`)

**Purpose**: Automated validation of MongoDB Atlas configurations across all environments and cluster types

**Trigger**:
- Push to any branch affecting cluster configurations
- Manual dispatch

**Key Features**:
- **Matrix Strategy**: Tests all combinations of environments (dev, nonprod, prod) and cluster types (basic_cluster_deploy, verbose_cluster_deploy, module_of_modules)
- **Fail-Fast Disabled**: Continues testing even if one combination fails
- **Timeout-Based Validation**: Uses 30-second timeouts to verify API acceptance without creating actual clusters
- **Smart Exit Code Handling**: Distinguishes between validation success (timeout expected) and actual failures

**Working Directory**: Uses `scripts/validate_apply.sh` for validation logic

**Output**: Comprehensive summary showing which configurations passed/failed validation

---

### 3. Terraform Plan Simple (`terraform-plan-simple.yml`)

**Purpose**: Simple Terraform validation for foundation infrastructure

**Trigger**:
- Pull requests to main branch affecting `deployments/` directory
- Manual dispatch

**Key Features**:
- **Foundation Focus**: Specifically targets `deployments/01-foundation` directory
- **Basic Validation**: Runs init, validate, and plan operations
- **Legacy Configuration**: Uses older Terraform version (~1.0) and different directory structure

**Security**: Uses AWS OIDC authentication with empty profile configuration

**Note**: This appears to be for a different deployment pattern than the main MongoDB cluster workflows

---

### 4. Test AWS OIDC Access (`test-aws-access.yml`)

**Purpose**: Continuous verification of AWS authentication setup

**Trigger**:
- Push to main or develop branches
- Pull requests to main branch
- Manual dispatch

**Key Features**:
- **Authentication Testing**: Verifies AWS OIDC integration is working
- **Lightweight**: Quick test using `aws sts get-caller-identity`
- **Broad Trigger**: Runs on most code changes to catch auth issues early

**Security**: Minimal permissions - only tests credential access

---

## Workflow Dependencies

### Required Secrets
- `AWS_ROLE_ARN`: IAM role ARN for GitHub Actions OIDC authentication

### Required Permissions
- `id-token: write` - For OIDC token generation
- `contents: read` - For repository access
- `pull-requests: write` - For PR comments and status updates

### AWS Setup
All workflows expect:
- Configured AWS OIDC identity provider
- IAM role with appropriate MongoDB Atlas and AWS permissions
- MongoDB Atlas API keys stored in AWS SSM Parameter Store

## Usage Patterns

### Development Workflow
1. **Development**: Push changes trigger validation workflow
2. **Review**: Use simple plan workflow for foundation changes
3. **Deployment**: Manual deployment workflow for controlled releases
4. **Monitoring**: AWS access test ensures authentication remains functional

### Security Considerations
- All workflows use OIDC instead of long-lived credentials
- Destroy operations require manual confirmation
- Matrix validation prevents environment-specific configuration drift
- Separate validation prevents accidental resource creation during testing

## Recommendations for Improvement

1. **Consolidation**: Consider merging similar workflows to reduce complexity
2. **Consistent Versioning**: Standardize Terraform versions across workflows
3. **Enhanced Security**: Add approval requirements for production deployments
4. **Better Error Handling**: Improve failure notifications and recovery procedures
5. **Artifact Management**: Consider storing plan files for apply workflows
