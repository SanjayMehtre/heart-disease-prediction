# PowerShell script to test the application
Write-Host "==========================================" -ForegroundColor Green
Write-Host "    Testing MediCare Cardiac Center" -ForegroundColor Green
Write-Host "==========================================" -ForegroundColor Green
Write-Host ""

# Navigate to project directory
Set-Location "C:\Users\sanja\OneDrive\Documents\Desktop\cc\aws-sagemaker-heart-disease-prediction-master"

Write-Host "Starting Flask application..." -ForegroundColor Yellow
python app.py
