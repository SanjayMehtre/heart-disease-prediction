#!/bin/bash

# AWS Amplify Frontend Deployment Script
echo "🚀 Deploying Frontend to AWS Amplify..."

# Check if AWS CLI is installed
if ! command -v aws &> /dev/null; then
    echo "❌ AWS CLI not found. Installing..."
    curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
    unzip awscliv2.zip
    sudo ./aws/install
fi

# Check if Amplify CLI is installed
if ! command -v amplify &> /dev/null; then
    echo "❌ Amplify CLI not found. Installing..."
    npm install -g @aws-amplify/cli
fi

# Initialize Amplify (if not already done)
if [ ! -d ".amplify" ]; then
    echo "📋 Initializing Amplify..."
    amplify init \
        --app-name heart-disease-prediction \
        --environment prod \
        --default-editor code \
        --yes
fi

# Add hosting (if not already added)
if ! amplify status | grep -q "hosting"; then
    echo "🌐 Adding hosting..."
    amplify add hosting \
        --type "amplify-hosting" \
        --custom-domain "" \
        --yes
fi

# Update frontend API URL
echo "🔧 Updating API endpoint in frontend..."
API_URL=$(aws apigateway get-rest-apis --query 'items[?name==`Heart Disease Prediction API`].id' --output text)
if [ -n "$API_URL" ]; then
    FULL_API_URL="https://$API_URL.execute-api.us-east-1.amazonaws.com/prod/predict"
    
    # Update JavaScript file with new API URL
    sed -i.bak "s|http://127.0.0.1:5000/predict|$FULL_API_URL|g" static/script.js
    
    echo "✅ Updated API URL to: $FULL_API_URL"
else
    echo "⚠️  API Gateway not found. Please deploy backend first."
    echo "📝 Current API URL in frontend: http://127.0.0.1:5000/predict"
fi

# Deploy to Amplify
echo "🚀 Deploying to Amplify..."
amplify publish \
    --env-name prod \
    --yes

# Get deployment URL
DEPLOY_URL=$(amplify status | grep "Hosting URL" | awk '{print $3}')

echo "✅ Frontend Deployment Complete!"
echo "🌐 Deployment URL: $DEPLOY_URL"
echo "📝 Test your application at: $DEPLOY_URL"

# Restore backup if created
if [ -f "static/script.js.bak" ]; then
    rm static/script.js.bak
fi

echo "🎉 Frontend is now live on AWS Amplify!"
