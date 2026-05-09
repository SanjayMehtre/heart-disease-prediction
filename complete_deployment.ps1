# Complete AWS Deployment Script for Heart Disease Prediction
# PowerShell script for Windows environment

Write-Host "🚀 Starting Complete AWS Deployment..." -ForegroundColor Green

# Configuration
$FUNCTION_NAME = "heart-disease-prediction"
$REGION = "us-east-1"
$ROLE_NAME = "lambda-execution-role"

# Check AWS CLI
try {
    $awsVersion = aws --version
    Write-Host "✅ AWS CLI found: $awsVersion" -ForegroundColor Green
} catch {
    Write-Host "❌ AWS CLI not found. Please install AWS CLI first." -ForegroundColor Red
    exit 1
}

# Step 1: Create IAM Role
Write-Host "📋 Creating IAM Role..." -ForegroundColor Yellow
try {
    $rolePolicy = @{
        Version = "2012-10-17"
        Statement = @{
            Effect = "Allow"
            Principal = @{
                Service = "lambda.amazonaws.com"
            }
            Action = "sts:AssumeRole"
        }
    } | ConvertTo-Json -Depth 3

    aws iam create-role --role-name $ROLE_NAME --assume-role-policy-document $rolePolicy
    aws iam attach-role-policy --role-name $ROLE_NAME --policy-arn arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole
    aws iam attach-role-policy --role-name $ROLE_NAME --policy-arn arn:aws:iam::aws:policy/AWSLambdaInvokeFunction
    Write-Host "✅ IAM Role created successfully" -ForegroundColor Green
} catch {
    Write-Host "⚠️ IAM Role might already exist" -ForegroundColor Yellow
}

# Step 2: Create Lambda package
Write-Host "📦 Creating Lambda deployment package..." -ForegroundColor Yellow
try {
    # Create requirements.txt for Lambda
    @"
Flask==2.3.2
numpy==1.24.3
pandas==1.5.3
boto3==1.26.137
botocore==1.29.137
"@ | Out-File -FilePath "lambda_requirements.txt" -Encoding UTF8

    # Create deployment package
    Compress-Archive -Path "lambda_function.py", "lambda_requirements.txt" -DestinationPath "deployment.zip" -Force
    Write-Host "✅ Lambda package created" -ForegroundColor Green
} catch {
    Write-Host "❌ Failed to create Lambda package" -ForegroundColor Red
    exit 1
}

# Step 3: Deploy Lambda function
Write-Host "🔧 Deploying Lambda function..." -ForegroundColor Yellow
try {
    $accountId = aws sts get-caller-identity --query Account --output text
    $roleArn = "arn:aws:iam::$accountId`:role/$ROLE_NAME"
    
    aws lambda create-function `
        --function-name $FUNCTION_NAME `
        --runtime python3.9 `
        --role $roleArn `
        --handler lambda_function.lambda_handler `
        --zip-file fileb://deployment.zip `
        --region $REGION `
        --description "Heart Disease Prediction API" `
        --timeout 30 `
        --memory-size 512 `
        --environment Variables="{FLASK_ENV=production,AWS_REGION=$REGION,USE_SAGEMAKER=false,SAGEMAKER_ENDPOINT=heart-disease-endpoint}" `
        2>$null
    
    Write-Host "✅ Lambda function deployed" -ForegroundColor Green
} catch {
    Write-Host "⚠️ Lambda function might already exist, updating..." -ForegroundColor Yellow
    aws lambda update-function-code --function-name $FUNCTION_NAME --zip-file fileb://deployment.zip --region $REGION
    aws lambda update-function-configuration --function-name $FUNCTION_NAME --environment Variables="{FLASK_ENV=production,AWS_REGION=$REGION,USE_SAGEMAKER=false,SAGEMAKER_ENDPOINT=heart-disease-endpoint}" --region $REGION
}

# Step 4: Create API Gateway
Write-Host "🌐 Creating API Gateway..." -ForegroundColor Yellow
try {
    $apiId = aws apigateway get-rest-apis --query "items[?name=='Heart Disease Prediction API'].id" --output text
    if (-not $apiId) {
        $apiId = aws apigateway create-rest-api --name "Heart Disease Prediction API" --description "API for Heart Disease Prediction" --region $REGION --query id --output text
        Write-Host "✅ API Gateway created: $apiId" -ForegroundColor Green
    } else {
        Write-Host "✅ API Gateway already exists: $apiId" -ForegroundColor Green
    }

    # Get root resource ID
    $rootResourceId = aws apigateway get-resources --rest-api-id $apiId --query "items[0].id" --output text
    
    # Create predict resource
    $predictResourceId = aws apigateway create-resource --rest-api-id $apiId --parent-id $rootResourceId --path-part "predict" --region $REGION --query id --output text
    
    # Add POST method
    aws apigateway put-method --rest-api-id $apiId --resource-id $predictResourceId --http-method POST --authorization-type NONE --region $REGION
    
    # Add Lambda integration
    $lambdaUri = "arn:aws:apigateway:$REGION`:lambda:path/2015-03-31/functions/arn:aws:lambda:$REGION`:$accountId`:function:$FUNCTION_NAME/invocations"
    aws apigateway put-integration --rest-api-id $apiId --resource-id $predictResourceId --http-method POST --type AWS_PROXY --integration-http-method POST --uri $lambdaUri --region $REGION
    
    # Add Lambda permission
    aws lambda add-permission --function-name $FUNCTION_NAME --statement-id apigateway-invoke --action lambda:InvokeFunction --principal apigateway.amazonaws.com --source-arn "arn:aws:execute-api:$REGION`:$accountId`:$apiId`/*/POST/predict"
    
    # Deploy API
    aws apigateway create-deployment --rest-api-id $apiId --stage-name prod --region $REGION
    
    $apiUrl = "https://$apiId.execute-api.$REGION.amazonaws.com/prod/predict"
    Write-Host "✅ API Gateway deployed: $apiUrl" -ForegroundColor Green
    
} catch {
    Write-Host "❌ Failed to deploy API Gateway" -ForegroundColor Red
    exit 1
}

# Step 5: Update frontend API URL
Write-Host "🔧 Updating frontend API URL..." -ForegroundColor Yellow
try {
    $scriptContent = Get-Content "static/script.js" -Raw
    $scriptContent = $scriptContent -replace "http://127.0.0.1:5000/predict", $apiUrl
    $scriptContent | Out-File -FilePath "static/script.js" -Encoding UTF8
    Write-Host "✅ Frontend API URL updated" -ForegroundColor Green
} catch {
    Write-Host "❌ Failed to update frontend API URL" -ForegroundColor Red
}

# Step 6: Deploy frontend to S3 (alternative to Amplify)
Write-Host "🚀 Deploying frontend to S3..." -ForegroundColor Yellow
try {
    $bucketName = "heart-disease-prediction-frontend-$accountId"
    
    # Create S3 bucket
    aws s3 mb s3://$bucketName --region $REGION 2>$null
    aws s3 website s3://$bucketName --index-document index.html --error-document error.html --region $REGION
    
    # Enable public read
    aws s3api put-bucket-policy --bucket $bucketName --policy "{
        `"Version`": `"2012-10-17`",
        `"Statement`": [
            {
                `"Sid`": `"PublicReadGetObject`",
                `"Effect`": `"Allow`",
                `"Principal`": `"*`",
                `"Action`": `"s3:GetObject`",
                `"Resource`": `"arn:aws:s3:::$bucketName/*`"
            }
        ]
    }"
    
    # Upload files
    aws s3 sync . s3://$bucketName --exclude ".git/*" --exclude "*.py" --exclude "*.sh" --exclude "*.ps1" --exclude "*.md" --exclude "deployment.zip" --region $REGION
    
    $frontendUrl = "http://$bucketName.s3-website-$REGION.amazonaws.com"
    Write-Host "✅ Frontend deployed: $frontendUrl" -ForegroundColor Green
    
} catch {
    Write-Host "❌ Failed to deploy frontend to S3" -ForegroundColor Red
}

# Step 7: Test deployment
Write-Host "🧪 Testing deployment..." -ForegroundColor Yellow
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
        Write-Host "🎯 Prediction: $($response.prediction.prediction)" -ForegroundColor Blue
    } else {
        Write-Host "❌ API test failed" -ForegroundColor Red
    }
} catch {
    Write-Host "❌ API test failed: $($_.Exception.Message)" -ForegroundColor Red
}

# Step 8: Cleanup
Write-Host "🧹 Cleaning up temporary files..." -ForegroundColor Yellow
Remove-Item "deployment.zip" -Force -ErrorAction SilentlyContinue
Remove-Item "lambda_requirements.txt" -Force -ErrorAction SilentlyContinue

# Summary
Write-Host "`n🎉 DEPLOYMENT COMPLETE!" -ForegroundColor Green
Write-Host "🌐 API Endpoint: $apiUrl" -ForegroundColor Blue
Write-Host "🌐 Frontend URL: $frontendUrl" -ForegroundColor Blue
Write-Host "📊 Lambda Function: $FUNCTION_NAME" -ForegroundColor Blue
Write-Host "🔧 Region: $REGION" -ForegroundColor Blue
Write-Host "`n💡 To enable SageMaker:" -ForegroundColor Yellow
Write-Host "1. Set USE_SAGEMAKER=true in Lambda environment variables" -ForegroundColor Gray
Write-Host "2. Deploy your model to SageMaker endpoint" -ForegroundColor Gray
Write-Host "3. Update SAGEMAKER_ENDPOINT environment variable" -ForegroundColor Gray
