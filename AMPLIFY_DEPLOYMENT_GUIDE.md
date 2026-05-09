# AWS Amplify Deployment Guide - No Stuck Issues

## 🚀 Complete Amplify Deployment (Step-by-Step)

### **Step 1: Install Required Tools**

#### **Install AWS CLI**
```bash
# Windows: Download from https://aws.amazon.com/cli/
# Or install via PowerShell:
Invoke-WebRequest -Uri https://awscli.amazonaws.com/AWSCLIV2.msi -Outfile AWSCLIV2.msi
Start-Process msiexec.exe -ArgumentList '/i AWSCLIV2.msi /quiet' -Wait

# Configure AWS CLI
aws configure
# Enter your AWS Access Key ID
# Enter your AWS Secret Access Key
# Enter default region: us-east-1
# Enter default output format: json
```

#### **Install Amplify CLI**
```bash
# Install Node.js first (https://nodejs.org/)
# Then install Amplify CLI:
npm install -g @aws-amplify/cli
```

### **Step 2: Deploy Backend to Lambda**

#### **Create Lambda Package**
```bash
# Create requirements file
echo Flask==2.3.2 > lambda_requirements.txt
echo numpy==1.24.3 >> lambda_requirements.txt
echo pandas==1.5.3 >> lambda_requirements.txt
echo boto3==1.26.137 >> lambda_requirements.txt
echo botocore==1.29.137 >> lambda_requirements.txt

# Create deployment package
powershell -Command "Compress-Archive -Path 'lambda_function.py', 'lambda_requirements.txt' -DestinationPath 'deployment.zip' -Force"
```

#### **Create IAM Role**
```bash
# Create role-policy.json file (already exists)
aws iam create-role --role-name lambda-execution-role --assume-role-policy-document file://role-policy.json
aws iam attach-role-policy --role-name lambda-execution-role --policy-arn arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole
```

#### **Deploy Lambda Function**
```bash
# Get your AWS Account ID
$accountId = aws sts get-caller-identity --query Account --output text

# Create Lambda function
aws lambda create-function `
    --function-name heart-disease-prediction `
    --runtime python3.9 `
    --role arn:aws:iam::$accountId`:role/lambda-execution-role `
    --handler lambda_function.lambda_handler `
    --zip-file fileb://deployment.zip `
    --region us-east-1 `
    --description "Heart Disease Prediction API" `
    --timeout 30 `
    --memory-size 512

# Set environment variables
aws lambda update-function-configuration `
    --function-name heart-disease-prediction `
    --environment Variables="{FLASK_ENV=production,AWS_REGION=us-east-1,USE_SAGEMAKER=false,SAGEMAKER_ENDPOINT=heart-disease-endpoint}" `
    --region us-east-1
```

#### **Create API Gateway**
```bash
# Create REST API
$apiId = aws apigateway create-rest-api --name "Heart Disease Prediction API" --description "API for Heart Disease Prediction" --region us-east-1 --query id --output text

# Get root resource ID
$rootResourceId = aws apigateway get-resources --rest-api-id $apiId --query "items[0].id" --output text

# Create predict resource
$predictResourceId = aws apigateway create-resource --rest-api-id $apiId --parent-id $rootResourceId --path-part "predict" --region us-east-1 --query id --output text

# Add POST method
aws apigateway put-method --rest-api-id $apiId --resource-id $predictResourceId --http-method POST --authorization-type NONE --region us-east-1

# Add Lambda integration
$lambdaUri = "arn:aws:apigateway:us-east-1:lambda:path/2015-03-31/functions/arn:aws:lambda:us-east-1:$accountId`:function:heart-disease-prediction/invocations"
aws apigateway put-integration --rest-api-id $apiId --resource-id $predictResourceId --http-method POST --type AWS_PROXY --integration-http-method POST --uri $lambdaUri --region us-east-1

# Add Lambda permission
aws lambda add-permission --function-name heart-disease-prediction --statement-id apigateway-invoke --action lambda:InvokeFunction --principal apigateway.amazonaws.com --source-arn "arn:aws:execute-api:us-east-1:$accountId`:$apiId`/*/POST/predict"

# Deploy API
aws apigateway create-deployment --rest-api-id $apiId --stage-name prod --region us-east-1

# Get API URL
$apiUrl = "https://$apiId.execute-api.us-east-1.amazonaws.com/prod/predict"
echo "API URL: $apiUrl"
```

### **Step 3: Deploy Frontend to Amplify**

#### **Initialize Amplify**
```bash
# Navigate to project directory
cd "c:\Users\sanja\OneDrive\Documents\Desktop\cc\aws-sagemaker-heart-disease-prediction-master"

# Initialize Amplify
amplify init

# Follow prompts:
# ? Enter a name for the project: heart-disease-prediction
# ? Enter a name for the environment: prod
# ? Choose your default editor: None
# ? Choose the type of app that you're building: javascript
# ? What javascript framework are you using: none
# ? Source directory path: .
# ? Distribution directory path: .
# ? Build command: 
# ? Start command: 
# ? Do you want to use an AWS profile? Yes
# ? Please choose the profile you want to use: default
```

#### **Add Hosting**
```bash
# Add hosting to Amplify
amplify add hosting

# Follow prompts:
# ? Select the plugin module to execute: Hosting with Amplify Console (Managed hosting with custom domains, Continuous deployment)
# ? Select the environment type: PRODUCTION (S3 with CloudFront using HTTP)
# ? Hosting bucket name: heart-disease-prediction-prod (accept default)
```

#### **Update Frontend API URL**
```bash
# Update JavaScript file with new API URL
$scriptContent = Get-Content "static/script.js" -Raw
$scriptContent = $scriptContent -replace "http://127.0.0.1:5000/predict", $apiUrl
$scriptContent | Out-File -FilePath "static/script.js" -Encoding UTF8
```

#### **Deploy to Amplify**
```bash
# Deploy the application
amplify publish

# Wait for deployment to complete
# Amplify will provide the URL
```

### **Step 4: Test the Complete Deployment**

#### **Test API Endpoint**
```bash
# Test the deployed API
curl -X POST $apiUrl `
  -H "Content-Type: application/json" `
  -d '{"name":"Test Patient","age":57,"sex":1,"trestbps":140,"chol":192,"fbs":0,"thalach":148}'
```

#### **Test Frontend**
```bash
# Open the Amplify URL in browser
# The URL will be provided by Amplify after deployment
# Format: https://uniqueid.amplifyapp.com
```

## 🎯 **Quick Deploy Script (Copy & Paste)**

```powershell
# Step 1: Create Lambda package
echo "Creating Lambda package..."
echo Flask==2.3.2 > lambda_requirements.txt
echo numpy==1.24.3 >> lambda_requirements.txt
echo pandas==1.5.3 >> lambda_requirements.txt
echo boto3==1.26.137 >> lambda_requirements.txt
echo botocore==1.29.137 >> lambda_requirements.txt
Compress-Archive -Path 'lambda_function.py', 'lambda_requirements.txt' -DestinationPath 'deployment.zip' -Force

# Step 2: Deploy Lambda
echo "Deploying Lambda function..."
$accountId = aws sts get-caller-identity --query Account --output text
aws lambda create-function --function-name heart-disease-prediction --runtime python3.9 --role arn:aws:iam::$accountId`:role/lambda-execution-role --handler lambda_function.lambda_handler --zip-file fileb://deployment.zip --region us-east-1 --description "Heart Disease Prediction API" --timeout 30 --memory-size 512
aws lambda update-function-configuration --function-name heart-disease-prediction --environment Variables="{FLASK_ENV=production,AWS_REGION=us-east-1,USE_SAGEMAKER=false,SAGEMAKER_ENDPOINT=heart-disease-endpoint}" --region us-east-1

# Step 3: Create API Gateway
echo "Creating API Gateway..."
$apiId = aws apigateway create-rest-api --name "Heart Disease Prediction API" --description "API for Heart Disease Prediction" --region us-east-1 --query id --output text
$rootResourceId = aws apigateway get-resources --rest-api-id $apiId --query "items[0].id" --output text
$predictResourceId = aws apigateway create-resource --rest-api-id $apiId --parent-id $rootResourceId --path-part "predict" --region us-east-1 --query id --output text
$lambdaUri = "arn:aws:apigateway:us-east-1:lambda:path/2015-03-31/functions/arn:aws:lambda:us-east-1:$accountId`:function:heart-disease-prediction/invocations"
aws apigateway put-method --rest-api-id $apiId --resource-id $predictResourceId --http-method POST --authorization-type NONE --region us-east-1
aws apigateway put-integration --rest-api-id $apiId --resource-id $predictResourceId --http-method POST --type AWS_PROXY --integration-http-method POST --uri $lambdaUri --region us-east-1
aws lambda add-permission --function-name heart-disease-prediction --statement-id apigateway-invoke --action lambda:InvokeFunction --principal apigateway.amazonaws.com --source-arn "arn:aws:execute-api:us-east-1:$accountId`:$apiId`/*/POST/predict"
aws apigateway create-deployment --rest-api-id $apiId --stage-name prod --region us-east-1

# Step 4: Update frontend
echo "Updating frontend API URL..."
$apiUrl = "https://$apiId.execute-api.us-east-1.amazonaws.com/prod/predict"
$scriptContent = Get-Content "static/script.js" -Raw
$scriptContent = $scriptContent -replace "http://127.0.0.1:5000/predict", $apiUrl
$scriptContent | Out-File -FilePath "static/script.js" -Encoding UTF8

# Step 5: Deploy to Amplify
echo "Deploying to Amplify..."
amplify init --yes
amplify add hosting --yes
amplify publish --yes

echo "Deployment Complete!"
echo "API URL: $apiUrl"
echo "Frontend URL: Check Amplify output"
```

## 🌐 **Final URLs**

After deployment:
- **API**: `https://YOUR_API_ID.execute-api.us-east-1.amazonaws.com/prod/predict`
- **Frontend**: `https://uniqueid.amplifyapp.com`

## 🔧 **Troubleshooting**

### **Common Issues & Solutions:**

1. **"aws command not found"**
   - Install AWS CLI from https://aws.amazon.com/cli/
   - Restart PowerShell after installation

2. **"amplify command not found"**
   - Install Node.js from https://nodejs.org/
   - Run: `npm install -g @aws-amplify/cli`

3. **IAM Role Error**
   - Wait 2-3 minutes after creating role before using it
   - Check role exists: `aws iam get-role --role-name lambda-execution-role`

4. **API Gateway Error**
   - Make sure API ID is correct
   - Check resource IDs are valid

5. **Amplify Stuck**
   - Use `amplify status` to check deployment status
   - Use `amplify delete` to remove and start over if needed

## 🎉 **Success Indicators**

✅ **Lambda Function**: Created and configured
✅ **API Gateway**: Deployed with POST endpoint
✅ **Frontend**: Updated with new API URL
✅ **Amplify**: Hosted and accessible
✅ **Integration**: Frontend calls backend successfully

## 💰 **Cost Estimate**

- **Lambda**: ~$5-10/month
- **API Gateway**: ~$3.50/month
- **Amplify**: ~$15-25/month (includes CloudFront CDN)
- **Total**: ~$25-40/month

## 🔄 **To Enable SageMaker**

1. Deploy model to SageMaker endpoint
2. Update Lambda environment variable:
   ```bash
   aws lambda update-function-configuration --function-name heart-disease-prediction --environment Variables="{FLASK_ENV=production,AWS_REGION=us-east-1,USE_SAGEMAKER=true,SAGEMAKER_ENDPOINT=your-endpoint-name}" --region us-east-1
   ```

**🎯 Your MediCare Cardiac Center will be live on AWS Amplify with no stuck deployment issues!**
