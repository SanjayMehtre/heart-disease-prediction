# 🔧 GitHub Authentication Fix

## ❌ **Issue Detected**
```
remote: Permission to SanjayMehtre/heart-disease-prediction.git denied to saurabhNag12.
fatal: unable to access 'https://github.com/SanjayMehtre/heart-disease-prediction.git/': The requested URL returned error: 403
```

## 🔧 **Solutions**

### **Option 1: Check GitHub Credentials**
The error shows `saurabhNag12` trying to push to `SanjayMehtre/heart-disease-prediction.git`. This suggests:
- Username mismatch between Git config and GitHub
- Authentication token expired
- Wrong repository URL

### **Solution 1A: Update Git Config**
```bash
# Check current Git config
git config --list

# Update username (replace with correct GitHub username)
git config user.name "Your Correct Name"
git config user.email "your-email@example.com"

# Remove incorrect remote
git remote remove origin

# Add correct remote (replace YOUR_USERNAME)
git remote add origin https://YOUR_USERNAME/heart-disease-prediction.git

# Try push again
git push -u origin main
```

### **Solution 1B: Use Personal Access Token**
```bash
# Create Personal Access Token on GitHub:
# 1. Go to GitHub → Settings → Developer settings → Personal access tokens
# 2. Generate new token with 'repo' permissions
# 3. Copy the token

# Use token instead of password
git remote set-url origin https://YOUR_USERNAME:YOUR_TOKEN@github.com/YOUR_USERNAME/heart-disease-prediction.git

# Push
git push -u origin main
```

### **Option 2: Create New Repository**
If the repository doesn't exist or you don't have access:

1. **Create New Repository**:
   - Go to [GitHub.com](https://github.com/new)
   - Repository name: `heart-disease-prediction`
   - Make it **Public**
   - Click **"Create repository"**

2. **Update Remote URL**:
```bash
# Remove old remote
git remote remove origin

# Add new remote (replace YOUR_USERNAME)
git remote add origin https://YOUR_USERNAME/heart-disease-prediction.git

# Push to new repository
git push -u origin main
```

### **Option 3: Use GitHub CLI (Recommended)**
```bash
# Install GitHub CLI
winget install GitHub.cli

# Authenticate
gh auth login

# Create repository
gh repo create heart-disease-prediction --public --description "MediCare Cardiac Center - Heart Disease Prediction System with AI Treatment Recommendations"

# Push
git push -u origin main
```

## 🔍 **Debugging Steps**

### **Check Current Configuration**
```bash
# Check Git user
git config user.name
git config user.email

# Check remotes
git remote -v

# Check if repository exists
curl -I https://github.com/SanjayMehtre/heart-disease-prediction.git
```

### **Common Issues & Fixes**

#### **Issue 1: Wrong Username**
```bash
# Fix: Update Git config with correct username
git config user.name "Your Correct Username"
```

#### **Issue 2: Repository Doesn't Exist**
```bash
# Fix: Create the repository first on GitHub
# Then update remote URL
```

#### **Issue 3: Permission Denied**
```bash
# Fix: Use Personal Access Token
git remote set-url origin https://USERNAME:TOKEN@github.com/USERNAME/heart-disease-prediction.git
```

## 🚀 **Quick Fix Commands**

### **Try This First:**
```bash
# 1. Check your actual GitHub username
git config user.name

# 2. Remove current remote
git remote remove origin

# 3. Add correct remote (replace with YOUR actual username)
git remote add origin https://YOUR_USERNAME/heart-disease-prediction.git

# 4. Push
git push -u origin main
```

### **If That Fails, Create New Repo:**
```bash
# 1. Create repository on GitHub.com
# 2. Use new repository URL
git remote add origin https://YOUR_USERNAME/heart-disease-prediction.git
git push -u origin main
```

## 🎯 **After Fix**

Once GitHub push works, proceed to Amplify:

1. Go to [AWS Amplify Console](https://console.aws.amazon.com/amplify/)
2. Click **"Get started"**
3. Choose **"GitHub"** as provider
4. Select your repository
5. Click **"Save and deploy"**

## 📞 **Need Help?**

- **GitHub Support**: https://support.github.com/
- **Git Documentation**: https://git-scm.com/docs
- **Amplify Support**: https://docs.amplify.aws/

**🔧 Fix the authentication issue and your project will upload successfully!**
