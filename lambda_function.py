import json
import os
import boto3
import numpy as np
import pandas as pd

def lambda_handler(event, context):
    """AWS Lambda function for heart disease prediction"""
    
    try:
        # Parse request body
        body = json.loads(event.get('body', '{}'))
        
        # Validate required fields
        required_fields = ['name', 'age', 'sex', 'trestbps', 'chol', 'fbs', 'thalach']
        for field in required_fields:
            if field not in body:
                return {
                    'statusCode': 400,
                    'headers': {
                        'Content-Type': 'application/json',
                        'Access-Control-Allow-Origin': '*',
                        'Access-Control-Allow-Headers': 'Content-Type',
                        'Access-Control-Allow-Methods': 'POST, OPTIONS'
                    },
                    'body': json.dumps({
                        'success': False,
                        'error': f'Missing required field: {field}'
                    })
                }
        
        # Validate data types
        try:
            patient_data = {
                'name': str(body['name']),
                'age': int(float(body['age'])),
                'sex': int(float(body['sex'])),
                'trestbps': int(float(body['trestbps'])),
                'chol': int(float(body['chol'])),
                'fbs': int(float(body['fbs'])),
                'thalach': int(float(body['thalach']))
            }
        except ValueError as e:
            return {
                    'statusCode': 400,
                    'headers': {
                        'Content-Type': 'application/json',
                        'Access-Control-Allow-Origin': '*',
                        'Access-Control-Allow-Headers': 'Content-Type',
                        'Access-Control-Allow-Methods': 'POST, OPTIONS'
                    },
                    'body': json.dumps({
                        'success': False,
                        'error': f'Invalid data format: {str(e)}'
                    })
                }
        
        # Get prediction
        result = predict_heart_disease(patient_data)
        
        if 'error' in result:
            return {
                'statusCode': 500,
                'headers': {
                    'Content-Type': 'application/json',
                    'Access-Control-Allow-Origin': '*',
                    'Access-Control-Allow-Headers': 'Content-Type',
                    'Access-Control-Allow-Methods': 'POST, OPTIONS'
                },
                'body': json.dumps({
                    'success': False,
                    'error': result['error']
                })
            }
        
        # Get AI treatment plan
        treatment_plan = get_ai_treatment_plan(result['risk_score'], patient_data)
        
        # Determine risk level and styling
        if result['risk_score'] >= 0.7:
            risk_level = {
                'level': 'High Risk',
                'color': 'red',
                'icon': 'fa-exclamation-circle',
                'bg_color': 'bg-red-50',
                'text_color': 'text-red-800',
                'border_color': 'border-red-200'
            }
        elif result['risk_score'] >= 0.4:
            risk_level = {
                'level': 'Moderate Risk',
                'color': 'yellow',
                'icon': 'fa-exclamation-triangle',
                'bg_color': 'bg-yellow-50',
                'text_color': 'text-yellow-800',
                'border_color': 'border-yellow-200'
            }
        else:
            risk_level = {
                'level': 'Low Risk',
                'color': 'green',
                'icon': 'fa-check-circle',
                'bg_color': 'bg-green-50',
                'text_color': 'text-green-800',
                'border_color': 'border-green-200'
            }
        
        return {
            'statusCode': 200,
            'headers': {
                'Content-Type': 'application/json',
                'Access-Control-Allow-Origin': '*',
                'Access-Control-Allow-Headers': 'Content-Type',
                'Access-Control-Allow-Methods': 'POST, OPTIONS'
            },
            'body': json.dumps({
                'success': True,
                'prediction': result['prediction'],
                'risk_score': result['risk_score'],
                'confidence': result['confidence'],
                'risk_level': risk_level,
                'patient_name': patient_data['name'],
                'ai_treatment_plan': treatment_plan,
                'timestamp': pd.Timestamp.now().strftime('%Y-%m-%d %H:%M:%S')
            })
        }
        
    except Exception as e:
        return {
            'statusCode': 500,
            'headers': {
                'Content-Type': 'application/json',
                'Access-Control-Allow-Origin': '*',
                'Access-Control-Allow-Headers': 'Content-Type',
                'Access-Control-Allow-Methods': 'POST, OPTIONS'
            },
            'body': json.dumps({
                'success': False,
                'error': f'Prediction failed: {str(e)}'
            })
        }

def predict_heart_disease(patient_data):
    """Predict heart disease using simple rule-based logic"""
    
    try:
        # Create input array in the correct order
        input_data = np.array([[
            patient_data['age'],
            patient_data['sex'],
            patient_data['trestbps'],
            patient_data['chol'],
            patient_data['fbs'],
            patient_data['thalach']
        ]])
        
        # Simple rule-based prediction (for demonstration)
        # In production, this would use a trained ML model
        
        # Risk factors
        risk_score = 0.0
        
        # Age risk
        if patient_data['age'] > 65:
            risk_score += 0.2
        elif patient_data['age'] > 55:
            risk_score += 0.1
        
        # Gender risk (male = 1)
        if patient_data['sex'] == 1:
            risk_score += 0.1
        
        # Blood pressure risk
        if patient_data['trestbps'] > 140:
            risk_score += 0.15
        elif patient_data['trestbps'] > 130:
            risk_score += 0.1
        
        # Cholesterol risk
        if patient_data['chol'] > 240:
            risk_score += 0.2
        elif patient_data['chol'] > 200:
            risk_score += 0.1
        
        # Blood sugar risk
        if patient_data['fbs'] == 1:
            risk_score += 0.15
        
        # Heart rate risk
        if patient_data['thalach'] < 100 or patient_data['thalach'] > 160:
            risk_score += 0.1
        
        # Normalize risk score to 0-1 range
        risk_score = min(risk_score, 0.95)
        
        # Make prediction
        prediction = 1 if risk_score > 0.5 else 0
        
        # Calculate confidence
        confidence = 0.5 + abs(risk_score - 0.5) * 0.4
        
        return {
            'prediction': int(prediction),
            'risk_score': round(risk_score, 3),
            'confidence': round(confidence, 3)
        }
        
    except Exception as e:
        return {
            'prediction': 0,
            'risk_score': 0.0,
            'confidence': 0.0,
            'error': str(e)
        }

def get_ai_treatment_plan(risk_score, patient_data):
    """Generate AI-powered treatment recommendations based on risk score and patient data"""
    
    age = patient_data.get('age', 50)
    sex = patient_data.get('sex', 1)
    bp = patient_data.get('trestbps', 120)
    cholesterol = patient_data.get('chol', 200)
    
    recommendations = []
    
    if risk_score >= 0.7:
        recommendations.extend([
            "🏥 Immediate Medical Consultation Required",
            "📞 Schedule appointment with cardiologist within 48 hours",
            "🚑 Consider emergency room if experiencing chest pain, shortness of breath, or dizziness",
            "💊 Begin statin therapy immediately",
            "🩺 Start low-dose aspirin therapy (unless contraindicated)",
            "🍎 Adopt heart-healthy diet: low sodium, low saturated fats, high fiber",
            "🚫 Quit smoking immediately - smoking cessation programs available",
            "🏃 Begin gentle cardiac rehabilitation program",
            "📊 Monitor blood pressure twice daily",
            "💤 Maintain healthy weight: BMI target 18.5-24.9",
            "🩸 Consider coronary angiography for detailed assessment"
        ])
    elif risk_score >= 0.4:
        recommendations.extend([
            "🩺 Schedule cardiology consultation within 2 weeks",
            "📋 Begin moderate exercise program: 30 minutes, 5 days/week",
            "🍎 Mediterranean diet recommended: fruits, vegetables, whole grains, olive oil",
            "💊 Consider cholesterol-lowering medication (statins)",
            "📊 Weekly blood pressure monitoring",
            "🚭 Reduce alcohol consumption to moderate levels",
            "🏃 Stress management techniques: meditation, yoga, deep breathing",
            "💤 Weight management: 5-10% weight reduction if overweight",
            "🩸 Consider stress test for baseline assessment"
        ])
    else:
        recommendations.extend([
            "🩺 Annual cardiology check-up recommended",
            "🏃 Regular aerobic exercise: 150 minutes/week moderate intensity",
            "🍎 Plant-based diet with limited processed foods",
            "📊 Quarterly blood pressure and cholesterol checks",
            "🚫 Maintain healthy weight through balanced diet and exercise",
            "🧘 Limit sodium intake to <2,300mg/day",
            "🍷 Increase omega-3 fatty acids: fish, nuts, seeds",
            "💤 Adequate sleep: 7-9 hours per night",
            "🩸 Consider cardiac calcium scan for baseline"
        ])
    
    age_specific = []
    if age >= 65:
        age_specific.extend([
            "👴 Senior cardiac care program recommended",
            "💊 Medication review for potential interactions",
            "🏃 Low-impact exercises: swimming, stationary cycling",
            "📋 Fall prevention strategies and home safety assessment"
        ])
    elif age >= 45:
        age_specific.extend([
            "📊 Comprehensive metabolic panel recommended",
            "🩸 Consider coronary calcium scoring",
            "💊 Discuss preventive aspirin therapy"
        ])
    
    return {
        "risk_level": "High" if risk_score >= 0.7 else "Medium" if risk_score >= 0.4 else "Low",
        "recommendations": recommendations + age_specific,
        "lifestyle_changes": [
            "🚫 Quit smoking completely",
            "🍎 Adopt heart-healthy Mediterranean diet",
            "🏃 Regular aerobic exercise (150 min/week)",
            "📊 Daily blood pressure monitoring",
            "💤 Maintain healthy BMI (18.5-24.9)",
            "🧘 7-9 hours of quality sleep",
            "🧘 Stress management through meditation/yoga"
        ],
        "follow_up": "Schedule follow-up in 3 months",
        "emergency_contacts": [
            "🚑 Emergency: 911 immediately",
            "🏥 Cardiologist: [Your doctor's number]",
            "📞 Primary Care: [Your doctor's number]"
        ]
    }
