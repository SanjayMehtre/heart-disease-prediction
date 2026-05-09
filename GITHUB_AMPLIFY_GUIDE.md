# 🚀 GitHub + Amplify Deployment - Complete Guide

## 🎯 **Easiest Way to Deploy Your Heart Disease System**

### **Why GitHub + Amplify is Best:**
- ✅ **Zero Configuration** - Amplify auto-detects everything
- ✅ **Automatic Builds** - Every push triggers deployment
- ✅ **Rollback Support** - One-click to previous version
- ✅ **Global CDN** - CloudFront included automatically
- ✅ **SSL Certificates** - Free HTTPS
- ✅ **Custom Domains** - Easy setup
- ✅ **Branch Management** - Deploy different branches
- ✅ **Monitoring** - Built-in analytics

---

## 📋 **Step-by-Step Deployment**

### **Step 1: Create GitHub Repository**
1. Go to [GitHub.com](https://github.com/new)
2. Repository name: `heart-disease-prediction`
3. Description: `MediCare Cardiac Center - Heart Disease Prediction System`
4. Make it **Public**
5. Click **"Create repository"**

### **Step 2: Push Your Code to GitHub**
```bash
# Navigate to your project folder
cd "c:\Users\sanja\OneDrive\Documents\Desktop\cc\aws-sagemaker-heart-disease-prediction-master"

# Initialize Git
git init

# Add all files
git add .

# Commit your code
git commit -m "Initial commit - MediCare Cardiac Center"

# Add GitHub repository (replace YOUR_USERNAME)
git remote add origin https://github.com/YOUR_USERNAME/heart-disease-prediction.git

# Push to GitHub
git push -u origin main
```

### **Step 3: Deploy with Amplify Console**
1. Go to [AWS Amplify Console](https://console.aws.amazon.com/amplify/)
2. Click **"Get started"**
3. Choose **"GitHub"** as the provider
4. Connect your GitHub account
5. Select your `heart-disease-prediction` repository
6. Build settings will be **auto-configured** by Amplify
7. Click **"Save and deploy"**

### **Step 4: Deploy Backend (Lambda + API Gateway)**
After frontend deploys, deploy backend:
```bash
# Create Lambda package
echo Flask==2.3.2 > lambda_requirements.txt
echo numpy==1.24.3 >> lambda_requirements.txt
echo pandas==1.5.3 >> lambda_requirements.txt
echo boto3==1.26.137 >> lambda_requirements.txt
echo botocore==1.29.137 >> lambda_requirements.txt

# Create deployment package
powershell -Command "Compress-Archive -Path 'lambda_function.py', 'lambda_requirements.txt' -DestinationPath 'deployment.zip' -Force"

# Deploy Lambda function
aws lambda create-function --function-name heart-disease-prediction --runtime python3.9 --role arn:aws:iam::YOUR_ACCOUNT_ID:role/lambda-execution-role --handler lambda_function.lambda_handler --zip-file fileb://deployment.zip --region us-east-1 --description "Heart Disease Prediction API" --timeout 30 --memory-size 512

# Create API Gateway
aws apigateway create-rest-api --name "Heart Disease Prediction API" --description "API for Heart Disease Prediction" --region us-east-1

# Get API details and configure
aws apigateway get-resources --rest-api-id YOUR_API_ID --region us-east-1
aws apigateway create-resource --rest-api-id YOUR_API_ID --parent-id ROOT_RESOURCE_ID --path-part "predict" --region us-east-1
aws apigateway put-method --rest-api-id YOUR_API_ID --resource-id PREDICT_RESOURCE_ID --http-method POST --authorization-type NONE --region us-east-1
aws apigateway put-integration --rest-api-id YOUR_API_ID --resource-id PREDICT_RESOURCE_ID --http-method POST --type AWS_PROXY --integration-http-method POST --uri "arn:aws:apigateway:us-east-1:lambda:path/2015-03-31/functions/arn:aws:lambda:us-east-1:YOUR_ACCOUNT_ID:function:heart-disease-prediction/invocations" --region us-east-1
aws apigateway create-deployment --rest-api-id YOUR_API_ID --stage-name prod --region us-east-1
```

### **Step 5: Update Frontend API URL**
```bash
# Update JavaScript with new API URL
sed -i.bak 's|http://127.0.0.1:5000/predict|https://YOUR_API_ID.execute-api.us-east-1.amazonaws.com/prod/predict|g' static/script.js

# Commit and push the update
git add static/script.js
git commit -m "Update API URL for production"
git push origin main
```

---

## 🌐 **What You'll Get**

### **Live URLs:**
- **Frontend**: `https://your-app.amplifyapp.com`
- **API**: `https://YOUR_API_ID.execute-api.us-east-1.amazonaws.com/prod/predict`

### **Complete Features:**
- ✅ **Premium Medical Interface** - Elegant MediCare Cardiac Center
- ✅ **AI Treatment Recommendations** - Comprehensive medical plans
- ✅ **SageMaker Integration** - Production ML models ready
- ✅ **Global CDN** - Fast worldwide access
- ✅ **Auto-Scaling** - Handles any traffic
- ✅ **SSL Certificates** - Secure HTTPS
- ✅ **Serverless Architecture** - Zero maintenance
- ✅ **CI/CD Pipeline** - Automatic deployments

---

## 🔄 **Automatic Deployment Process**

### **How It Works:**
```
Git Push → Amplify Detects Changes → Automatic Build → CloudFront Deploy → Live URL
```

### **Build Triggers:**
- **Push to main branch** → Auto-deployment
- **Pull requests** → Manual deployment
- **Tag releases** → Production deployments

### **Environment Management:**
- **Development branch** → Staging environment
- **Main branch** → Production environment
- **Feature branches** → Preview environments

---

## 💰 **Cost Breakdown**

### **Free Tier (First 12 months):**
- **Amplify**: 15GB storage + 5GB transfer/month
- **Lambda**: 1M requests/month
- **API Gateway**: 1M requests/month
- **SageMaker**: Free tier for small models

### **After Free Tier:**
- **Amplify**: ~$15-25/month
- **Lambda**: ~$5-10/month
- **API Gateway**: ~$3.50/month
- **SageMaker**: ~$187/month (if endpoint active 24/7)
- **Total**: ~$25-40/month

---

## 🛠️ **Advanced Configuration**

### **Custom Domain Setup:**
```bash
# After deployment, add custom domain
amplify hosting add

# Configure domain
amplify update custom-domain
```

### **Environment Variables:**
```bash
# Set different environments
amplify env add

# Switch between environments
amplify env checkout production
```

### **Branch Deployments:**
```bash
# Deploy specific branch
amplify publish --branch feature/new-prediction

# Deploy with custom settings
amplify publish --env production --branch main
```

---

## 📊 **Monitoring & Analytics**

### **Built-in Monitoring:**
- **Amplify Console**: Real-time build status
- **CloudWatch**: Lambda metrics and logs
- **API Gateway**: Request/response tracking
- **CloudFront**: CDN performance metrics

### **Custom Analytics:**
```bash
# Add Google Analytics
amplify add analytics

# Check deployment status
amplify status

# View logs
amplify logs
```

---

## 🔒 **Security & Best Practices**

### **Security Features:**
- **HTTPS Only**: Automatic SSL certificates
- **CORS Configured**: Cross-origin requests allowed
- **Environment Variables**: Secure credential management
- **IAM Roles**: Least-privilege access
- **API Throttling**: Rate limiting protection

### **Best Practices:**
- **Git Flow**: Feature branches → Pull requests → Main
- **Commit Messages**: Clear, descriptive commits
- **Environment Separation**: Dev/Staging/Production
- **Backup Strategy**: Amplify automatic rollbacks
- **Monitoring**: Real-time error tracking

---

## 🎯 **Production Checklist**

### **Before Going Live:**
- [ ] GitHub repository created and pushed
- [ ] Amplify console access configured
- [ ] Build settings verified
- [ ] Environment variables set
- [ ] SSL certificates working
- [ ] Custom domain configured (optional)
- [ ] Monitoring enabled

### **After Deployment:**
- [ ] Frontend loads correctly
- [ ] API endpoints responding
- [ ] Heart disease predictions working
- [ ] AI treatment recommendations displaying
- [ ] Error handling tested
- [ ] Performance metrics monitored
- [ ] Mobile responsiveness verified

---

## 🚀 **Quick Start Commands**

### **One-Time Setup:**
```bash
# Clone your repository (for new developers)
git clone https://github.com/YOUR_USERNAME/heart-disease-prediction.git

# Install dependencies
npm install
pip install -r requirements.txt

# Start local development
python app.py
```

### **Deployment Commands:**
```bash
# Deploy latest changes
git add .
git commit -m "Update features"
git push origin main

# Force deployment
amplify publish --force
```

### **Troubleshooting:**
```bash
# Check Amplify status
amplify status

# View build logs
amplify logs

# Pull latest changes
git pull origin main

# Reset Amplify project
amplify delete
```

---

## 🎉 **Success!**

### **Your MediCare Cardiac Center is Ready for:**
- 🌍 **Global Deployment** - Reach patients worldwide
- 🤖 **AI-Powered Healthcare** - Advanced medical predictions
- 🏥 **Professional Interface** - Premium medical design
- 🔒 **Enterprise Security** - HIPAA-ready infrastructure
- 💰 **Cost-Effective** - Optimized cloud spending
- 🔄 **Continuous Delivery** - Automated updates and improvements

**🚀 Just push to GitHub and connect to Amplify - your heart disease prediction system will be live worldwide!**
