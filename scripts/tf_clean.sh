#!/bin/bash

set -e

echo "Cleaning up Terraform files"

CURRENT_DIR=$(pwd)

# Clean terraform directory
if [ -d "terraform/.terraform" ]; then
    echo "Cleaning terraform/.terraform directory"
    rm -rf terraform/.terraform
    rm -f terraform/.terraform.lock.hcl
    rm -f terraform/tfplan
    rm -f terraform/terraform.tfstate*
fi

echo "Cleanup complete"
