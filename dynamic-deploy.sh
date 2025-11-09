#!/bin/bash

# Dynamic AWS S3 Static Website Deployment Script
# Supports multiple environments and dynamic resource creation

set -e

# Configuration
ENVIRONMENT=${1:-"dev"}
USER_ID=$(whoami)
TIMESTAMP=$(date +%s)
BUCKET_NAME="2048-game-${USER_ID}-${ENVIRONMENT}-${TIMESTAMP}"
REGION="us-east-1"
PROFILE="default"

echo "🚀 Dynamic AWS S3 Static Website Deployment"
echo "Environment: $ENVIRONMENT"
echo "Bucket Name: $BUCKET_NAME"
echo "Region: $REGION"
echo "User: $USER_ID"

# Step 1: Create S3 Bucket
echo "📦 Creating S3 bucket..."
aws s3 mb s3://$BUCKET_NAME --region $REGION --profile $PROFILE

# Step 2: Enable Static Website Hosting
echo "🌐 Enabling static website hosting..."
aws s3 website s3://$BUCKET_NAME \
    --index-document index.html \
    --error-document error.html \
    --profile $PROFILE

# Step 3: Configure Public Access
echo "🔧 Configuring public access..."
aws s3api put-public-access-block \
    --bucket $BUCKET_NAME \
    --public-access-block-configuration \
    "BlockPublicAcls=false,IgnorePublicAcls=false,BlockPublicPolicy=false,RestrictPublicBuckets=false" \
    --profile $PROFILE

# Step 4: Apply Bucket Policy
echo "🔓 Setting bucket policy..."
cat > bucket-policy-${ENVIRONMENT}.json << EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "PublicReadGetObject",
            "Effect": "Allow",
            "Principal": "*",
            "Action": "s3:GetObject",
            "Resource": "arn:aws:s3:::$BUCKET_NAME/*"
        }
    ]
}
EOF

aws s3api put-bucket-policy \
    --bucket $BUCKET_NAME \
    --policy file://bucket-policy-${ENVIRONMENT}.json \
    --profile $PROFILE

# Step 5: Upload Files
echo "📤 Uploading website files..."
aws s3 sync . s3://$BUCKET_NAME \
    --exclude "*.sh" \
    --exclude "*.json" \
    --exclude "*.md" \
    --exclude ".git/*" \
    --profile $PROFILE

# Step 6: Create CloudFront Distribution
echo "☁️ Creating CloudFront distribution..."
cat > cloudfront-config-${ENVIRONMENT}.json << EOF
{
    "CallerReference": "2048-game-${ENVIRONMENT}-${TIMESTAMP}",
    "Comment": "CloudFront distribution for 2048 game - ${ENVIRONMENT}",
    "DefaultCacheBehavior": {
        "TargetOriginId": "$BUCKET_NAME-origin",
        "ViewerProtocolPolicy": "redirect-to-https",
        "MinTTL": 0,
        "ForwardedValues": {
            "QueryString": false,
            "Cookies": {
                "Forward": "none"
            }
        },
        "TrustedSigners": {
            "Enabled": false,
            "Quantity": 0
        }
    },
    "Origins": {
        "Quantity": 1,
        "Items": [
            {
                "Id": "$BUCKET_NAME-origin",
                "DomainName": "$BUCKET_NAME.s3-website-$REGION.amazonaws.com",
                "CustomOriginConfig": {
                    "HTTPPort": 80,
                    "HTTPSPort": 443,
                    "OriginProtocolPolicy": "http-only"
                }
            }
        ]
    },
    "Enabled": true,
    "DefaultRootObject": "index.html",
    "PriceClass": "PriceClass_100"
}
EOF

DISTRIBUTION_OUTPUT=$(aws cloudfront create-distribution \
    --distribution-config file://cloudfront-config-${ENVIRONMENT}.json \
    --profile $PROFILE)

DISTRIBUTION_ID=$(echo $DISTRIBUTION_OUTPUT | jq -r '.Distribution.Id')
CLOUDFRONT_DOMAIN=$(echo $DISTRIBUTION_OUTPUT | jq -r '.Distribution.DomainName')

# Step 7: Create OAC
echo "🔒 Setting up Origin Access Control..."
OAC_OUTPUT=$(aws cloudfront create-origin-access-control \
    --origin-access-control-config \
    "Name=OAC-$BUCKET_NAME,Description=OAC for $BUCKET_NAME,OriginAccessControlOriginType=s3,SigningBehavior=always,SigningProtocol=sigv4" \
    --profile $PROFILE)

OAC_ID=$(echo $OAC_OUTPUT | jq -r '.OriginAccessControl.Id')

# Step 8: Save deployment info
cat > deployment-${ENVIRONMENT}.json << EOF
{
    "environment": "$ENVIRONMENT",
    "bucket_name": "$BUCKET_NAME",
    "s3_website_url": "http://$BUCKET_NAME.s3-website-$REGION.amazonaws.com",
    "cloudfront_distribution_id": "$DISTRIBUTION_ID",
    "cloudfront_domain": "$CLOUDFRONT_DOMAIN",
    "cloudfront_url": "https://$CLOUDFRONT_DOMAIN",
    "oac_id": "$OAC_ID",
    "region": "$REGION",
    "created_at": "$(date -u +%Y-%m-%dT%H:%M:%SZ)"
}
EOF

# Clean up temporary files
rm -f bucket-policy-${ENVIRONMENT}.json cloudfront-config-${ENVIRONMENT}.json

echo ""
echo "🎉 Dynamic Deployment Complete!"
echo "Environment: $ENVIRONMENT"
echo "S3 Website: http://$BUCKET_NAME.s3-website-$REGION.amazonaws.com"
echo "CloudFront: https://$CLOUDFRONT_DOMAIN"
echo "Deployment info saved to: deployment-${ENVIRONMENT}.json"
