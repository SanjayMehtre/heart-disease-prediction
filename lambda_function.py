import json
import numpy as np
import boto3
from datetime import datetime
import os

# SageMaker configuration
USE_SAGEMAKER = os.environ.get('USE_SAGEMAKER', 'false').lower() == 'true'
SAGEMAKER_ENDPOINT = os.environ.get('SAGEMAKER_ENDPOINT', 'heart-disease-endpoint')

def predict_heart_disease_sagemaker(features):
    """
    Call AWS SageMaker endpoint for prediction
    """
    try:
        runtime = boto3.client('sagemaker-runtime')
        
        # Prepare payload for SageMaker
        payload = {
            "instances": [{"features": features}]
        }
        
        # Call SageMaker endpoint
        response = runtime.invoke_endpoint(
            EndpointName=SAGEMAKER_ENDPOINT,
            ContentType='application/json',
            Body=json.dumps(payload)
        )
        
        # Parse response
        result = json.loads(response['Body'].read().decode())
        prediction = result['predictions'][0]
        
        return {
            'risk_score': float(prediction.get('predicted_probability', 0.5)),
            'prediction': int(prediction.get('predicted_label', 0)),
            'confidence': float(prediction.get('score', 0.5)),
            'timestamp': datetime.now().isoformat(),
            'source': 'sagemaker'
        }
        
    except Exception as e:
        print(f"SageMaker prediction failed: {e}")
        # Fallback to local prediction
        return predict_heart_disease_local(features)

def predict_heart_disease_local(features):
    """
    Local prediction function (simplified heuristic)
    Used as fallback when SageMaker is not available
    """
    # Extract features (removed thal, cp, restecg, oldpeak, slope, exang, ca)
    age, sex, trestbps, chol, fbs, thalach = features
    
    # Simple risk calculation (for demonstration)
    risk_score = 0
    
    # Age factor
    if age > 55: risk_score += 0.2
    if age > 65: risk_score += 0.1
    
    # Sex factor (male higher risk)
    if sex == 1: risk_score += 0.1
    
    # Blood pressure
    if trestbps > 140: risk_score += 0.2
    if trestbps > 160: risk_score += 0.1
    
    # Cholesterol
    if chol > 240: risk_score += 0.2
    if chol > 300: risk_score += 0.1
    
    # Fasting blood sugar
    if fbs == 1: risk_score += 0.1
    
    # Max heart rate (lower is riskier)
    if thalach < 120: risk_score += 0.3
    elif thalach < 140: risk_score += 0.2
    
    # Add some randomness for realism
    risk_score += (np.random.random() - 0.5) * 0.1
    
    # Cap between 0 and 0.95 to prevent 100% risk
    risk_score = max(0, min(0.95, risk_score))
    
    return {
        'risk_score': float(risk_score),
        'prediction': 1 if risk_score > 0.5 else 0,
        'confidence': float(abs(risk_score - 0.5) * 2),
        'timestamp': datetime.now().isoformat(),
        'source': 'local'
    }

def get_risk_level(score):
    """Get risk level based on score"""
    if score < 0.3:
        return {'level': 'Low', 'color': 'green', 'icon': 'fa-check-circle'}
    elif score < 0.6:
        return {'level': 'Moderate', 'color': 'yellow', 'icon': 'fa-exclamation-triangle'}
    else:
        return {'level': 'High', 'color': 'red', 'icon': 'fa-exclamation-circle'}

def get_recommendations(score, features):
    """Get medical recommendations based on risk and features"""
    recommendations = []
    age, sex, trestbps, chol, fbs, thalach = features
    
    if score > 0.5:
        recommendations.append('Consult with a cardiologist for further evaluation')
        recommendations.append('Consider comprehensive cardiac screening tests')
    
    if trestbps > 140:
        recommendations.append('Monitor blood pressure regularly')
        recommendations.append('Consider lifestyle modifications to reduce blood pressure')
    
    if chol > 240:
        recommendations.append('Follow up with cholesterol management plan')
        recommendations.append('Consider dietary changes to reduce cholesterol')
        
    if fbs == 1:
        recommendations.append('Monitor blood sugar levels regularly')
        recommendations.append('Consider diabetes management program')
    
    if len(recommendations) == 0:
        recommendations.append('Continue regular health check-ups')
        recommendations.append('Maintain healthy lifestyle habits')
    
    return recommendations

def get_ai_treatment_plan(score, features):
    """Generate AI-powered treatment recommendations based on risk assessment"""
    age, sex, trestbps, chol, fbs, thalach = features
    
    treatment_plan = {
        'immediate_actions': [],
        'lifestyle_modifications': [],
        'medication_recommendations': [],
        'monitoring_plan': [],
        'follow_up_care': [],
        'emergency_indicators': []
    }
    
    # Immediate Actions
    if score > 0.7:
        treatment_plan['immediate_actions'].extend([
            'Seek immediate medical attention from emergency department',
            'Call emergency services if experiencing chest pain, shortness of breath, or dizziness',
            'Avoid any physical exertion until evaluated by healthcare provider'
        ])
    elif score > 0.5:
        treatment_plan['immediate_actions'].extend([
            'Schedule urgent appointment with cardiologist within 48 hours',
            'Avoid strenuous activities until medical evaluation',
            'Monitor vital signs (blood pressure, heart rate) twice daily'
        ])
    else:
        treatment_plan['immediate_actions'].extend([
            'Schedule routine check-up with primary care physician within 2 weeks',
            'Continue normal activities with awareness of symptoms'
        ])

    # Lifestyle Modifications
    if trestbps > 140:
        treatment_plan['lifestyle_modifications'].extend([
            'Adopt DASH (Dietary Approaches to Stop Hypertension) eating plan',
            'Reduce sodium intake to less than 1,500 mg per day',
            'Engage in moderate aerobic exercise (30 minutes, 5 days/week)',
            'Practice stress reduction techniques (meditation, deep breathing)',
            'Limit alcohol consumption to 1 drink/day for women, 2 for men'
        ])

    if chol > 240:
        treatment_plan['lifestyle_modifications'].extend([
            'Follow heart-healthy diet low in saturated and trans fats',
            'Increase soluble fiber intake (oats, beans, apples, citrus)',
            'Incorporate omega-3 fatty acids (fatty fish, walnuts, flaxseed)',
            'Achieve and maintain healthy body weight (BMI 18.5-24.9)',
            'Quit smoking if applicable'
        ])

    if age > 65:
        treatment_plan['lifestyle_modifications'].extend([
            'Consider low-impact exercises (swimming, walking, tai chi)',
            'Ensure adequate calcium and vitamin D intake',
            'Participate in regular balance and strength training'
        ])

    # Medication Recommendations
    if score > 0.6:
        treatment_plan['medication_recommendations'].extend([
            'Physician may consider statin therapy for cholesterol management',
            'Blood pressure medications may be prescribed (ACE inhibitors, beta-blockers)',
            'Aspirin therapy may be considered for cardiovascular prevention',
            'Note: All medications require prescription and medical supervision'
        ])
    elif trestbps > 140:
        treatment_plan['medication_recommendations'].extend([
            'Antihypertensive medications may be prescribed',
            'Regular medication adherence monitoring required'
        ])

    if fbs == 1:
        treatment_plan['medication_recommendations'].extend([
            'Diabetes medications may be prescribed if diabetic',
            'Regular blood glucose monitoring essential'
        ])

    # Monitoring Plan
    treatment_plan['monitoring_plan'].extend([
        'Daily blood pressure monitoring (morning and evening)',
        'Weekly weight tracking to detect fluid retention',
        'Monthly cholesterol level checks if elevated',
        'Keep symptom diary noting chest pain, shortness of breath, fatigue'
    ])

    if score > 0.5:
        treatment_plan['monitoring_plan'].extend([
            'Consider home ECG monitoring if recommended by physician',
            'Regular heart rate variability monitoring',
            'Blood sugar monitoring if diabetic or pre-diabetic'
        ])

    # Follow-up Care
    if score > 0.7:
        treatment_plan['follow_up_care'].extend([
            'Cardiology follow-up within 1 week',
            'Possible cardiac stress test or echocardiogram',
            'Consider cardiac catheterization if indicated',
            'Referral to cardiac rehabilitation program'
        ])
    elif score > 0.5:
        treatment_plan['follow_up_care'].extend([
            'Cardiology follow-up within 4-6 weeks',
            'Baseline cardiac workup (ECG, blood tests)',
            'Consider stress testing based on symptoms'
        ])
    else:
        treatment_plan['follow_up_care'].extend([
            'Primary care follow-up within 3 months',
            'Annual cardiac screening',
            'Preventive health maintenance'
        ])

    # Emergency Indicators
    treatment_plan['emergency_indicators'].extend([
        'Chest pain or pressure lasting more than 5 minutes',
        'Shortness of breath at rest or with minimal activity',
        'Pain radiating to arm, jaw, neck, or back',
        'Cold sweat, nausea, or lightheadedness',
        'Irregular or rapid heartbeat',
        'Sudden severe headache or vision changes'
    ])

    return treatment_plan

def lambda_handler(event, context):
    """Main Lambda handler function"""
    try:
        # Log the incoming request
        print(f"Received event: {event}")
        
        # Get JSON data from request
        if 'body' in event:
            data = json.loads(event['body'])
        else:
            data = event
        
        # Extract features in the correct order (removed thal, cp, restecg, oldpeak, slope, exang, ca)
        features = [
            float(data.get('age', 0)),
            float(data.get('sex', 0)),
            float(data.get('trestbps', 0)),
            float(data.get('chol', 0)),
            float(data.get('fbs', 0)),
            float(data.get('thalach', 0))
        ]
        
        # Get patient name for display
        patient_name = data.get('name', 'Patient')
        
        # Get prediction (use SageMaker if available, otherwise local)
        if USE_SAGEMAKER:
            result = predict_heart_disease_sagemaker(features)
        else:
            result = predict_heart_disease_local(features)
        
        # Add additional information
        result['risk_level'] = get_risk_level(result['risk_score'])
        result['recommendations'] = get_recommendations(result['risk_score'], features)
        result['ai_treatment_plan'] = get_ai_treatment_plan(result['risk_score'], features)
        
        # Log the result
        print(f"Prediction result: {result}")
        
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
                'prediction': result
            })
        }
        
    except Exception as e:
        # Log the error
        print(f"Error processing request: {str(e)}")
        
        return {
            'statusCode': 500,
            'headers': {
                'Content-Type': 'application/json',
                'Access-Control-Allow-Origin': '*'
            },
            'body': json.dumps({
                'success': False,
                'error': str(e)
            })
        }

# Health check function for monitoring
def health_check():
    """Health check endpoint"""
    return {
        'status': 'healthy',
        'timestamp': datetime.now().isoformat(),
        'version': '1.0.0',
        'service': 'heart-disease-prediction'
    }
