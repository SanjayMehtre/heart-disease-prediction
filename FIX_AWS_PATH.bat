@echo off
title Fix AWS CLI Path
color 0E

echo.
echo ==========================================
echo    Fix AWS CLI Path Issue
echo ==========================================
echo.

echo AWS CLI was installed but not found in PATH.
echo This script will fix the PATH and deploy.
echo.

echo Step 1: Adding AWS CLI to PATH...
set PATH=%PATH%;C:\Program Files\Amazon\AWSCLI\bin\

echo Step 2: Verifying AWS CLI...
aws --version >nul 2>&1
if %errorlevel% neq 0 (
    echo Trying alternative path...
    set PATH=%PATH%;C:\Program Files (x86)\Amazon\AWSCLI\bin\
    
    aws --version >nul 2>&1
    if %errorlevel% neq 0 (
        echo AWS CLI still not found. Please check installation.
        echo AWS CLI should be in: C:\Program Files\Amazon\AWSCLI\bin\
        pause
        exit /b 1
    )
)

echo ✅ AWS CLI found!

echo.
echo Step 3: Configure AWS (if not configured)...
aws configure

echo.
echo Step 4: Deploy to AWS...
call final_deploy.bat

echo.
echo ✅ Deployment complete!
pause
