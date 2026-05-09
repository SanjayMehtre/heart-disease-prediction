# AWS Deployment Script for Heart Disease Prediction
Write-Host "🚀 Starting AWS Deployment..." -ForegroundColor Green

# Check AWS CLI
try {
    aws --version | Out-Null
    Write-Host "✅ AWS CLI found" -ForegroundColor Green
} catch {
    Write-Host "❌ AWS CLI not found. Please install AWS CLI first." -ForegroundColor Red
    exit 1
}

# Get AWS Account ID
$accountId = aws sts get-caller-identity --query Account --output text
Write-Host "📋 AWS Account: $accountId" -ForegroundColor Blue

# Create Lambda package
Write-Host "📦 Creating Lambda package..." -ForegroundColor Yellow
@"
Flask==2.3.2
numpy==1.24.3
pandas==1.5.3
boto3==1.26.137
botocore==1.29.137
"@ | Out-File -FilePath "lambda_requirements.txt" -Encoding UTF8

Compress-Archive -Path "lambda_function.py", "lambda_requirements.txt" -DestinationPath "deployment.zip" -Force

# Create IAM Role
Write-Host "🔧 Creating IAM Role..." -ForegroundColor Yellow
$rolePolicy = @"
{
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
}
"@

try {
    aws iam create-role --role-name lambda-execution-role --assume-role-policy-document $rolePolicy
    aws iam attach-role-policy --role-name lambda-execution-role --policy-arn arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole
    Write-Host "✅ IAM Role created" -ForegroundColor Green
} catch {
    Write-Host "⚠️ IAM Role might already exist" -ForegroundColor Yellow
}

# Deploy Lambda Function
Write-Host "🚀 Deploying Lambda function..." -ForegroundColor Yellow
$roleArn = "arn:aws:iam::$accountId`:role/lambda-execution-role"

try {
    aws lambda create-function `
        --function-name heart-disease-prediction `
        --runtime python3.9 `
        --role $roleArn `
        --handler lambda_function.lambda_handler `
        --zip-file fileb://deployment.zip `
        --region us-east-1 `
        --description "Heart Disease Prediction API" `
        --timeout 30 `
        --memory-size 512
    
    Write-Host "✅ Lambda function created" -ForegroundColor Green
} catch {
    Write-Host "⚠️ Lambda function might already exist, updating..." -ForegroundColor Yellow
    aws lambda update-function-code --function-name heart-disease-prediction --zip-file fileb://deployment.zip --region us-east-1
}

# Set environment variables
Write-Host "⚙️ Setting environment variables..." -ForegroundColor Yellow
aws lambda update-function-configuration `
    --function-name heart-disease-prediction `
    --environment Variables="{FLASK_ENV=production,AWS_REGION=us-east-1,USE_SAGEMAKER=false,SAGEMAKER_ENDPOINT=heart-disease-endpoint}" `
    --region us-east-1

# Create API Gateway
Write-Host "🌐 Creating API Gateway..." -ForegroundColor Yellow
try {
    $apiId = aws apigateway create-rest-api --name "Heart Disease Prediction API" --description "API for Heart Disease Prediction" --region us-east-1 --query id --output text
    Write-Host "✅ API Gateway created: $apiId" -ForegroundColor Green
} catch {
    Write-Host "⚠️ API Gateway might already exist" -ForegroundColor Yellow
    $apiId = aws apigateway get-rest-apis --query "items[?name=='Heart Disease Prediction API'].id" --output text
}

# Get resources and create endpoint
$rootResourceId = aws apigateway get-resources --rest-api-id $apiId --query "items[0].id" --output text
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

$apiUrl = "https://$apiId.execute-api.us-east-1.amazonaws.com/prod/predict"
Write-Host "✅ API Gateway deployed: $apiUrl" -ForegroundColor Green

# Update frontend API URL
Write-Host "🔧 Updating frontend API URL..." -ForegroundColor Yellow
$scriptContent = Get-Content "static/script.js" -Raw
$scriptContent = $scriptContent -replace "http://127.0.0.1:5000/predict", $apiUrl
$scriptContent | Out-File -FilePath "static/script.js" -Encoding UTF8

# Create S3 bucket for frontend
Write-Host "🚀 Deploying frontend to S3..." -ForegroundColor Yellow
$bucketName = "heart-disease-prediction-$accountId"

try {
    aws s3 mb s3://$bucketName --region us-east-1
    aws s3 website s3://$bucketName --index-document index.html --error-document error.html --region us-east-1
    
    # Enable public read
    $bucketPolicy = @"
{
        "Version": "2012-10-17",
        "Statement": [
            {
                "Sid": "PublicReadGetObject",
                "Effect": "Allow",
                "Principal": "*",
                "Action": "s3:GetObject",
                "Resource": "arn:aws:s3:::$bucketName/*"
            }
        ]
    }
"@
    
    aws s3api put-bucket-policy --bucket $bucketName --policy $bucketPolicy
    
    # Upload files
    aws s3 sync . s3://$bucketName --exclude ".git/*" --exclude "*.py" --exclude "*.sh" --exclude "*.ps1" --exclude "*.md" --exclude "deployment.zip" --region us-east-1
    
    $frontendUrl = "http://$bucketName.s3-website-us-east-1.amazonaws.com"
    Write-Host "✅ Frontend deployed: $frontendUrl" -ForegroundColor Green
    
} catch {
    Write-Host "❌ Failed to deploy frontend" -ForegroundColor Red
}

# Test API
Write-Host "🧪 Testing API..." -ForegroundColor Yellow
try {
    $testData = @{
        name = "Test Patient"
        age = 57
        sex = 1
        trestbps = 140
        chol = 192
        fbs = 0
        thalach = 148
    } | ConvertTo-Json
    
    $response = Invoke-RestMethod -Uri $apiUrl -Method POST -Body $testData -ContentType "application/json" -TimeoutSec 30
    
    if ($response.success) {
        Write-Host "✅ API test successful!" -ForegroundColor Green
        Write-Host "📊 Risk Score: $($response.prediction.risk_score)" -ForegroundColor Blue
    } else {
        Write-Host "❌ API test failed" -ForegroundColor Red
    }
} catch {
    Write-Host "❌ API test failed: $($_.Exception.Message)" -ForegroundColor Red
}

# Cleanup
Remove-Item "deployment.zip" -Force -ErrorAction SilentlyContinue
Remove-Item "lambda_requirements.txt" -Force -ErrorAction SilentlyContinue

# Summary
Write-Host "`n🎉 DEPLOYMENT COMPLETE!" -ForegroundColor Green
Write-Host "🌐 API Endpoint: $apiUrl" -ForegroundColor Blue
Write-Host "🌐 Frontend URL: $frontendUrl" -ForegroundColor Blue
Write-Host "📊 Lambda Function: heart-disease-prediction" -ForegroundColor Blue
