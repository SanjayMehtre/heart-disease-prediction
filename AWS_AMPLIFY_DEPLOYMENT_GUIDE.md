# AWS Amplify Deployment Guide for MediCare Cardiac Center

## 🚀 **Complete AWS Deployment Strategy**

This guide shows how to deploy the **MediCare Cardiac Center** to AWS Amplify with SageMaker integration.

---

## 📋 **Architecture Overview**

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   AWS Amplify  │    │   API Gateway  │    │  AWS SageMaker  │
│   (Frontend)   │◄──►│   (Backend)    │◄──►│   (ML Model)    │
│  Static Files   │    │   REST API     │    │  Predictions    │
└─────────────────┘    └─────────────────┘    └─────────────────┘
```

---

## 🎯 **Where SageMaker is Used**

### **1. Machine Learning Model Hosting**
- **File**: `app.py` lines 44-77
- **Function**: `predict_with_sagemaker()`
- **Purpose**: Calls trained ML model for heart disease prediction
- **Endpoint**: Configurable via `SAGEMAKER_ENDPOINT_NAME` environment variable

### **2. Production Predictions**
- **Fallback**: Uses local logic if SageMaker unavailable
- **Integration**: Seamless switching between SageMaker and local model
- **Response**: Returns predictions with confidence scores

### **3. Model Information Display**
- **UI**: Shows whether using SageMaker or local model
- **Endpoint**: Displays SageMaker endpoint details
- **Status**: Health check endpoint shows model availability

---

## 🛠️ **Step 1: AWS SageMaker Setup**

### **1.1 Create SageMaker Model**
```python
# In your SageMaker notebook or console
import sagemaker
from sagemaker.sklearn import SKLearn

# Train and deploy model
estimator = SKLearn(entry_point='train.py',
                  role='SageMakerExecutionRole',
                  instance_type='ml.m5.large',
                  framework_version='1.2-1')

estimator.fit({'train': s3_train_data})
predictor = estimator.deploy(initial_instance_count=1,
                         instance_type='ml.m5.large',
                         endpoint_name='heart-disease-prediction-endpoint')
```

### **1.2 Configure Endpoint**
```bash
# Set environment variables
export SAGEMAKER_ENDPOINT_NAME=heart-disease-prediction-endpoint
export AWS_REGION=us-east-1
```

---

## 🚀 **Step 2: AWS Amplify Deployment**

### **2.1 Prerequisites**
```bash
# Install AWS CLI
npm install -g @aws-amplify/cli

# Configure AWS credentials
aws configure
```

### **2.2 Initialize Amplify**
```bash
# Navigate to project directory
cd aws-sagemaker-heart-disease-prediction-master

# Initialize Amplify
amplify init

# Choose:
# - Default editor: VS Code
# - Type of app: JavaScript
# - Framework: None (static HTML/CSS/JS)
# - Distribution directory: static
# - Build command: echo "No build required"
# - Start command: python app.py
```

### **2.3 Add Hosting**
```bash
# Add hosting
amplify add hosting

# Choose:
# - Plugin type: Hosting - Amplify Console (Managed)
# - Environment: dev
# - Custom domain: (optional)
```

### **2.4 Deploy to Amplify**
```bash
# Deploy frontend
amplify publish

# Your app will be available at:
# https://dev.xxxxxx.amplifyapp.com
```

---

## 🔧 **Step 3: Backend Deployment (Lambda + API Gateway)**

### **3.1 Deploy Lambda Function**
```bash
# Package Lambda function
zip lambda_function.zip lambda_function.py

# Deploy Lambda
aws lambda create-function \
    --function-name heart-disease-prediction \
    --runtime python3.8 \
    --role arn:aws:iam::ACCOUNT:role/lambda-execution-role \
    --handler lambda_function.lambda_handler \
    --zip-file fileb://lambda_function.zip \
    --environment Variables="{SAGEMAKER_ENDPOINT_NAME=heart-disease-prediction-endpoint,AWS_REGION=us-east-1}"
```

### **3.2 Create API Gateway**
```bash
# Create REST API
aws apigateway create-rest-api --name heart-disease-api

# Deploy API
aws apigateway create-deployment \
    --rest-api-id YOUR_API_ID \
    --stage-name prod
```

### **3.3 Update Frontend API Endpoint**
```javascript
// In static/script.js line 95
const response = await fetch('https://YOUR_API.execute-api.us-east-1.amazonaws.com/prod/predict', {
    method: 'POST',
    headers: {
        'Content-Type': 'application/json',
    },
    body: JSON.stringify(data)
});
```

---

## 🔐 **Step 4: IAM Configuration**

### **4.1 SageMaker Execution Role**
```json
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "sagemaker:InvokeEndpoint",
                "sagemaker:GetEndpoint",
                "sagemaker:ListEndpoints"
            ],
            "Resource": "*"
        },
        {
            "Effect": "Allow",
            "Action": [
                "logs:CreateLogGroup",
                "logs:CreateLogStream",
                "logs:PutLogEvents"
            ],
            "Resource": "*"
        }
    ]
}
```

### **4.2 Lambda Execution Role**
```json
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "sagemaker:InvokeEndpoint"
            ],
            "Resource": "arn:aws:sagemaker:*:*:endpoint/heart-disease-prediction-endpoint"
        },
        {
            "Effect": "Allow",
            "Action": [
                "logs:CreateLogGroup",
                "logs:CreateLogStream",
                "logs:PutLogEvents"
            ],
            "Resource": "*"
        }
    ]
}
```

---

## 🌐 **Step 5: GitHub Integration (Optional)**

### **5.1 Connect GitHub Repository**
```bash
# Initialize git
git init
git add .
git commit -m "Initial commit"

# Add remote
git remote add origin https://github.com/YOUR_USERNAME/heart-disease-prediction.git
git push -u origin main
```

### **5.2 Amplify GitHub Integration**
```bash
# Connect to GitHub in Amplify Console
# 1. Go to AWS Amplify Console
# 2. Click "Connect app"
# 3. Choose GitHub
# 4. Select repository and branch
# 5. Configure build settings
```

---

## 📊 **Step 6: Monitoring & Testing**

### **6.1 Health Check Endpoint**
```bash
# Test health
curl https://your-app.amplifyapp.com/health

# Response:
{
    "status": "healthy",
    "sagemaker_available": true,
    "endpoint_name": "heart-disease-prediction-endpoint",
    "timestamp": "2026-05-12T14:30:00.000Z"
}
```

### **6.2 Test Prediction**
```bash
# Test prediction endpoint
curl -X POST https://your-api.execute-api.us-east-1.amazonaws.com/prod/predict \
  -H "Content-Type: application/json" \
  -d '{
    "name": "John Doe",
    "age": 57,
    "sex": 1,
    "trestbps": 140,
    "chol": 192,
    "fbs": 0,
    "thalach": 148
  }'
```

---

## 🎯 **Production URLs**

### **Frontend (Amplify)**
- **URL**: `https://your-app-name.amplifyapp.com`
- **Purpose**: Static HTML/CSS/JS files
- **Features**: Medical form, results display, signup page

### **Backend (API Gateway)**
- **URL**: `https://your-api.execute-api.us-east-1.amazonaws.com/prod`
- **Purpose**: REST API for predictions
- **Endpoints**: `/predict`, `/health`, `/signup`

### **ML Model (SageMaker)**
- **Endpoint**: `heart-disease-prediction-endpoint`
- **Purpose**: Machine learning predictions
- **Integration**: Called by Lambda function

---

## 🚀 **Deployment Commands Summary**

```bash
# 1. Deploy to Amplify
amplify publish

# 2. Deploy Lambda
aws lambda update-function-code \
    --function-name heart-disease-prediction \
    --zip-file fileb://lambda_function.zip

# 3. Update API Gateway
aws apigateway create-deployment \
    --rest-api-id YOUR_API_ID \
    --stage-name prod
```

---

## 🔧 **Environment Variables**

| Variable | Value | Purpose |
|----------|--------|---------|
| `SAGEMAKER_ENDPOINT_NAME` | `heart-disease-prediction-endpoint` | SageMaker endpoint |
| `AWS_REGION` | `us-east-1` | AWS region |
| `FLASK_ENV` | `production` | Flask environment |

---

## 📱 **Access Your Deployed Application**

1. **Frontend**: `https://your-app-name.amplifyapp.com`
2. **API Health**: `https://your-api.execute-api.us-east-1.amazonaws.com/prod/health`
3. **Prediction**: `https://your-api.execute-api.us-east-1.amazonaws.com/prod/predict`

---

## 🎉 **Success Indicators**

✅ **Amplify**: Static files served globally  
✅ **API Gateway**: REST API accessible  
✅ **Lambda**: Function executes predictions  
✅ **SageMaker**: ML model responding  
✅ **Integration**: All services connected  
✅ **Monitoring**: Health checks working  

---

## 🔄 **CI/CD Pipeline**

```yaml
# amplify.yml (already in project)
version: 1
frontend:
  phases:
    preBuild:
      commands:
        - echo "No build required for static files"
    build:
      commands:
        - echo "Build complete"
  artifacts:
    baseDirectory: static
    files:
      - '**/*'
```

---

**🎯 Your MediCare Cardiac Center is now fully deployed on AWS with SageMaker integration!**
