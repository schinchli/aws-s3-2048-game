#!/bin/bash

# Teardown AWS S3 Static Website Infrastructure
# Cleans up all resources created by deployment scripts

set -e

ENVIRONMENT=${1:-"dev"}
PROFILE="default"

echo "🧹 Tearing down AWS S3 Static Website Infrastructure"
echo "Environment: $ENVIRONMENT"

# Check if deployment info exists
if [ ! -f "deployment-${ENVIRONMENT}.json" ]; then
    echo "❌ No deployment info found for environment: $ENVIRONMENT"
    echo "Looking for existing resources..."
    
    # Try to find resources by pattern
    echo "🔍 Searching for S3 buckets..."
    aws s3 ls --profile $PROFILE | grep "2048-game-$(whoami)" || echo "No matching buckets found"
    
    echo "🔍 Searching for CloudFront distributions..."
    aws cloudfront list-distributions --profile $PROFILE \
        --query "DistributionList.Items[?contains(Comment, '2048 game')].{Id:Id,Domain:DomainName,Comment:Comment}" \
        --output table || echo "No matching distributions found"
    
    exit 1
fi

# Read deployment info
BUCKET_NAME=$(jq -r '.bucket_name' deployment-${ENVIRONMENT}.json)
DISTRIBUTION_ID=$(jq -r '.cloudfront_distribution_id' deployment-${ENVIRONMENT}.json)
OAC_ID=$(jq -r '.oac_id' deployment-${ENVIRONMENT}.json)

echo "Bucket: $BUCKET_NAME"
echo "Distribution: $DISTRIBUTION_ID"
echo "OAC: $OAC_ID"

# Step 1: Delete S3 bucket contents and bucket
echo "🗑️ Deleting S3 bucket and contents..."
aws s3 rb s3://$BUCKET_NAME --force --profile $PROFILE
echo "✅ S3 bucket deleted"

# Step 2: Disable and delete CloudFront distribution
echo "🌐 Disabling CloudFront distribution..."
DIST_CONFIG=$(aws cloudfront get-distribution-config --id $DISTRIBUTION_ID --profile $PROFILE)
ETAG=$(echo $DIST_CONFIG | jq -r '.ETag')

# Create disabled config
echo $DIST_CONFIG | jq '.DistributionConfig.Enabled = false' > disabled-config.json

# Update distribution to disabled
aws cloudfront update-distribution \
    --id $DISTRIBUTION_ID \
    --distribution-config file://disabled-config.json \
    --if-match $ETAG \
    --profile $PROFILE

echo "⏳ Waiting for distribution to be disabled..."
aws cloudfront wait distribution-deployed --id $DISTRIBUTION_ID --profile $PROFILE

# Get new ETag and delete
DIST_CONFIG=$(aws cloudfront get-distribution-config --id $DISTRIBUTION_ID --profile $PROFILE)
ETAG=$(echo $DIST_CONFIG | jq -r '.ETag')

aws cloudfront delete-distribution \
    --id $DISTRIBUTION_ID \
    --if-match $ETAG \
    --profile $PROFILE

echo "✅ CloudFront distribution deleted"

# Step 3: Delete Origin Access Control
echo "🔒 Deleting Origin Access Control..."
aws cloudfront delete-origin-access-control \
    --id $OAC_ID \
    --profile $PROFILE
echo "✅ OAC deleted"

# Clean up files
rm -f disabled-config.json deployment-${ENVIRONMENT}.json

echo ""
echo "🎉 Teardown Complete!"
echo "All resources for environment '$ENVIRONMENT' have been deleted."
