@echo off
title Install AWS CLI
color 0A

echo.
echo ==========================================
echo    Installing AWS CLI for Windows
echo ==========================================
echo.

echo Downloading AWS CLI...
powershell -Command "Invoke-WebRequest -Uri https://awscli.amazonaws.com/awscli-exe-windows-x86_64.zip -OutFile awscliv2.zip"

echo.
echo Extracting files...
powershell -Command "Expand-Archive awscliv2.zip"

echo.
echo Installing AWS CLI...
powershell -Command ".\aws\install.exe"

echo.
echo Cleaning up temporary files...
del awscliv2.zip
rmdir /s /q aws

echo.
echo ==========================================
echo    AWS CLI Installation Complete
echo ==========================================
echo.
echo Please restart PowerShell and run: aws --version
echo.
pause
