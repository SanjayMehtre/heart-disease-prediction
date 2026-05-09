# Manual AWS Deployment Guide - Step by Step

## 🚀 Quick Manual Deployment

### **Step 1: Install AWS CLI** (if not already installed)
```bash
# Download and install AWS CLI from: https://aws.amazon.com/cli/
# Then run: aws configure
```

### **Step 2: Create Lambda Package**
```bash
# Create requirements file
echo Flask==2.3.2 > lambda_requirements.txt
echo numpy==1.24.3 >> lambda_requirements.txt
echo pandas==1.5.3 >> lambda_requirements.txt
echo boto3==1.26.137 >> lambda_requirements.txt
echo botocore==1.29.137 >> lambda_requirements.txt

# Create deployment package
zip deployment.zip lambda_function.py lambda_requirements.txt
```

### **Step 3: Create IAM Role**
```bash
aws iam create-role --role-name lambda-execution-role --assume-role-policy-document file://role-policy.json
aws iam attach-role-policy --role-name lambda-execution-role --policy-arn arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole
```

### **Step 4: Deploy Lambda Function**
```bash
# Get your AWS Account ID
aws sts get-caller-identity --query Account --output text

# Replace YOUR_ACCOUNT_ID in the command below
aws lambda create-function \
    --function-name heart-disease-prediction \
    --runtime python3.9 \
    --role arn:aws:iam::YOUR_ACCOUNT_ID:role/lambda-execution-role \
    --handler lambda_function.lambda_handler \
    --zip-file fileb://deployment.zip \
    --region us-east-1 \
    --description "Heart Disease Prediction API" \
    --timeout 30 \
    --memory-size 512

# Set environment variables
aws lambda update-function-configuration \
    --function-name heart-disease-prediction \
    --environment Variables="{FLASK_ENV=production,AWS_REGION=us-east-1,USE_SAGEMAKER=false,SAGEMAKER_ENDPOINT=heart-disease-endpoint}" \
    --region us-east-1
```

### **Step 5: Create API Gateway**
```bash
# Create REST API
aws apigateway create-rest-api \
    --name "Heart Disease Prediction API" \
    --description "API for Heart Disease Prediction" \
    --region us-east-1

# Note the API ID from the output, then:
aws apigateway get-resources --rest-api-id YOUR_API_ID --region us-east-1

# Create predict resource
aws apigateway create-resource \
    --rest-api-id YOUR_API_ID \
    --parent-id ROOT_RESOURCE_ID \
    --path-part "predict" \
    --region us-east-1

# Add POST method
aws apigateway put-method \
    --rest-api-id YOUR_API_ID \
    --resource-id PREDICT_RESOURCE_ID \
    --http-method POST \
    --authorization-type NONE \
    --region us-east-1

# Add Lambda integration
aws apigateway put-integration \
    --rest-api-id YOUR_API_ID \
    --resource-id PREDICT_RESOURCE_ID \
    --http-method POST \
    --type AWS_PROXY \
    --integration-http-method POST \
    --uri "arn:aws:apigateway:us-east-1:lambda:path/2015-03-31/functions/arn:aws:lambda:us-east-1:YOUR_ACCOUNT_ID:function:heart-disease-prediction/invocations" \
    --region us-east-1

# Add Lambda permission
aws lambda add-permission \
    --function-name heart-disease-prediction \
    --statement-id apigateway-invoke \
    --action lambda:InvokeFunction \
    --principal apigateway.amazonaws.com \
    --source-arn "arn:aws:execute-api:us-east-1:YOUR_ACCOUNT_ID:YOUR_API_ID/*/POST/predict"

# Deploy API
aws apigateway create-deployment \
    --rest-api-id YOUR_API_ID \
    --stage-name prod \
    --region us-east-1
```

### **Step 6: Deploy Frontend to S3**
```bash
# Create S3 bucket
aws s3 mb s3://heart-disease-prediction-YOUR_ACCOUNT_ID --region us-east-1

# Enable static website hosting
aws s3 website s3://heart-disease-prediction-YOUR_ACCOUNT_ID \
    --index-document index.html \
    --error-document error.html \
    --region us-east-1

# Enable public read access
aws s3api put-bucket-policy \
    --bucket heart-disease-prediction-YOUR_ACCOUNT_ID \
    --policy '{
        "Version": "2012-10-17",
        "Statement": [
            {
                "Sid": "PublicReadGetObject",
                "Effect": "Allow",
                "Principal": "*",
                "Action": "s3:GetObject",
                "Resource": "arn:aws:s3:::heart-disease-prediction-YOUR_ACCOUNT_ID/*"
            }
        ]
    }'

# Upload files
aws s3 sync . s3://heart-disease-prediction-YOUR_ACCOUNT_ID \
    --exclude ".git/*" \
    --exclude "*.py" \
    --exclude "*.sh" \
    --exclude "*.ps1" \
    --exclude "*.md" \
    --exclude "deployment.zip" \
    --region us-east-1
```

### **Step 7: Update Frontend API URL**
```bash
# Get your API URL (replace YOUR_API_ID)
API_URL="https://YOUR_API_ID.execute-api.us-east-1.amazonaws.com/prod/predict"

# Update the JavaScript file
sed -i.bak "s|http://127.0.0.1:5000/predict|$API_URL|g" static/script.js
```

### **Step 8: Test the Deployment**
```bash
# Test the API endpoint
curl -X POST https://YOUR_API_ID.execute-api.us-east-1.amazonaws.com/prod/predict \
  -H "Content-Type: application/json" \
  -d '{"name":"Test Patient","age":57,"sex":1,"trestbps":140,"chol":192,"fbs":0,"thalach":148}'
```

## 🌐 Final URLs

After deployment, you'll have:
- **API Endpoint**: `https://YOUR_API_ID.execute-api.us-east-1.amazonaws.com/prod/predict`
- **Frontend URL**: `http://heart-disease-prediction-YOUR_ACCOUNT_ID.s3-website-us-east-1.amazonaws.com`

## 🔧 To Enable SageMaker

1. **Deploy your model to SageMaker endpoint**
2. **Update Lambda environment variables**:
   ```bash
   aws lambda update-function-configuration \
       --function-name heart-disease-prediction \
       --environment Variables="{FLASK_ENV=production,AWS_REGION=us-east-1,USE_SAGEMAKER=true,SAGEMAKER_ENDPOINT=your-sagemaker-endpoint}" \
       --region us-east-1
   ```

## 🎯 Quick Test Commands

```bash
# Test Lambda function
aws lambda invoke --function-name heart-disease-prediction --payload '{"name":"Test","age":57,"sex":1,"trestbps":140,"chol":192,"fbs":0,"thalach":148}' response.json

# Check logs
aws logs tail /aws/lambda/heart-disease-prediction --follow
```

## 📊 Cost Summary

- **Lambda**: ~$5-10/month
- **API Gateway**: ~$3.50/month
- **S3**: ~$1-2/month
- **Total**: ~$10-20/month

## 🛠️ Troubleshooting

### **Common Issues:**
1. **IAM Role**: Wait 1-2 minutes after creating role before using it
2. **API Gateway**: Make sure to replace YOUR_API_ID in all commands
3. **S3 Bucket**: Bucket names must be globally unique
4. **CORS**: Lambda function already handles CORS headers

### **Cleanup Commands:**
```bash
# Delete Lambda function
aws lambda delete-function --function-name heart-disease-prediction

# Delete API Gateway
aws apigateway delete-rest-api --rest-api-id YOUR_API_ID

# Delete S3 bucket
aws s3 rb s3://heart-disease-prediction-YOUR_ACCOUNT_ID --force

# Delete IAM role
aws iam delete-role --role-name lambda-execution-role
```

## 🎉 Success!

Your MediCare Cardiac Center is now live on AWS with:
- ✅ Serverless backend (Lambda + API Gateway)
- ✅ Static frontend (S3)
- ✅ SageMaker integration ready
- ✅ AI treatment recommendations
- ✅ Premium medical interface
