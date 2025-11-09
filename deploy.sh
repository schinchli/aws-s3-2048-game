#!/bin/bash

# AWS S3 Static Website with CloudFront Deployment Script
# This script demonstrates the complete process of hosting a static website on AWS

set -e

# Configuration
BUCKET_NAME="2048-game-$(whoami)-$(date +%s)"
REGION="us-east-1"
PROFILE="default"

echo "🚀 Starting AWS S3 Static Website Deployment"
echo "Bucket Name: $BUCKET_NAME"
echo "Region: $REGION"

# Step 1: Create S3 Bucket
echo "📦 Step 1: Creating S3 bucket..."
aws s3 mb s3://$BUCKET_NAME --region $REGION --profile $PROFILE
echo "✅ Bucket created: $BUCKET_NAME"

# Step 2: Enable Static Website Hosting
echo "🌐 Step 2: Enabling static website hosting..."
aws s3 website s3://$BUCKET_NAME \
    --index-document index.html \
    --error-document error.html \
    --profile $PROFILE
echo "✅ Static website hosting enabled"

# Step 3: Configure Public Access Settings FIRST
echo "🔧 Step 3: Configuring public access settings..."
aws s3api put-public-access-block \
    --bucket $BUCKET_NAME \
    --public-access-block-configuration \
    "BlockPublicAcls=false,IgnorePublicAcls=false,BlockPublicPolicy=false,RestrictPublicBuckets=false" \
    --profile $PROFILE
echo "✅ Public access configured for website hosting"

# Step 4: Create Bucket Policy for Public Read Access
echo "🔓 Step 4: Setting bucket policy for public read access..."
cat > bucket-policy.json << EOF
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
    --policy file://bucket-policy.json \
    --profile $PROFILE
echo "✅ Bucket policy applied - Public read access enabled"

# Step 5: Upload Website Files
echo "📤 Step 5: Uploading website files..."
aws s3 sync . s3://$BUCKET_NAME \
    --exclude "*.sh" \
    --exclude "*.json" \
    --exclude "*.md" \
    --exclude ".git/*" \
    --profile $PROFILE
echo "✅ Website files uploaded"

# Step 6: Get S3 Website URL
S3_WEBSITE_URL="http://$BUCKET_NAME.s3-website-$REGION.amazonaws.com"
echo "🌐 S3 Website URL: $S3_WEBSITE_URL"

# Step 7: Test S3 Website
echo "🧪 Step 7: Testing S3 website..."
if curl -s -o /dev/null -w "%{http_code}" $S3_WEBSITE_URL | grep -q "200"; then
    echo "✅ S3 website is accessible"
else
    echo "❌ S3 website test failed"
fi

# Step 8: Create CloudFront Distribution
echo "☁️ Step 8: Creating CloudFront distribution..."
cat > cloudfront-config.json << EOF
{
    "CallerReference": "2048-game-$(date +%s)",
    "Comment": "CloudFront distribution for 2048 game",
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
    --distribution-config file://cloudfront-config.json \
    --profile $PROFILE)

DISTRIBUTION_ID=$(echo $DISTRIBUTION_OUTPUT | jq -r '.Distribution.Id')
CLOUDFRONT_DOMAIN=$(echo $DISTRIBUTION_OUTPUT | jq -r '.Distribution.DomainName')

echo "✅ CloudFront distribution created"
echo "Distribution ID: $DISTRIBUTION_ID"
echo "CloudFront Domain: $CLOUDFRONT_DOMAIN"

# Step 9: Wait for CloudFront deployment
echo "⏳ Step 9: Waiting for CloudFront deployment (this takes 15-20 minutes)..."
echo "You can check status with: aws cloudfront get-distribution --id $DISTRIBUTION_ID"

# Step 10: Create Origin Access Control (OAC) for better security
echo "🔒 Step 10: Setting up Origin Access Control..."
OAC_OUTPUT=$(aws cloudfront create-origin-access-control \
    --origin-access-control-config \
    "Name=OAC-$BUCKET_NAME,Description=OAC for $BUCKET_NAME,OriginAccessControlOriginType=s3,SigningBehavior=always,SigningProtocol=sigv4" \
    --profile $PROFILE)

OAC_ID=$(echo $OAC_OUTPUT | jq -r '.OriginAccessControl.Id')
echo "✅ Origin Access Control created: $OAC_ID"

# Clean up temporary files
rm -f bucket-policy.json cloudfront-config.json

echo ""
echo "🎉 Deployment Summary:"
echo "===================="
echo "S3 Bucket: $BUCKET_NAME"
echo "S3 Website URL: $S3_WEBSITE_URL"
echo "CloudFront Distribution ID: $DISTRIBUTION_ID"
echo "CloudFront URL: https://$CLOUDFRONT_DOMAIN"
echo ""
echo "📝 Next Steps:"
echo "1. Wait 15-20 minutes for CloudFront deployment"
echo "2. Test CloudFront URL: https://$CLOUDFRONT_DOMAIN"
echo "3. Update bucket policy to restrict access to CloudFront only (OAC)"
echo "4. Set up custom domain (optional)"
echo ""
echo "🔧 Useful Commands:"
echo "Check CloudFront status: aws cloudfront get-distribution --id $DISTRIBUTION_ID"
echo "Create invalidation: aws cloudfront create-invalidation --distribution-id $DISTRIBUTION_ID --paths '/*'"
echo "Delete resources: aws s3 rb s3://$BUCKET_NAME --force && aws cloudfront delete-distribution --id $DISTRIBUTION_ID"
