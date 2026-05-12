@echo off
title Run MediCare Cardiac Center
color 0A

echo.
echo ==========================================
echo    Starting MediCare Cardiac Center
echo ==========================================
echo.

echo Navigating to project directory...
cd "C:\Users\sanja\OneDrive\Documents\Desktop\cc\aws-sagemaker-heart-disease-prediction-master"

echo.
echo Starting Flask application...
python app.py

echo.
echo If server started successfully, open your browser to:
echo http://127.0.0.1:5000
echo.
pause
