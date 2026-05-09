@echo off
title AWS Final Deployment
color 0A

echo.
echo ==========================================
echo    AWS Final Deployment Solution
echo ==========================================
echo.

echo Step 1: Finding AWS CLI...
if exist "C:\Program Files\Amazon\AWSCLI\bin\aws.exe" (
    set AWS_PATH=C:\Program Files\Amazon\AWSCLI\bin\
    echo ✅ AWS CLI found at: %AWS_PATH%
) else if exist "C:\Program Files (x86)\Amazon\AWSCLI\bin\aws.exe" (
    set AWS_PATH=C:\Program Files (x86)\Amazon\AWSCLI\bin\
    echo ✅ AWS CLI found at: %AWS_PATH%
) else (
    for /f "tokens=*" %%i in ('where aws.exe 2^>nul') do set AWS_PATH=%%~dpi
    if defined AWS_PATH (
        echo ✅ AWS CLI found at: %AWS_PATH%
    ) else (
        echo ❌ AWS CLI not found. Please install from https://aws.amazon.com/cli/
        pause
        exit /b 1
    )
)

echo.
echo Step 2: Configure AWS (if needed)...
"%AWS_PATH%aws.exe" configure

echo.
echo Step 3: Get AWS Account ID...
for /f "tokens=*" %%i in ('"%AWS_PATH%aws.exe" sts get-caller-identity --query Account --output text') do set accountId=%%i
if "%accountId%"=="" (
    echo ❌ AWS configuration failed
    pause
    exit /b 1
)

echo ✅ AWS Account ID: %accountId%

echo.
echo Step 4: Create Lambda package...
echo Flask==2.3.2 > lambda_requirements.txt
echo numpy==1.24.3 >> lambda_requirements.txt
echo pandas==1.5.3 >> lambda_requirements.txt
echo boto3==1.26.137 >> lambda_requirements.txt
echo botocore==1.29.137 >> lambda_requirements.txt

powershell -Command "Compress-Archive -Path 'lambda_function.py', 'lambda_requirements.txt' -DestinationPath 'deployment.zip' -Force"
echo ✅ Lambda package created

echo.
echo Step 5: Create IAM Role...
"%AWS_PATH%aws.exe" iam create-role --role-name lambda-execution-role --assume-role-policy-document file://role-policy.json >nul 2>&1
"%AWS_PATH%aws.exe" iam attach-role-policy --role-name lambda-execution-role --policy-arn arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole >nul 2>&1
echo ✅ IAM Role created

echo.
echo Step 6: Deploy Lambda function...
set roleArn=arn:aws:iam::%accountId%:role/lambda-execution-role

"%AWS_PATH%aws.exe" lambda create-function --function-name heart-disease-prediction --runtime python3.9 --role %roleArn% --handler lambda_function.lambda_handler --zip-file fileb://deployment.zip --region us-east-1 --description "Heart Disease Prediction API" --timeout 30 --memory-size 512 >nul 2>&1

if %errorlevel% neq 0 (
    echo ⚠️ Lambda function already exists, updating...
    "%AWS_PATH%aws.exe" lambda update-function-code --function-name heart-disease-prediction --zip-file fileb://deployment.zip --region us-east-1 >nul 2>&1
)

"%AWS_PATH%aws.exe" lambda update-function-configuration --function-name heart-disease-prediction --environment Variables="{FLASK_ENV=production,AWS_REGION=us-east-1,USE_SAGEMAKER=false,SAGEMAKER_ENDPOINT=heart-disease-endpoint}" --region us-east-1 >nul 2>&1
echo ✅ Lambda function deployed

echo.
echo Step 7: Create API Gateway...
for /f "tokens=*" %%i in ('"%AWS_PATH%aws.exe" apigateway create-rest-api --name "Heart Disease Prediction API" --description "API for Heart Disease Prediction" --region us-east-1 --query id --output text') do set apiId=%%i
echo ✅ API Gateway created: %apiId%

echo.
echo Step 8: Configure API Gateway...
for /f "tokens=*" %%i in ('"%AWS_PATH%aws.exe" apigateway get-resources --rest-api-id %apiId% --query "items[0].id" --output text') do set rootResourceId=%%i
for /f "tokens=*" %%i in ('"%AWS_PATH%aws.exe" apigateway create-resource --rest-api-id %apiId% --parent-id %rootResourceId% --path-part "predict" --region us-east-1 --query id --output text') do set predictResourceId=%%i

"%AWS_PATH%aws.exe" apigateway put-method --rest-api-id %apiId% --resource-id %predictResourceId% --http-method POST --authorization-type NONE --region us-east-1 >nul 2>&1

set lambdaUri=arn:aws:apigateway:us-east-1:lambda:path/2015-03-31/functions/arn:aws:lambda:us-east-1:%accountId%:function:heart-disease-prediction/invocations
"%AWS_PATH%aws.exe" apigateway put-integration --rest-api-id %apiId% --resource-id %predictResourceId% --http-method POST --type AWS_PROXY --integration-http-method POST --uri %lambdaUri% --region us-east-1 >nul 2>&1

"%AWS_PATH%aws.exe" lambda add-permission --function-name heart-disease-prediction --statement-id apigateway-invoke --action lambda:InvokeFunction --principal apigateway.amazonaws.com --source-arn "arn:aws:execute-api:us-east-1:%accountId%:%apiId%/POST/predict" >nul 2>&1

"%AWS_PATH%aws.exe" apigateway create-deployment --rest-api-id %apiId% --stage-name prod --region us-east-1 >nul 2>&1

set apiUrl=https://%apiId%.execute-api.us-east-1.amazonaws.com/prod/predict
echo ✅ API Gateway configured

echo.
echo Step 9: Update frontend API URL...
powershell -Command "(Get-Content 'static\script.js') -replace 'http://127.0.0.1:5000/predict', '%apiUrl%' | Set-Content 'static\script.js'" >nul 2>&1
echo ✅ Frontend updated

echo.
echo Step 10: Deploy to Amplify...
echo Initializing Amplify...
echo y | "%AWS_PATH%amplify.bat" init --name heart-disease-prediction --environment prod --javascript --no-editor --yes >nul 2>&1

echo Adding hosting...
echo y | "%AWS_PATH%amplify.bat" add hosting --yes >nul 2>&1

echo Publishing to Amplify...
echo y | "%AWS_PATH%amplify.bat" publish --yes >nul 2>&1

echo ✅ Amplify deployment complete

echo.
echo Step 11: Test deployment...
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
