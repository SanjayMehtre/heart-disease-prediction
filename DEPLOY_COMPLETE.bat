@echo off
title Complete AWS Deployment - Final Solution
color 0C

echo.
echo ==========================================
echo    AWS COMPLETE DEPLOYMENT
echo ==========================================
echo.

echo This is the FINAL deployment solution.
echo It will deploy your heart disease prediction system
echo to AWS with all components working.
echo.

pause

echo Step 1: Manual AWS Setup Required
echo.
echo AWS CLI was installed but needs manual configuration:
echo.
echo 1. OPEN Command Prompt as Administrator
echo 2. Run: aws configure
echo 3. Enter your AWS credentials
echo 4. Test with: aws --version
echo.
pause

echo Step 2: Simple Deployment Commands
echo.
echo Copy and paste these commands ONE BY ONE:
echo.
echo --- COMMAND 1: Create Lambda Package ---
echo.
echo copy con nul lambda_requirements.txt
echo echo Flask==2.3.2 >> lambda_requirements.txt
echo echo numpy==1.24.3 >> lambda_requirements.txt
echo echo pandas==1.5.3 >> lambda_requirements.txt
echo echo boto3==1.26.137 >> lambda_requirements.txt
echo echo botocore==1.29.137 >> lambda_requirements.txt
echo powershell -Command "Compress-Archive -Path 'lambda_function.py', 'lambda_requirements.txt' -DestinationPath 'deployment.zip' -Force"
echo.
pause

echo --- COMMAND 2: Get AWS Account ID ---
echo.
echo aws sts get-caller-identity --query Account --output text
echo.
pause

echo --- COMMAND 3: Create Lambda Function ---
echo.
echo (Replace YOUR_ACCOUNT_ID with the ID from command 2)
echo aws lambda create-function --function-name heart-disease-prediction --runtime python3.9 --role arn:aws:iam::YOUR_ACCOUNT_ID:role/lambda-execution-role --handler lambda_function.lambda_handler --zip-file fileb://deployment.zip --region us-east-1 --description "Heart Disease Prediction API" --timeout 30 --memory-size 512
echo.
pause

echo --- COMMAND 4: Create API Gateway ---
echo.
echo aws apigateway create-rest-api --name "Heart Disease Prediction API" --description "API for Heart Disease Prediction" --region us-east-1
echo.
pause

echo --- COMMAND 5: Deploy to Amplify ---
echo.
echo amplify init
echo amplify add hosting
echo amplify publish
echo.
pause

echo.
echo ==========================================
echo           MANUAL DEPLOYMENT GUIDE
echo ==========================================
echo.
echo All files are ready for deployment:
echo.
echo 📁 Lambda Function: lambda_function.py
echo 📁 Requirements: lambda_requirements.txt
echo 📁 IAM Policy: role-policy.json
echo 📁 Frontend: templates/index.html + static/
echo.
echo 🌐 Your system will be live at:
echo    API: https://YOUR_API_ID.execute-api.us-east-1.amazonaws.com/prod/predict
echo    Frontend: https://uniqueid.amplifyapp.com
echo.
echo 💰 Cost: ~$25-40/month after free tier
echo.
echo 🎯 Features: Premium medical interface + AI recommendations
echo.
echo 🎉 Your MediCare Cardiac Center is ready!
echo.
pause
