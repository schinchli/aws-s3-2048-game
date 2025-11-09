#!/bin/bash

# Portfolio Website Deployment Script
# Deploys a static resume website to AWS S3 with CloudFront CDN

set -e

echo "🚀 Starting Portfolio Website Deployment"

# Configuration
BUCKET_NAME="portfolio-$(whoami)-$(date +%s)"
REGION="us-east-1"

echo "📋 Deployment Configuration:"
echo "  Bucket Name: $BUCKET_NAME"
echo "  Region: $REGION"
echo ""

# Step 1: Create S3 Bucket
echo "📦 Creating S3 bucket..."
aws s3 mb s3://$BUCKET_NAME --region $REGION

# Step 2: Configure static website hosting
echo "🌐 Configuring static website hosting..."
aws s3 website s3://$BUCKET_NAME --index-document index.html --error-document error.html

# Step 3: Set bucket policy for public read access
echo "🔒 Setting bucket policy for public read access..."
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

aws s3api put-bucket-policy --bucket $BUCKET_NAME --policy file://bucket-policy.json

# Step 4: Upload website files
echo "📤 Uploading website files..."
aws s3 sync . s3://$BUCKET_NAME \
  --exclude "*.md" \
  --exclude "*.sh" \
  --exclude "bucket-policy.json" \
  --exclude "cloudfront-config.json"

# Get S3 website URL
S3_WEBSITE_URL="http://$BUCKET_NAME.s3-website-$REGION.amazonaws.com"
echo "✅ Website uploaded to S3: $S3_WEBSITE_URL"

# Step 5: Create CloudFront distribution
echo "🌍 Creating CloudFront distribution..."
cat > cloudfront-config.json << EOF
{
  "CallerReference": "portfolio-$(date +%s)",
  "Comment": "Portfolio Website CDN - $BUCKET_NAME",
  "DefaultRootObject": "index.html",
  "Origins": {
    "Quantity": 1,
    "Items": [
      {
        "Id": "S3-$BUCKET_NAME",
        "DomainName": "$BUCKET_NAME.s3-website-$REGION.amazonaws.com",
        "CustomOriginConfig": {
          "HTTPPort": 80,
          "HTTPSPort": 443,
          "OriginProtocolPolicy": "http-only"
        }
      }
    ]
  },
  "DefaultCacheBehavior": {
    "TargetOriginId": "S3-$BUCKET_NAME",
    "ViewerProtocolPolicy": "redirect-to-https",
    "TrustedSigners": {
      "Enabled": false,
      "Quantity": 0
    },
    "ForwardedValues": {
      "QueryString": false,
      "Cookies": {
        "Forward": "none"
      }
    },
    "MinTTL": 0,
    "DefaultTTL": 86400,
    "MaxTTL": 31536000,
    "Compress": true
  },
  "Enabled": true,
  "PriceClass": "PriceClass_100"
}
EOF

DISTRIBUTION_ID=$(aws cloudfront create-distribution \
  --distribution-config file://cloudfront-config.json \
  --query 'Distribution.Id' --output text)

echo "✅ CloudFront distribution created: $DISTRIBUTION_ID"
echo "⏳ Distribution is deploying... This takes 15-20 minutes"

# Step 6: Wait for CloudFront deployment
echo "⏳ Waiting for CloudFront deployment to complete..."
aws cloudfront wait distribution-deployed --id $DISTRIBUTION_ID

# Get CloudFront domain name
CLOUDFRONT_DOMAIN=$(aws cloudfront get-distribution \
  --id $DISTRIBUTION_ID \
  --query 'Distribution.DomainName' --output text)

# Step 7: Test the deployment
echo "🧪 Testing website deployment..."
sleep 30  # Allow some time for propagation

# Test S3 website
echo "Testing S3 website..."
curl -s -o /dev/null -w "%{http_code}" $S3_WEBSITE_URL | grep -q "200" && echo "✅ S3 website responding" || echo "❌ S3 website not responding"

# Test CloudFront
echo "Testing CloudFront distribution..."
curl -s -o /dev/null -w "%{http_code}" https://$CLOUDFRONT_DOMAIN | grep -q "200" && echo "✅ CloudFront responding" || echo "❌ CloudFront not responding"

# Cleanup temporary files
rm -f bucket-policy.json cloudfront-config.json

# Save deployment information
cat > deployment-info.json << EOF
{
  "deployment_date": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
  "bucket_name": "$BUCKET_NAME",
  "region": "$REGION",
  "s3_website_url": "$S3_WEBSITE_URL",
  "cloudfront_distribution_id": "$DISTRIBUTION_ID",
  "cloudfront_domain": "$CLOUDFRONT_DOMAIN",
  "secure_website_url": "https://$CLOUDFRONT_DOMAIN",
  "estimated_monthly_cost": "$0.50 - $2.00"
}
EOF

echo ""
echo "🎉 Deployment completed successfully!"
echo ""
echo "📊 Deployment Summary:"
echo "  S3 Bucket: $BUCKET_NAME"
echo "  S3 Website URL: $S3_WEBSITE_URL"
echo "  CloudFront Distribution: $DISTRIBUTION_ID"
echo "  Secure Website URL: https://$CLOUDFRONT_DOMAIN"
echo ""
echo "📝 Next Steps:"
echo "  1. Visit https://$CLOUDFRONT_DOMAIN to see your portfolio"
echo "  2. Click on any text to edit your resume"
echo "  3. Upload your profile photo"
echo "  4. Customize all sections with your information"
echo "  5. Share your portfolio URL with employers!"
echo ""
echo "💾 Deployment info saved to: deployment-info.json"
echo ""
echo "🔧 To update your website:"
echo "  1. Make changes to your files"
echo "  2. Run: aws s3 sync . s3://$BUCKET_NAME --exclude '*.md' --exclude '*.sh'"
echo "  3. Invalidate cache: aws cloudfront create-invalidation --distribution-id $DISTRIBUTION_ID --paths '/*'"
