# 🚀 DEPLOY NOW - Complete AWS Deployment

## ⚡ Quick Start - Deploy Your Heart Disease Prediction System

### **Step 1: Restart Your Terminal**
The AWS CLI was just installed. Please:
1. **Close this terminal window**
2. **Open a new terminal** (Command Prompt or PowerShell)
3. **Navigate back to project folder**:
   ```bash
   cd "c:\Users\sanja\OneDrive\Documents\Desktop\cc\aws-sagemaker-heart-disease-prediction-master"
   ```

### **Step 2: Configure AWS Credentials**
```bash
aws configure
```
Enter your AWS Access Key ID and Secret Access Key
(You can get these from AWS Console → IAM → Users → Security Credentials)

### **Step 3: Deploy Everything**
```bash
final_deploy.bat
```

This single command will:
- ✅ Deploy Lambda function
- ✅ Create API Gateway
- ✅ Deploy to Amplify
- ✅ Test everything
- ✅ Give you your live URLs

## 🌐 What You'll Get

After deployment, you'll have:

### **Live URLs:**
- **API Endpoint**: `https://YOUR_API_ID.execute-api.us-east-1.amazonaws.com/prod/predict`
- **Frontend URL**: `https://uniqueid.amplifyapp.com`

### **Features:**
- ✅ Premium medical interface
- ✅ AI treatment recommendations
- ✅ SageMaker integration ready
- ✅ Global CDN (fast worldwide)
- ✅ Auto-scaling
- ✅ SSL certificates

## 🎯 If You Want Manual Control

### **Option A: Step-by-Step**
```bash
# 1. Create Lambda package
echo Flask==2.3.2 > lambda_requirements.txt
echo numpy==1.24.3 >> lambda_requirements.txt
echo pandas==1.5.3 >> lambda_requirements.txt
echo boto3==1.26.137 >> lambda_requirements.txt
echo botocore==1.29.137 >> lambda_requirements.txt
powershell -Command "Compress-Archive -Path 'lambda_function.py', 'lambda_requirements.txt' -DestinationPath 'deployment.zip' -Force"

# 2. Get AWS Account ID
aws sts get-caller-identity --query Account --output text

# 3. Create IAM Role
aws iam create-role --role-name lambda-execution-role --assume-role-policy-document file://role-policy.json
aws iam attach-role-policy --role-name lambda-execution-role --policy-arn arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole

# 4. Deploy Lambda (replace YOUR_ACCOUNT_ID)
aws lambda create-function --function-name heart-disease-prediction --runtime python3.9 --role arn:aws:iam::YOUR_ACCOUNT_ID:role/lambda-execution-role --handler lambda_function.lambda_handler --zip-file fileb://deployment.zip --region us-east-1 --description "Heart Disease Prediction API" --timeout 30 --memory-size 512

# 5. Create API Gateway
aws apigateway create-rest-api --name "Heart Disease Prediction API" --description "API for Heart Disease Prediction" --region us-east-1

# 6. Deploy to Amplify
amplify init
amplify add hosting
amplify publish
```

### **Option B: Use Amplify Console**
1. Go to https://console.aws.amazon.com/amplify/
2. Click "Deploy app"
3. Choose "GitHub" or "Git provider"
4. Connect your repository
5. Build settings will be auto-configured
6. Deploy

## 💰 Cost Estimate

- **First 12 months**: Free tier covers most usage
- **After free tier**: ~$25-40/month total
  - Lambda: ~$5-10/month
  - API Gateway: ~$3.50/month
  - Amplify: ~$15-25/month

## 🧪 Test Your Deployment

After deployment, test with:
```bash
# Test API (replace YOUR_API_ID)
curl -X POST https://YOUR_API_ID.execute-api.us-east-1.amazonaws.com/prod/predict \
  -H "Content-Type: application/json" \
  -d '{"name":"Test Patient","age":57,"sex":1,"trestbps":140,"chol":192,"fbs":0,"thalach":148}'
```

## 🔧 Enable SageMaker (Optional)

1. Deploy your model to SageMaker endpoint
2. Update Lambda environment variables:
   ```bash
   aws lambda update-function-configuration --function-name heart-disease-prediction --environment Variables="{FLASK_ENV=production,AWS_REGION=us-east-1,USE_SAGEMAKER=true,SAGEMAKER_ENDPOINT=your-endpoint-name}" --region us-east-1
   ```

## 🎉 Success!

Your **MediCare Cardiac Center** will be live with:
- 🏥 Professional medical interface
- 🤖 AI-powered treatment recommendations
- 🌍 Global accessibility
- 🔒 Secure and scalable
- 💰 Cost-effective

**🚀 Just restart your terminal and run `final_deploy.bat` to go live!**
