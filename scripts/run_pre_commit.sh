#!/bin/bash

# Script to run pre-commit hooks scoped to a specific directory
# Usage: ./run_pre_commit.sh <deployment_directory>

set -e

DEPLOYMENT_DIR=${1}

if [ -z "$DEPLOYMENT_DIR" ]; then
    echo "Error: Deployment directory parameter is required"
    echo "Usage: ./run_pre_commit.sh <deployment_directory>"
    exit 1
fi

# Convert to absolute path (macOS compatible)
DEPLOYMENT_DIR=$(cd "$DEPLOYMENT_DIR" && pwd)

if [ ! -d "$DEPLOYMENT_DIR" ]; then
    echo "Error: Directory $DEPLOYMENT_DIR does not exist"
    exit 1
fi

echo "🔍 Running pre-commit hooks for deployment: $(basename "$DEPLOYMENT_DIR")"
echo "Directory: $DEPLOYMENT_DIR"

# Get the project root (where .pre-commit-config.yaml is located)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

# Check if pre-commit is available
if ! command -v pre-commit &> /dev/null; then
    echo "⚠️  Warning: pre-commit not found, skipping pre-commit checks"
    echo "Install with: pip install pre-commit"
    exit 0
fi

# Check if .pre-commit-config.yaml exists
if [ ! -f "$PROJECT_ROOT/.pre-commit-config.yaml" ]; then
    echo "⚠️  Warning: .pre-commit-config.yaml not found in project root, skipping pre-commit checks"
    exit 0
fi

cd "$PROJECT_ROOT"

# Get all files in the deployment directory (relative to project root)
# Calculate relative path manually for macOS compatibility
REL_DEPLOYMENT_DIR=${DEPLOYMENT_DIR#$PROJECT_ROOT/}
FILES=$(find "$REL_DEPLOYMENT_DIR" -type f \( -name "*.tf" -o -name "*.tfvars" -o -name "*.yaml" -o -name "*.yml" -o -name "*.json" \) 2>/dev/null || true)

if [ -z "$FILES" ]; then
    echo "ℹ️  No relevant files found for pre-commit checks"
    exit 0
fi

echo "📋 Files to check:"
echo "$FILES" | sed 's/^/  - /'

# Run specific pre-commit hooks that are relevant for Terraform
HOOKS_TO_RUN=(
    "trailing-whitespace"
    "end-of-file-fixer"
    "check-yaml"
    "check-json"
    "check-merge-conflict"
    "detect-private-key"
    "terraform_fmt"
    "terraform_validate"
)

echo ""
echo "🚀 Running pre-commit hooks..."

# Track if any hooks failed (but don't exit immediately)
FAILED_HOOKS=()

for HOOK in "${HOOKS_TO_RUN[@]}"; do
    echo ""
    echo "Running $HOOK..."

    if echo "$FILES" | xargs pre-commit run "$HOOK" --files 2>/dev/null; then
        echo "✅ $HOOK passed"
    else
        echo "⚠️  $HOOK had issues"
        FAILED_HOOKS+=("$HOOK")
    fi
done

echo ""
echo "========================================="
if [ ${#FAILED_HOOKS[@]} -eq 0 ]; then
    echo "✅ All pre-commit checks passed!"
    exit 0
else
    echo "⚠️  Some pre-commit hooks had issues:"
    printf '  - %s\n' "${FAILED_HOOKS[@]}"
    echo ""
    echo "Note: Pre-commit issues are reported but don't fail the validation"
    echo "Please review and fix these issues in future commits"
    exit 0  # Don't fail the overall validation for pre-commit issues
fi
