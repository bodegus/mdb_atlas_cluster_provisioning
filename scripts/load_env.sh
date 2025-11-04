#!/bin/bash

set -e

echo "Loading MongoDB Atlas credentials and project information"

PUBLIC_KEY=$(aws ssm get-parameter --name "/tfvalidations/sandbox/mongodb/atlas_public_key" --with-decryption --query 'Parameter.Value' --output text 2>/dev/null)
if [ $? -ne 0 ]; then
    echo "Error: Failed to retrieve MongoDB public key from SSM"
    exit 1
fi

PRIVATE_KEY=$(aws ssm get-parameter --name "/tfvalidations/sandbox/mongodb/atlas_private_key" --with-decryption --query 'Parameter.Value' --output text 2>/dev/null)
if [ $? -ne 0 ]; then
    echo "Error: Failed to retrieve MongoDB private key from SSM"
    exit 1
fi

export MONGODB_ATLAS_PUBLIC_KEY="${PUBLIC_KEY}"
export MONGODB_ATLAS_PRIVATE_KEY="${PRIVATE_KEY}"

echo "MongoDB Atlas credentials loaded successfully"

# Get project information from Atlas using API keys
echo "Fetching MongoDB Atlas project information"

# Use direct API call with the API keys from SSM
echo "Calling MongoDB Atlas API to list projects..."
PROJECTS_JSON=$(curl -s --user "${MONGODB_ATLAS_PUBLIC_KEY}:${MONGODB_ATLAS_PRIVATE_KEY}" \
    --digest \
    --header "Accept: application/json" \
    --header "Content-Type: application/json" \
    "https://cloud.mongodb.com/api/atlas/v1.0/groups")
CURL_EXIT_CODE=$?

if [ $CURL_EXIT_CODE -ne 0 ]; then
    echo "Error: curl command failed with exit code ${CURL_EXIT_CODE}"
    exit 1
fi

if [ -z "$PROJECTS_JSON" ]; then
    echo "Error: Empty response from MongoDB Atlas API"
    exit 1
fi

# Check if response contains an error
if echo "$PROJECTS_JSON" | grep -q '"error"'; then
    echo "Error: MongoDB Atlas API returned an error:"
    echo "$PROJECTS_JSON" | jq -r '.error'
    exit 1
fi

# Validate there is exactly one project
PROJECT_COUNT=$(echo "$PROJECTS_JSON" | jq '.results | length')
if [ "$PROJECT_COUNT" -ne 1 ]; then
    echo "Error: Expected exactly 1 MongoDB Atlas project, found ${PROJECT_COUNT}"
    exit 1
fi

# Get the project ID
PROJECT_ID=$(echo "$PROJECTS_JSON" | jq -r '.results[0].id')
if [ -z "$PROJECT_ID" ]; then
    echo "Error: Failed to extract project ID"
    exit 1
fi

export TF_VAR_project_id="${PROJECT_ID}"

echo "MongoDB Atlas project ID loaded: ${PROJECT_ID}"
