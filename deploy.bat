@echo off
echo 🚀 Starting AWS Deployment...

REM Check AWS CLI
aws --version >nul 2>&1
if %errorlevel% neq 0 (
    echo ❌ AWS CLI not found. Please install AWS CLI first.
    pause
    exit /b 1
)
echo ✅ AWS CLI found

REM Get AWS Account ID
for /f "tokens=*" %%i in ('aws sts get-caller-identity --query Account --output text') do set accountId=%%i
echo 📋 AWS Account: %accountId%

REM Create Lambda package
echo 📦 Creating Lambda package...
(
echo Flask==2.3.2
echo numpy==1.24.3
echo pandas==1.5.3
echo boto3==1.26.137
echo botocore==1.29.137
) > lambda_requirements.txt

powershell -Command "Compress-Archive -Path 'lambda_function.py', 'lambda_requirements.txt' -DestinationPath 'deployment.zip' -Force"

REM Create IAM Role
echo 🔧 Creating IAM Role...
aws iam create-role --role-name lambda-execution-role --assume-role-policy-document file://role-policy.json 2>nul
aws iam attach-role-policy --role-name lambda-execution-role --policy-arn arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole
echo ✅ IAM Role created

REM Deploy Lambda Function
echo 🚀 Deploying Lambda function...
set roleArn=arn:aws:iam::%accountId%:role/lambda-execution-role

aws lambda create-function --function-name heart-disease-prediction --runtime python3.9 --role %roleArn% --handler lambda_function.lambda_handler --zip-file fileb://deployment.zip --region us-east-1 --description "Heart Disease Prediction API" --timeout 30 --memory-size 512 2>nul

if %errorlevel% neq 0 (
    echo ⚠️ Lambda function might already exist, updating...
    aws lambda update-function-code --function-name heart-disease-prediction --zip-file fileb://deployment.zip --region us-east-1
)

REM Set environment variables
echo ⚙️ Setting environment variables...
aws lambda update-function-configuration --function-name heart-disease-prediction --environment Variables="{FLASK_ENV=production,AWS_REGION=us-east-1,USE_SAGEMAKER=false,SAGEMAKER_ENDPOINT=heart-disease-endpoint}" --region us-east-1

REM Create API Gateway
echo 🌐 Creating API Gateway...
for /f "tokens=*" %%i in ('aws apigateway create-rest-api --name "Heart Disease Prediction API" --description "API for Heart Disease Prediction" --region us-east-1 --query id --output text') do set apiId=%%i
echo ✅ API Gateway created: %apiId%

REM Get resources and create endpoint
for /f "tokens=*" %%i in ('aws apigateway get-resources --rest-api-id %apiId% --query "items[0].id" --output text') do set rootResourceId=%%i
for /f "tokens=*" %%i in ('aws apigateway create-resource --rest-api-id %apiId% --parent-id %rootResourceId --path-part "predict" --region us-east-1 --query id --output text') do set predictResourceId=%%i

REM Add POST method
aws apigateway put-method --rest-api-id %apiId% --resource-id %predictResourceId% --http-method POST --authorization-type NONE --region us-east-1

REM Add Lambda integration
set lambdaUri=arn:aws:apigateway:us-east-1:lambda:path/2015-03-31/functions/arn:aws:lambda:us-east-1:%accountId%:function:heart-disease-prediction/invocations
aws apigateway put-integration --rest-api-id %apiId% --resource-id %predictResourceId% --http-method POST --type AWS_PROXY --integration-http-method POST --uri %lambdaUri% --region us-east-1

REM Add Lambda permission
aws lambda add-permission --function-name heart-disease-prediction --statement-id apigateway-invoke --action lambda:InvokeFunction --principal apigateway.amazonaws.com --source-arn "arn:aws:execute-api:us-east-1:%accountId%:%apiId%/*/POST/predict"

REM Deploy API
aws apigateway create-deployment --rest-api-id %apiId% --stage-name prod --region us-east-1

set apiUrl=https://%apiId%.execute-api.us-east-1.amazonaws.com/prod/predict
echo ✅ API Gateway deployed: %apiUrl%

REM Update frontend API URL
echo 🔧 Updating frontend API URL...
powershell -Command "(Get-Content 'static\script.js') -replace 'http://127.0.0.1:5000/predict', '%apiUrl%' | Set-Content 'static\script.js'"

REM Create S3 bucket for frontend
echo 🚀 Deploying frontend to S3...
set bucketName=heart-disease-prediction-%accountId%

aws s3 mb s3://%bucketName% --region us-east-1 2>nul
aws s3 website s3://%bucketName% --index-document index.html --error-document error.html --region us-east-1

REM Enable public read
(
echo {
echo     "Version": "2012-10-17",
echo     "Statement": [
echo         {
echo             "Sid": "PublicReadGetObject",
echo             "Effect": "Allow",
echo             "Principal": "*",
echo             "Action": "s3:GetObject",
echo             "Resource": "arn:aws:s3:::%bucketName%/*"
echo         }
echo     ]
echo }
) > bucket-policy.json

aws s3api put-bucket-policy --bucket %bucketName% --policy file://bucket-policy.json

REM Upload files
aws s3 sync . s3://%bucketName% --exclude ".git/*" --exclude "*.py" --exclude "*.sh" --exclude "*.ps1" --exclude "*.md" --exclude "deployment.zip" --region us-east-1

set frontendUrl=http://%bucketName%.s3-website-us-east-1.amazonaws.com
echo ✅ Frontend deployed: %frontendUrl%

REM Test API
echo 🧪 Testing API...
powershell -Command "$testData = @{name='Test Patient'; age=57; sex=1; trestbps=140; chol=192; fbs=0; thalach=148} | ConvertTo-Json; try { $response = Invoke-RestMethod -Uri '%apiUrl%' -Method POST -Body $testData -ContentType 'application/json' -TimeoutSec 30; if ($response.success) { Write-Host '✅ API test successful!' -ForegroundColor Green; Write-Host '📊 Risk Score:' $response.prediction.risk_score } else { Write-Host '❌ API test failed' } } catch { Write-Host '❌ API test failed:' $_.Exception.Message }"

REM Cleanup
del deployment.zip 2>nul
del lambda_requirements.txt 2>nul
del role-policy.json 2>nul
del bucket-policy.json 2>nul

echo.
echo 🎉 DEPLOYMENT COMPLETE!
echo 🌐 API Endpoint: %apiUrl%
echo 🌐 Frontend URL: %frontendUrl%
echo 📊 Lambda Function: heart-disease-prediction
echo.
echo 💡 To enable SageMaker:
echo 1. Set USE_SAGEMAKER=true in Lambda environment variables
echo 2. Deploy your model to SageMaker endpoint
echo 3. Update SAGEMAKER_ENDPOINT environment variable
echo.
pause
