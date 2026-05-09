#!/bin/bash

# AWS Lambda Deployment Script for Heart Disease Prediction
echo "🚀 Deploying Heart Disease Prediction to AWS Lambda..."

# Configuration
FUNCTION_NAME="heart-disease-prediction"
REGION="us-east-1"
ROLE_NAME="lambda-execution-role"

# Create IAM Role for Lambda
echo "📋 Creating IAM Role..."
aws iam create-role \
    --role-name $ROLE_NAME \
    --assume-role-policy-document '{
        "Version": "2012-10-17",
        "Statement": [
            {
                "Effect": "Allow",
                "Principal": {
                    "Service": "lambda.amazonaws.com"
                },
                "Action": "sts:AssumeRole"
            }
        ]
    }' \
    --description "Role for Lambda function execution"

# Attach basic execution policy
aws iam attach-role-policy \
    --role-name $ROLE_NAME \
    --policy-arn arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole

# Wait for role to be created
echo "⏳ Waiting for IAM role to be created..."
sleep 10

# Create Lambda package
echo "📦 Creating Lambda deployment package..."
zip -r deployment.zip lambda_function.py requirements.txt

# Create Lambda function
echo "🔧 Creating Lambda function..."
aws lambda create-function \
    --function-name $FUNCTION_NAME \
    --runtime python3.9 \
    --role arn:aws:iam::$(aws sts get-caller-identity --query Account --output text):role/$ROLE_NAME \
    --handler lambda_function.lambda_handler \
    --zip-file fileb://deployment.zip \
    --region $REGION \
    --description "Heart Disease Prediction API" \
    --timeout 30 \
    --memory-size 512

# Add environment variables
echo "⚙️ Setting environment variables..."
aws lambda update-function-configuration \
    --function-name $FUNCTION_NAME \
    --environment Variables='{FLASK_ENV=production,AWS_REGION='$REGION',USE_SAGEMAKER=false,SAGEMAKER_ENDPOINT=heart-disease-endpoint}' \
    --region $REGION

# Create API Gateway
echo "🌐 Creating API Gateway..."
aws apigateway create-rest-api \
    --name "Heart Disease Prediction API" \
    --description "API for Heart Disease Prediction" \
    --region $REGION

# Get API ID
API_ID=$(aws apigateway get-rest-apis --region $REGION --query 'items[0].id' --output text)

# Create resource
RESOURCE_ID=$(aws apigateway create-resource \
    --rest-api-id $API_ID \
    --parent-id $(aws apigateway get-resources --rest-api-id $API_ID --query 'items[0].id' --output text) \
    --path-part 'predict' \
    --region $REGION \
    --query 'id' --output text)

# Create POST method
aws apigateway put-method \
    --rest-api-id $API_ID \
    --resource-id $RESOURCE_ID \
    --http-method POST \
    --authorization-type NONE \
    --region $REGION

# Add Lambda integration
aws apigateway put-integration \
    --rest-api-id $API_ID \
    --resource-id $RESOURCE_ID \
    --http-method POST \
    --type AWS_PROXY \
    --integration-http-method POST \
    --uri arn:aws:apigateway:$REGION:lambda:path/2015-03-31/functions/arn:aws:lambda:$REGION:$(aws sts get-caller-identity --query Account --output text):function:$FUNCTION_NAME/invocations \
    --region $REGION

# Add Lambda permission
aws lambda add-permission \
    --function-name $FUNCTION_NAME \
    --statement-id apigateway-invoke \
    --action lambda:InvokeFunction \
    --principal apigateway.amazonaws.com \
    --source-arn arn:aws:execute-api:$REGION:$(aws sts get-caller-identity --query Account --output text):$API_ID/*/POST/predict

# Deploy API
aws apigateway create-deployment \
    --rest-api-id $API_ID \
    --stage-name prod \
    --region $REGION

# Enable CORS
aws apigateway update-method \
    --rest-api-id $API_ID \
    --resource-id $RESOURCE_ID \
    --http-method OPTIONS \
    --patch-operations op=add,path=/integration/integrationResponses,='[{"statusCode":"200","responseParameters":{"method.response.header.Access-Control-Allow-Origin":"'*'"}}]' \
    --region $REGION

# Get API URL
API_URL="https://$API_ID.execute-api.$REGION.amazonaws.com/prod/predict"

echo "✅ Deployment Complete!"
echo "🌐 API Endpoint: $API_URL"
echo "📝 Update your frontend API_BASE_URL to: $API_URL"

# Clean up
rm deployment.zip

echo "🎉 Heart Disease Prediction API is now live!"
