# Manual AWS Setup Guide for Windows

## 🔧 **AWS CLI Installation & Configuration**

### **Step 1: Install AWS CLI on Windows**

#### **Option A: Download MSI Installer**
1. Go to: https://aws.amazon.com/cli/
2. Click "Download AWS CLI v2"
3. Download the 64-bit MSI installer
4. Run the installer with Administrator privileges
5. Follow the installation wizard

#### **Option B: Using PowerShell (Admin)**
```powershell
# Run PowerShell as Administrator
Invoke-WebRequest -Uri https://awscli.amazonaws.com/awscli-exe-windows-x86_64.zip -OutFile awscliv2.zip
Expand-Archive awscliv2.zip
.\aws\install.exe
```

### **Step 2: Verify Installation**
```powershell
# Open new PowerShell window
aws --version
# Should show: aws-cli/2.x.x
```

### **Step 3: Configure AWS Credentials**
```powershell
# Configure AWS CLI
aws configure

# Enter your AWS credentials:
# AWS Access Key ID: YOUR_ACCESS_KEY
# AWS Secret Access Key: YOUR_SECRET_KEY
# Default region name: us-east-1
# Default output format: json
```

---

## 🚀 **Manual AWS Amplify Deployment**

### **Step 1: Create AWS Amplify App via Console**

1. **Go to AWS Management Console**
   - URL: https://console.aws.amazon.com/
   - Sign in with your AWS account

2. **Navigate to Amplify**
   - Search "Amplify" in services
   - Click "Amplify"

3. **Create New App**
   - Click "Create app"
   - Choose "Host your web app"
   - Select "GitHub" (if connected) or "Deploy without Git"

4. **Configure Build Settings**
   ```
   App name: heart-disease-prediction
   Environment: dev
   Build command: echo "No build required"
   Build output: static
   ```

### **Step 2: Upload Files Manually**

#### **Option A: Using AWS Console**
1. **Upload Static Files**
   - Go to Amplify Console
   - Select your app
   - Click "Hosting"
   - Click "Upload files"
   - Upload entire `static` folder

2. **Upload Application Files**
   - Upload `templates/index.html`
   - Upload `templates/signup.html`
   - Upload `app.py` (for backend)

#### **Option B: Using AWS CLI**
```powershell
# Navigate to project directory
cd "C:\Users\sanja\OneDrive\Documents\Desktop\cc\aws-sagemaker-heart-disease-prediction-master"

# Create S3 bucket for static files
aws s3 mb s3://heart-disease-static-files

# Upload static files
aws s3 sync static/ s3://heart-disease-static-files/ --delete

# Upload templates
aws s3 sync templates/ s3://heart-disease-static-files/templates/ --delete

# Upload Python files
aws s3 cp app.py s3://heart-disease-static-files/
aws s3 cp lambda_function.py s3://heart-disease-static-files/
aws s3 cp requirements.txt s3://heart-disease-static-files/
```

---

## 🔧 **Manual AWS Lambda Deployment**

### **Step 1: Create Lambda Function via Console**

1. **Go to Lambda Console**
   - Search "Lambda" in AWS services
   - Click "Create function"

2. **Configure Function**
   ```
   Function name: heart-disease-prediction
   Runtime: Python 3.8
   Architecture: x86_64
   Permissions: Create a new role with basic Lambda permissions
   ```

3. **Upload Code**
   - Click "Upload from .zip file"
   - Create zip file:
   ```powershell
   # Create zip file
   Compress-Archive -Path lambda_function.py -DestinationPath lambda_function.zip
   ```
   - Upload `lambda_function.zip`

### **Step 2: Configure Environment Variables**
```
SAGEMAKER_ENDPOINT_NAME = heart-disease-prediction-endpoint
AWS_REGION = us-east-1
FLASK_ENV = production
```

### **Step 3: Set Memory and Timeout**
```
Memory: 512 MB
Timeout: 30 seconds
```

---

## 🌐 **Manual API Gateway Setup**

### **Step 1: Create REST API**

1. **Go to API Gateway Console**
   - Search "API Gateway" in AWS services
   - Click "Create API"

2. **Configure API**
   ```
   API type: REST API
   Protocol: REST
   Create new API: New API
   API name: heart-disease-api
   Description: Heart Disease Prediction API
   ```

### **Step 2: Create Resources**
```
Resource: /predict
Method: POST
Integration type: Lambda function
Lambda function: heart-disease-prediction
```

### **Step 3: Deploy API**
```
Stage: prod
Stage description: Production stage
```

### **Step 4: Get API URL**
```
Your API URL: https://YOUR_API_ID.execute-api.us-east-1.amazonaws.com/prod
```

---

## 🤖 **Manual SageMaker Setup**

### **Step 1: Create SageMaker Endpoint**

1. **Go to SageMaker Console**
   - Search "SageMaker" in AWS services
   - Click "Inference" → "Endpoints"

2. **Create Endpoint**
   ```
   Endpoint name: heart-disease-prediction-endpoint
   Instance type: ml.m5.large
   Initial instance count: 1
   ```

3. **Attach Model**
   - Select your trained model
   - Choose the model version
   - Attach to endpoint

### **Step 2: Configure IAM Permissions**

1. **Create IAM Role**
   ```json
   {
     "Version": "2012-10-17",
     "Statement": [
       {
         "Effect": "Allow",
         "Action": [
           "sagemaker:InvokeEndpoint",
           "sagemaker:GetEndpoint"
         ],
         "Resource": "arn:aws:sagemaker:*:*:endpoint/heart-disease-prediction-endpoint"
       }
     ]
   }
   ```

2. **Attach Role to Lambda**
   - Go to Lambda function
   - Configuration → Permissions
   - Edit execution role

---

## 🔗 **Connect Components**

### **Step 1: Update Frontend API URL**

Edit `static/script.js` line 95:
```javascript
const response = await fetch('https://YOUR_API_ID.execute-api.us-east-1.amazonaws.com/prod/predict', {
    method: 'POST',
    headers: {
        'Content-Type': 'application/json',
    },
    body: JSON.stringify(data)
});
```

### **Step 2: Update Lambda Environment**
```json
{
  "Variables": {
    "SAGEMAKER_ENDPOINT_NAME": "heart-disease-prediction-endpoint",
    "AWS_REGION": "us-east-1",
    "FLASK_ENV": "production"
  }
}
```

---

## 🧪 **Testing Manual Deployment**

### **Step 1: Test Local Application**
```powershell
# Navigate to project
cd "C:\Users\sanja\OneDrive\Documents\Desktop\cc\aws-sagemaker-heart-disease-prediction-master"

# Run local test
powershell -ExecutionPolicy Bypass -File .\TEST_APP.ps1
```

### **Step 2: Test API Gateway**
```powershell
# Test API endpoint
curl -X POST https://YOUR_API_ID.execute-api.us-east-1.amazonaws.com/prod/predict `
  -H "Content-Type: application/json" `
  -d '{"name":"Test User","age":57,"sex":1,"trestbps":140,"chol":192,"fbs":0,"thalach":148}'
```

### **Step 3: Test Health Check**
```powershell
curl https://YOUR_API_ID.execute-api.us-east-1.amazonaws.com/prod/health
```

---

## 🔧 **Windows-Specific Commands**

### **PowerShell AWS Commands**
```powershell
# List S3 buckets
aws s3 ls

# Upload files
aws s3 cp .\static\index.html s3://your-bucket/

# Create Lambda function
aws lambda create-function --function-name test --runtime python3.8 --handler lambda_function.lambda_handler --zip-file fileb://lambda_function.zip

# Update Lambda function
aws lambda update-function-code --function-name heart-disease-prediction --zip-file fileb://lambda_function.zip
```

### **Batch File for Deployment**
```batch
@echo off
title AWS Deployment
color 0A

echo ==========================================
echo    Deploying to AWS
echo ==========================================

echo Uploading static files...
aws s3 sync static/ s3://heart-disease-static-files/ --delete

echo Updating Lambda function...
aws lambda update-function-code --function-name heart-disease-prediction --zip-file fileb://lambda_function.zip

echo Deployment complete!
pause
```

---

## 🎯 **Manual Deployment Checklist**

### **Prerequisites**
- [ ] AWS CLI installed and configured
- [ ] Node.js and npm installed
- [ ] Python 3.8+ installed
- [ ] AWS account with appropriate permissions

### **Frontend (Amplify)**
- [ ] Static files uploaded to S3 or Amplify
- [ ] Custom domain configured (optional)
- [ ] SSL certificate enabled
- [ ] Build settings configured

### **Backend (Lambda + API Gateway)**
- [ ] Lambda function created and code uploaded
- [ ] Environment variables set
- [ ] IAM permissions configured
- [ ] API Gateway created and deployed
- [ ] CORS settings configured

### **ML Model (SageMaker)**
- [ ] SageMaker endpoint created
- [ ] Model deployed to endpoint
- [ ] Lambda has SageMaker permissions
- [ ] Endpoint is healthy and responding

### **Integration**
- [ ] Frontend API URL updated
- [ ] Backend environment variables set
- [ ] End-to-end testing complete
- [ ] Health checks passing

---

## 🚨 **Troubleshooting**

### **Common Issues**
1. **AWS CLI not found**
   - Restart PowerShell
   - Check PATH environment variable
   - Reinstall AWS CLI

2. **Permission denied**
   - Run PowerShell as Administrator
   - Check IAM permissions
   - Verify AWS credentials

3. **CORS errors**
   - Configure CORS in API Gateway
   - Add appropriate headers
   - Test with different origins

4. **SageMaker endpoint not found**
   - Verify endpoint name
   - Check region settings
   - Confirm endpoint is "InService"

---

## 📱 **Access Your Application**

After manual deployment:

- **Frontend**: Your Amplify URL
- **API**: Your API Gateway URL
- **Health Check**: `https://your-api/health`
- **Predictions**: `https://your-api/predict`

---

**🎉 Your MediCare Cardiac Center is now manually deployed to AWS!**
