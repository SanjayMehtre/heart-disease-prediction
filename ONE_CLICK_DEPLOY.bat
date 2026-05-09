@echo off
title One Click AWS Deploy
color 0F

echo.
echo ==========================================
echo    ONE CLICK AWS DEPLOY
echo ==========================================
echo.
echo This will deploy your complete system!
echo.

echo Opening AWS configuration...
start /wait cmd /c "aws configure && pause"

echo.
echo Deploying Lambda + API Gateway + Amplify...
echo.

echo Creating Lambda package...
powershell -Command "$req = 'Flask==2.3.2','numpy==1.24.3','pandas==1.5.3','boto3==1.26.137','botocore==1.29.137'; $req | Out-File -FilePath 'lambda_requirements.txt' -Encoding UTF8; Compress-Archive -Path 'lambda_function.py','lambda_requirements.txt' -DestinationPath 'deployment.zip' -Force"

echo Deploying Lambda...
powershell -Command "$acc = aws sts get-caller-identity --query Account --output text; aws lambda create-function --function-name heart-disease-prediction --runtime python3.9 --role arn:aws:iam::$acc`:role/lambda-execution-role --handler lambda_function.lambda_handler --zip-file fileb://deployment.zip --region us-east-1 --description 'Heart Disease Prediction API' --timeout 30 --memory-size 512"

echo Creating API Gateway...
powershell -Command "$api = aws apigateway create-rest-api --name 'Heart Disease Prediction API' --description 'API for Heart Disease Prediction' --region us-east-1 --query id --output text; $root = aws apigateway get-resources --rest-api-id $api --query 'items[0].id' --output text; $res = aws apigateway create-resource --rest-api-id $api --parent-id $root --path-part 'predict' --region us-east-1 --query id --output text; aws apigateway put-method --rest-api-id $api --resource-id $res --http-method POST --authorization-type NONE --region us-east-1; $uri = 'arn:aws:apigateway:us-east-1:lambda:path/2015-03-31/functions/arn:aws:lambda:us-east-1:' + $acc + ':function:heart-disease-prediction/invocations'; aws apigateway put-integration --rest-api-id $api --resource-id $res --http-method POST --type AWS_PROXY --integration-http-method POST --uri $uri --region us-east-1; aws lambda add-permission --function-name heart-disease-prediction --statement-id apigateway-invoke --action lambda:InvokeFunction --principal apigateway.amazonaws.com --source-arn 'arn:aws:execute-api:us-east-1:' + $acc + ':' + $api + '/POST/predict'; aws apigateway create-deployment --rest-api-id $api --stage-name prod --region us-east-1; $url = 'https://' + $api + '.execute-api.us-east-1.amazonaws.com/prod/predict'; Write-Host 'API URL:' $url -ForegroundColor Green"

echo Updating frontend...
powershell -Command "(Get-Content 'static\script.js') -replace 'http://127.0.0.1:5000/predict', $url | Set-Content 'static\script.js'"

echo Deploying to Amplify...
powershell -Command "amplify init -y; amplify add hosting -y; amplify publish -y"

echo.
echo ==========================================
echo           DEPLOYMENT COMPLETE!
echo ==========================================
echo.
echo 🎉 Your MediCare Cardiac Center is LIVE!
echo.
echo Check Amplify output above for your frontend URL
echo.
pause
del deployment.zip
del lambda_requirements.txt
