@echo off
title Fast AWS Deploy - Final
color 0A

echo.
echo ==========================================
echo    FAST AWS DEPLOYMENT
echo ==========================================
echo.

echo This will deploy everything in one go!
echo.

pause

echo Step 1: AWS Setup...
start /wait cmd /c "aws configure"

echo Step 2: Lambda Deploy...
powershell -Command "echo Flask==2.3.2 > lambda_requirements.txt; echo numpy==1.24.3 >> lambda_requirements.txt; echo pandas==1.5.3 >> lambda_requirements.txt; echo boto3==1.26.137 >> lambda_requirements.txt; echo botocore==1.29.137 >> lambda_requirements.txt; Compress-Archive -Path 'lambda_function.py', 'lambda_requirements.txt' -DestinationPath 'deployment.zip' -Force"

aws lambda create-function --function-name heart-disease-prediction --runtime python3.9 --role arn:aws:iam::$(aws sts get-caller-identity --query Account --output text):role/lambda-execution-role --handler lambda_function.lambda_handler --zip-file fileb://deployment.zip --region us-east-1 --description "Heart Disease Prediction API" --timeout 30 --memory-size 512

echo Step 3: API Gateway...
for /f "tokens=*" %%i in ('aws apigateway create-rest-api --name "Heart Disease Prediction API" --description "API for Heart Disease Prediction" --region us-east-1 --query id --output text') do set apiId=%%i

aws apigateway put-method --rest-api-id %apiId% --resource-id %rootResourceId% --http-method POST --authorization-type NONE --region us-east-1

aws apigateway put-integration --rest-api-id %apiId% --resource-id %predictResourceId% --http-method POST --type AWS_PROXY --integration-http-method POST --uri "arn:aws:apigateway:us-east-1:lambda:path/2015-03-31/functions/arn:aws:lambda:us-east-1:$(aws sts get-caller-identity --query Account --output text):function:heart-disease-prediction/invocations" --region us-east-1

aws apigateway create-deployment --rest-api-id %apiId% --stage-name prod --region us-east-1

echo Step 4: Amplify...
amplify init -y
amplify add hosting -y
amplify publish -y

echo.
echo ==========================================
echo           DEPLOYMENT COMPLETE!
echo ==========================================
echo.
echo API: https://%apiId%.execute-api.us-east-1.amazonaws.com/prod/predict
echo Frontend: Check Amplify output above
echo.
pause
del deployment.zip
del lambda_requirements.txt
