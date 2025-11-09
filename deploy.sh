#!/bin/bash
set -e

BUCKET_NAME="2048-game-$(whoami)-$(date +%s)"
REGION="us-east-1"

echo "🚀 Deploying 2048 Game to AWS S3 + CloudFront"
echo "Bucket: $BUCKET_NAME"

# Create S3 bucket
aws s3 mb s3://$BUCKET_NAME --region $REGION

# Enable static website hosting
aws s3 website s3://$BUCKET_NAME --index-document index.html --error-document error.html

# Configure public access
aws s3api put-public-access-block --bucket $BUCKET_NAME \
    --public-access-block-configuration "BlockPublicAcls=false,IgnorePublicAcls=false,BlockPublicPolicy=false,RestrictPublicBuckets=false"

# Set bucket policy
cat > policy.json << EOF
{
    "Version": "2012-10-17",
    "Statement": [{
        "Effect": "Allow",
        "Principal": "*",
        "Action": "s3:GetObject",
        "Resource": "arn:aws:s3:::$BUCKET_NAME/*"
    }]
}
EOF

aws s3api put-bucket-policy --bucket $BUCKET_NAME --policy file://policy.json

# Upload files
aws s3 sync . s3://$BUCKET_NAME --exclude "*.sh" --exclude "*.json" --exclude "*.md" --exclude ".git/*"

# Create CloudFront distribution
cat > cf-config.json << EOF
{
    "CallerReference": "$(date +%s)",
    "Comment": "2048 Game CDN",
    "DefaultCacheBehavior": {
        "TargetOriginId": "$BUCKET_NAME",
        "ViewerProtocolPolicy": "redirect-to-https",
        "MinTTL": 0,
        "ForwardedValues": {"QueryString": false, "Cookies": {"Forward": "none"}},
        "TrustedSigners": {"Enabled": false, "Quantity": 0}
    },
    "Origins": {
        "Quantity": 1,
        "Items": [{
            "Id": "$BUCKET_NAME",
            "DomainName": "$BUCKET_NAME.s3-website-$REGION.amazonaws.com",
            "CustomOriginConfig": {"HTTPPort": 80, "HTTPSPort": 443, "OriginProtocolPolicy": "http-only"}
        }]
    },
    "Enabled": true,
    "DefaultRootObject": "index.html"
}
EOF

CF_OUTPUT=$(aws cloudfront create-distribution --distribution-config file://cf-config.json)
CF_DOMAIN=$(echo $CF_OUTPUT | jq -r '.Distribution.DomainName')

# Cleanup
rm -f policy.json cf-config.json

echo ""
echo "✅ Deployment Complete!"
echo "S3 Website: http://$BUCKET_NAME.s3-website-$REGION.amazonaws.com"
echo "CloudFront: https://$CF_DOMAIN"
echo ""
echo "🎮 Your 2048 game is live! CloudFront will be ready in 15-20 minutes."
