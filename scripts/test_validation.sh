#!/bin/bash

# Test script to verify the validation logic with sample outputs

echo "Testing MongoDB Atlas Cluster Validation Logic"
echo "============================================="

# Create temporary test files
TIMEOUT_OUTPUT=$(mktemp)
API_ERROR_OUTPUT=$(mktemp)
OTHER_ERROR_OUTPUT=$(mktemp)

# Test Case 1: Timeout (should PASS validation)
cat > "${TIMEOUT_OUTPUT}" << 'EOF'
module.mongodb_cluster.mongodbatlas_advanced_cluster.this: Creating...
╷
│ Warning: Failed to create resource. Will run cleanup due to the operation timing out
│
│   with module.mongodb_cluster.mongodbatlas_advanced_cluster.this,
│   on .terraform/modules/mongodb_cluster/main.tf line 119, in resource "mongodbatlas_advanced_cluster" "this":
│  119: resource "mongodbatlas_advanced_cluster" "this" {
│
│ Cluster name test-cluster-prod-aaa111 (project_id=111a1a11aaa11aaa11111111).
╵
╷
│ Error: Error in create
│
│   with module.mongodb_cluster.mongodbatlas_advanced_cluster.this,
│   on .terraform/modules/mongodb_cluster/main.tf line 119, in resource "mongodbatlas_advanced_cluster" "this":
│  119: resource "mongodbatlas_advanced_cluster" "this" {
│
│ cluster=test-cluster-prod-aaa111 didn't reach desired state: IDLE, error: context deadline exceeded
EOF

# Test Case 2: API Validation Error (should FAIL validation)
cat > "${API_ERROR_OUTPUT}" << 'EOF'
module.mongodb_cluster.mongodbatlas_advanced_cluster.this: Creating...
╷
│ Error: Error in create
│
│   with module.mongodb_cluster.mongodbatlas_advanced_cluster.this,
│   on .terraform/modules/mongodb_cluster/main.tf line 119, in resource "mongodbatlas_advanced_cluster" "this":
│  119: resource "mongodbatlas_advanced_cluster" "this" {
│
│ cluster name: test-cluster-dev-aaa111, API error details: https://cloud.mongodb.com/api/atlas/v2/groups/111a1a11aaa11aaa11111111/clusters POST: HTTP 400 Bad Request
│ (Error code: "COMPUTE_AUTO_SCALING_MIN_INSTANCE_SIZE_INVALID_FOR_DISABLED") Detail: Compute auto-scaling min instance size must be unset when scale down is disabled.
│ Reason: Bad Request. Params: [], BadRequestDetail:
╵
EOF

# Test Case 3: Other error
cat > "${OTHER_ERROR_OUTPUT}" << 'EOF'
Error: Backend initialization required, please run "terraform init"
EOF

echo "Test 1: Timeout Error (Expected: PASS)"
echo "---------------------------------------"
if grep -q "context deadline exceeded" "${TIMEOUT_OUTPUT}"; then
    echo "✅ Correctly identified as timeout - validation should PASS"
else
    echo "❌ Failed to identify timeout"
fi

echo ""
echo "Test 2: API Validation Error (Expected: FAIL)"
echo "---------------------------------------------"
if grep -E "(HTTP 400 Bad Request|Error code:)" "${API_ERROR_OUTPUT}"; then
    echo "✅ Correctly identified as API error - validation should FAIL"
else
    echo "❌ Failed to identify API error"
fi

echo ""
echo "Test 3: Check both conditions don't overlap"
echo "-------------------------------------------"
if grep -q "context deadline exceeded" "${API_ERROR_OUTPUT}"; then
    echo "❌ API error incorrectly matches timeout pattern"
else
    echo "✅ API error does not match timeout pattern"
fi

if grep -E "(HTTP 400 Bad Request|Error code:)" "${TIMEOUT_OUTPUT}"; then
    echo "❌ Timeout error incorrectly matches API error pattern"
else
    echo "✅ Timeout error does not match API error pattern"
fi

echo ""
echo "Test 4: Other errors (Expected: UNKNOWN/ERROR)"
echo "----------------------------------------------"
if grep -q "context deadline exceeded" "${OTHER_ERROR_OUTPUT}"; then
    echo "❌ Other error incorrectly matches timeout pattern"
elif grep -E "(HTTP 400 Bad Request|Error code:)" "${OTHER_ERROR_OUTPUT}"; then
    echo "❌ Other error incorrectly matches API error pattern"
else
    echo "✅ Other error correctly identified as unknown"
fi

# Cleanup
rm "${TIMEOUT_OUTPUT}" "${API_ERROR_OUTPUT}" "${OTHER_ERROR_OUTPUT}"

echo ""
echo "============================================="
echo "Validation logic test complete!"
