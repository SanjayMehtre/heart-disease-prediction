# AWS Deployment Guide - MediCare Cardiac Center

## 🚀 Recommended AWS Architecture

### **Best Option: Serverless Architecture (Most Reliable & Cost-Effective)**

```
Frontend: AWS Amplify / S3 + CloudFront
Backend: AWS Lambda + API Gateway
Database: AWS DynamoDB (optional)
ML Model: AWS SageMaker Endpoint
```

## 📋 Deployment Options

### **Option 1: Serverless (Recommended - No Stuck Issues)**

#### **Frontend Deployment: AWS Amplify**
```bash
# 1. Install AWS Amplify CLI
npm install -g @aws-amplify/cli

# 2. Initialize Amplify in your project
amplify init

# 3. Add hosting
amplify add hosting

# 4. Deploy frontend
amplify publish
```

**Benefits:**
- ✅ Auto-scaling
- ✅ Global CDN (CloudFront)
- ✅ Custom domains
- ✅ Continuous deployment
- ✅ No server management

#### **Backend Deployment: AWS Lambda + API Gateway**

**Create Lambda Function:**
```python
# lambda_function.py
import json
import numpy as np
from datetime import datetime

def lambda_handler(event, context):
    try:
        # Get data from API Gateway
        data = json.loads(event['body'])
        
        # Extract features
        features = [
            float(data.get('age', 0)),
            float(data.get('sex', 0)),
            float(data.get('trestbps', 0)),
            float(data.get('chol', 0)),
            float(data.get('fbs', 0)),
            float(data.get('thalach', 0))
        ]
        
        # Your prediction logic here
        result = predict_heart_disease(features)
        
        return {
            'statusCode': 200,
            'headers': {
                'Content-Type': 'application/json',
                'Access-Control-Allow-Origin': '*'
            },
            'body': json.dumps({
                'success': True,
                'prediction': result
            })
        }
    except Exception as e:
        return {
            'statusCode': 500,
            'body': json.dumps({
                'success': False,
                'error': str(e)
            })
        }
```

**Deploy Lambda:**
```bash
# 1. Package your function
zip -r deployment.zip lambda_function.py

# 2. Create Lambda function
aws lambda create-function \
    --function-name heart-disease-prediction \
    --runtime python3.9 \
    --role arn:aws:iam::ACCOUNT:role/lambda-execution-role \
    --handler lambda_function.lambda_handler \
    --zip-file fileb://deployment.zip

# 3. Add API Gateway trigger
aws lambda add-permission \
    --function-name heart-disease-prediction \
    --statement-id apigateway-invoke \
    --action lambda:InvokeFunction \
    --principal apigateway.amazonaws.com
```

### **Option 2: Container-Based (ECS + Fargate)**

#### **Create Dockerfile:**
```dockerfile
# Dockerfile
FROM python:3.9-slim

WORKDIR /app

COPY requirements.txt .
RUN pip install -r requirements.txt

COPY . .

EXPOSE 5000

CMD ["gunicorn", "--bind", "0.0.0.0:5000", "app:app"]
```

#### **Create requirements.txt:**
```txt
Flask==2.3.2
numpy==1.24.3
pandas==1.5.3
gunicorn==20.1.0
```

#### **Deploy to ECS Fargate:**
```bash
# 1. Build and push Docker image
aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin ACCOUNT.dkr.ecr.us-east-1.amazonaws.com

docker build -t heart-disease-prediction .
docker tag heart-disease-prediction:latest ACCOUNT.dkr.ecr.us-east-1.amazonaws.com/heart-disease-prediction:latest

docker push ACCOUNT.dkr.ecr.us-east-1.amazonaws.com/heart-disease-prediction:latest

# 2. Create ECS task definition
aws ecs register-task-definition --cli-input-json file://task-definition.json

# 3. Create ECS service
aws ecs create-service --cluster heart-disease-cluster --service-name heart-disease-service --task-definition heart-disease-prediction
```

### **Option 3: Elastic Beanstalk (Easiest)**

```bash
# 1. Install EB CLI
pip install awsebcli

# 2. Initialize EB application
eb init heart-disease-prediction

# 3. Create environment
eb create production

# 4. Deploy
eb deploy
```

## 🔧 Configuration Files

### **Amplify Configuration (amplify.yml):**
```yaml
version: 1
frontend:
  phases:
    preBuild:
      commands:
        - npm ci
    build:
      commands:
        - npm run build
  artifacts:
    baseDirectory: .
    files:
      - '**/*'
  cache:
    paths:
      - node_modules/**/*
```

### **API Gateway Configuration:**
```json
{
  "openapi": "3.0.0",
  "info": {
    "title": "Heart Disease Prediction API",
    "version": "1.0.0"
  },
  "paths": {
    "/predict": {
      "post": {
        "x-amazon-apigateway-integration": {
          "uri": "arn:aws:apigateway:us-east-1:lambda:path/2015-03-31/functions/arn:aws:lambda:us-east-1:ACCOUNT:function:heart-disease-prediction/invocations",
          "httpMethod": "POST",
          "type": "aws_proxy"
        }
      }
    }
  }
}
```

## 🛡️ Security & Best Practices

### **IAM Roles:**
```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "logs:CreateLogGroup",
        "logs:CreateLogStream",
        "logs:PutLogEvents"
      ],
      "Resource": "arn:aws:logs:*:*:*"
    }
  ]
}
```

### **Environment Variables:**
```bash
# Lambda Environment Variables
FLASK_ENV=production
AWS_REGION=us-east-1
SAGE_MAKER_ENDPOINT=heart-disease-endpoint
```

## 📊 Monitoring & Logging

### **CloudWatch Monitoring:**
```python
import logging

logger = logging.getLogger()
logger.setLevel(logging.INFO)

def lambda_handler(event, context):
    logger.info(f"Processing request: {event}")
    # Your code here
    logger.info(f"Prediction result: {result}")
```

### **Health Check Endpoint:**
```python
@app.route('/health')
def health_check():
    return {
        'status': 'healthy',
        'timestamp': datetime.now().isoformat(),
        'version': '1.0.0'
    }
```

## 🚀 Deployment Steps

### **Step 1: Prepare Your Code**
```bash
# 1. Update frontend API endpoint
# In static/script.js, update:
const API_BASE_URL = 'https://your-api-gateway-url.execute-api.us-east-1.amazonaws.com/prod'

# 2. Test locally
python app.py
```

### **Step 2: Deploy Backend**
```bash
# Choose your deployment method:
# Option A: Lambda (Recommended)
./deploy_lambda.sh

# Option B: ECS
./deploy_ecs.sh

# Option C: Elastic Beanstalk
eb deploy
```

### **Step 3: Deploy Frontend**
```bash
# Option A: Amplify (Recommended)
amplify publish

# Option B: S3 + CloudFront
aws s3 sync ./dist s3://your-bucket-name
```

### **Step 4: Test Deployment**
```bash
# Test API endpoint
curl -X POST https://your-api-url/predict \
  -H "Content-Type: application/json" \
  -d '{"name":"Test","age":57,"sex":1,"trestbps":140,"chol":192,"fbs":0,"thalach":148}'
```

## 💰 Cost Optimization

### **Lambda Pricing:**
- **Free Tier**: 1M requests/month
- **Beyond**: $0.20 per 1M requests
- **Compute**: $0.0000166667 per GB-second

### **Amplify Pricing:**
- **Free Tier**: 15 GB storage, 5 GB data transfer
- **Beyond**: $0.02 per GB-month storage, $0.15 per GB data transfer

### **Monthly Estimate (Low Traffic):**
- **Lambda**: ~$5-10/month
- **API Gateway**: ~$3.50/month
- **Amplify**: ~$10-20/month
- **Total**: ~$20-35/month

## 🔧 Troubleshooting

### **Common Issues & Solutions:**

1. **CORS Errors:**
   ```python
   # Add to Flask app
   from flask_cors import CORS
   CORS(app)
   ```

2. **Lambda Timeouts:**
   ```bash
   # Increase timeout
   aws lambda update-function-configuration \
     --function-name heart-disease-prediction \
     --timeout 30
   ```

3. **Memory Issues:**
   ```bash
   # Increase memory
   aws lambda update-function-configuration \
     --function-name heart-disease-prediction \
     --memory-size 512
   ```

4. **API Gateway Throttling:**
   ```bash
   # Increase rate limit
   aws apigateway update-stage \
     --rest-api-id your-api-id \
     --stage-name prod \
     --patch-operations op=replace,path=/~1throttling/burstLimit,value=1000
   ```

## 📱 CI/CD Pipeline

### **GitHub Actions:**
```yaml
name: Deploy to AWS
on:
  push:
    branches: [ main ]

jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
    - uses: actions/checkout@v2
    - name: Deploy to AWS
      run: |
        aws amplify start-deployment --app-id your-app-id --branch-name main --job-id $(uuidgen)
```

## 🎯 Recommendation

**For your use case, I recommend:**
1. **Frontend**: AWS Amplify (easiest, most reliable)
2. **Backend**: AWS Lambda + API Gateway (serverless, no stuck issues)
3. **ML Model**: Keep using SageMaker
4. **Database**: Not needed for your current use case

This setup ensures:
- ✅ No stuck deployments
- ✅ Auto-scaling
- ✅ Cost-effective
- ✅ High reliability
- ✅ Easy maintenance
