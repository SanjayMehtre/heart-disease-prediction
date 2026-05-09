@echo off
title Final AWS Deployment
color 0A

echo.
echo ==========================================
echo    Final AWS Deployment - Heart Disease
echo ==========================================
echo.

echo Refreshing environment variables...
call refreshenv

echo.
echo Checking AWS CLI...
aws --version >nul 2>&1
if %errorlevel% neq 0 (
    echo ❌ AWS CLI not found in PATH
    echo Please restart your command prompt and try again
    pause
    exit /b 1
)

echo ✅ AWS CLI found

echo.
echo Checking Amplify CLI...
amplify --version >nul 2>&1
if %errorlevel% neq 0 (
    echo ❌ Amplify CLI not found
    echo Installing Amplify CLI...
    npm install -g @aws-amplify/cli
)

echo ✅ Amplify CLI found

echo.
echo Step 1: Configure AWS (if not configured)...
aws sts get-caller-identity >nul 2>&1
if %errorlevel% neq 0 (
    echo AWS not configured. Please enter your credentials:
    aws configure
)

for /f "tokens=*" %%i in ('aws sts get-caller-identity --query Account --output text') do set accountId=%%i
echo ✅ AWS Account ID: %accountId%

echo.
echo Step 2: Creating Lambda deployment package...
echo Flask==2.3.2 > lambda_requirements.txt
echo numpy==1.24.3 >> lambda_requirements.txt
echo pandas==1.5.3 >> lambda_requirements.txt
echo boto3==1.26.137 >> lambda_requirements.txt
echo botocore==1.29.137 >> lambda_requirements.txt

powershell -Command "Compress-Archive -Path 'lambda_function.py', 'lambda_requirements.txt' -DestinationPath 'deployment.zip' -Force"
echo ✅ Lambda package created

echo.
echo Step 3: Creating IAM Role...
aws iam create-role --role-name lambda-execution-role --assume-role-policy-document file://role-policy.json >nul 2>&1
aws iam attach-role-policy --role-name lambda-execution-role --policy-arn arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole >nul 2>&1
echo ✅ IAM Role created

echo.
echo Step 4: Deploying Lambda function...
set roleArn=arn:aws:iam::%accountId%:role/lambda-execution-role

aws lambda create-function --function-name heart-disease-prediction --runtime python3.9 --role %roleArn% --handler lambda_function.lambda_handler --zip-file fileb://deployment.zip --region us-east-1 --description "Heart Disease Prediction API" --timeout 30 --memory-size 512 >nul 2>&1

if %errorlevel% neq 0 (
    echo ⚠️ Lambda function already exists, updating...
    aws lambda update-function-code --function-name heart-disease-prediction --zip-file fileb://deployment.zip --region us-east-1 >nul 2>&1
)

aws lambda update-function-configuration --function-name heart-disease-prediction --environment Variables="{FLASK_ENV=production,AWS_REGION=us-east-1,USE_SAGEMAKER=false,SAGEMAKER_ENDPOINT=heart-disease-endpoint}" --region us-east-1 >nul 2>&1
echo ✅ Lambda function deployed

echo.
echo Step 5: Creating API Gateway...
for /f "tokens=*" %%i in ('aws apigateway create-rest-api --name "Heart Disease Prediction API" --description "API for Heart Disease Prediction" --region us-east-1 --query id --output text') do set apiId=%%i
echo ✅ API Gateway created: %apiId%

echo.
echo Step 6: Configuring API Gateway...
for /f "tokens=*" %%i in ('aws apigateway get-resources --rest-api-id %apiId% --query "items[0].id" --output text') do set rootResourceId=%%i
for /f "tokens=*" %%i in ('aws apigateway create-resource --rest-api-id %apiId% --parent-id %rootResourceId --path-part "predict" --region us-east-1 --query id --output text') do set predictResourceId=%%i

aws apigateway put-method --rest-api-id %apiId% --resource-id %predictResourceId% --http-method POST --authorization-type NONE --region us-east-1 >nul 2>&1

set lambdaUri=arn:aws:apigateway:us-east-1:lambda:path/2015-03-31/functions/arn:aws:lambda:us-east-1:%accountId%:function:heart-disease-prediction/invocations
aws apigateway put-integration --rest-api-id %apiId% --resource-id %predictResourceId% --http-method POST --type AWS_PROXY --integration-http-method POST --uri %lambdaUri% --region us-east-1 >nul 2>&1

aws lambda add-permission --function-name heart-disease-prediction --statement-id apigateway-invoke --action lambda:InvokeFunction --principal apigateway.amazonaws.com --source-arn "arn:aws:execute-api:us-east-1:%accountId%:%apiId%/POST/predict" >nul 2>&1

aws apigateway create-deployment --rest-api-id %apiId% --stage-name prod --region us-east-1 >nul 2>&1

set apiUrl=https://%apiId%.execute-api.us-east-1.amazonaws.com/prod/predict
echo ✅ API Gateway configured

echo.
echo Step 7: Updating frontend API URL...
powershell -Command "(Get-Content 'static\script.js') -replace 'http://127.0.0.1:5000/predict', '%apiUrl%' | Set-Content 'static\script.js'" >nul 2>&1
echo ✅ Frontend updated

echo.
echo Step 8: Deploying to Amplify...
echo Initializing Amplify...
echo y | amplify init --name heart-disease-prediction --environment prod --javascript --no-editor --yes >nul 2>&1

echo Adding hosting...
echo y | amplify add hosting --yes >nul 2>&1

echo Publishing to Amplify...
echo y | amplify publish --yes >nul 2>&1

echo ✅ Amplify deployment complete

echo.
echo Step 9: Testing deployment...
powershell -Command "$testData = @{name='Test Patient'; age=57; sex=1; trestbps=140; chol=192; fbs=0; thalach=148} | ConvertTo-Json; try { $response = Invoke-RestMethod -Uri '%apiUrl%' -Method POST -Body $testData -ContentType 'application/json' -TimeoutSec 30; Write-Host '✅ API Test Successful!' -ForegroundColor Green; Write-Host '📊 Risk Score:' $response.prediction.risk_score } catch { Write-Host '❌ API Test Failed:' $_.Exception.Message -ForegroundColor Red }"

echo.
echo Cleanup...
del deployment.zip 2>nul
del lambda_requirements.txt 2>nul

echo.
echo ==========================================
echo           DEPLOYMENT COMPLETE!
echo ==========================================
echo.
echo 🌐 API Endpoint: %apiUrl%
echo 🌐 Frontend URL: Check Amplify output above
echo 📊 Lambda Function: heart-disease-prediction
echo 🎯 AWS Account: %accountId%
echo.
echo 🎉 Your MediCare Cardiac Center is now live on AWS!
echo.
echo 💡 Next Steps:
echo 1. Open your Amplify URL in browser
echo 2. Test the heart disease prediction
echo 3. Enable SageMaker when ready
echo.
pause
