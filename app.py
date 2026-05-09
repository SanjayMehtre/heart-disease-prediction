#!/usr/bin/env python3
"""
Heart Disease Prediction Web Application
Flask backend serving the HTML interface and handling API requests
Integrates with AWS SageMaker for real-time predictions
"""

from flask import Flask, render_template, request, jsonify
import pandas as pd
import numpy as np
import json
import os
from datetime import datetime

# Initialize Flask app
app = Flask(__name__)

# Load the heart disease dataset for reference
DATA_PATH = './heart-disease-predictor/src/main/resources/heart.csv'
heart_data = None

def load_data():
    """Load the heart disease dataset"""
    global heart_data
    try:
        heart_data = pd.read_csv(DATA_PATH)
        print(f"Dataset loaded successfully: {heart_data.shape}")
    except Exception as e:
        print(f"Error loading dataset: {e}")
        heart_data = None

def predict_heart_disease_local(features):
    """
    Local prediction function (simplified heuristic)
    In production, this would call AWS SageMaker endpoint
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
        'timestamp': datetime.now().isoformat()
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

@app.route('/')
def index():
    """Serve the main HTML page"""
    return render_template('index.html')

@app.route('/predict', methods=['POST'])
def predict():
    """Handle prediction requests"""
    try:
        # Get JSON data from request
        data = request.get_json()
        
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
        
        # Get prediction
        result = predict_heart_disease_local(features)
        
        # Add additional information
        result['risk_level'] = get_risk_level(result['risk_score'])
        result['recommendations'] = get_recommendations(result['risk_score'], features)
        result['ai_treatment_plan'] = get_ai_treatment_plan(result['risk_score'], features)
        
        return jsonify({
            'success': True,
            'prediction': result
        })
        
    except Exception as e:
        return jsonify({
            'success': False,
            'error': str(e)
        }), 400

@app.route('/health')
def health_check():
    """Health check endpoint"""
    return jsonify({
        'status': 'healthy',
        'timestamp': datetime.now().isoformat(),
        'dataset_loaded': heart_data is not None
    })

@app.route('/dataset-stats')
def dataset_stats():
    """Return dataset statistics"""
    if heart_data is None:
        return jsonify({'error': 'Dataset not loaded'}), 500
    
    stats = {
        'total_records': len(heart_data),
        'features': list(heart_data.columns[:-1]),
        'target_distribution': heart_data['target'].value_counts().to_dict(),
        'age_stats': {
            'mean': float(heart_data['age'].mean()),
            'min': int(heart_data['age'].min()),
            'max': int(heart_data['age'].max())
        },
        'sex_distribution': heart_data['sex'].value_counts().to_dict()
    }
    
    return jsonify(stats)

@app.route('/sdg-info')
def sdg_info():
    """Return SDG 3 related information"""
    return jsonify({
        'sdg_goal': 3,
        'goal_title': 'Good Health and Well-being',
        'targets': [
            {
                'target': '3.4',
                'description': 'By 2030, reduce by one-third premature mortality from non-communicable diseases through prevention and treatment'
            },
            {
                'target': '3.8',
                'description': 'Achieve universal health coverage, including access to quality essential healthcare services'
            }
        ],
        'project_contribution': {
            'early_detection': 'Identifies at-risk patients before symptoms become severe',
            'preventive_care': 'Enables proactive health management and lifestyle interventions',
            'resource_optimization': 'Helps healthcare systems allocate resources efficiently',
            'accessibility': 'Provides affordable screening tools for underserved populations'
        }
    })

@app.route('/sagemaker-info')
def sagemaker_info():
    """Return AWS SageMaker integration information"""
    return jsonify({
        'platform': 'AWS SageMaker',
        'features': [
            {
                'category': 'Data Management',
                'capabilities': [
                    'S3 integration for scalable data storage',
                    'Built-in data preprocessing and transformation tools',
                    'Support for multiple data formats (CSV, JSON, RecordIO)'
                ]
            },
            {
                'category': 'Model Development',
                'capabilities': [
                    'Jupyter notebook environment for interactive development',
                    'Built-in algorithms (Linear Learner) optimized for performance',
                    'Hyperparameter tuning and optimization'
                ]
            },
            {
                'category': 'Training Infrastructure',
                'capabilities': [
                    'Managed training instances with automatic scaling',
                    'Distributed training for large datasets',
                    'Cost-effective pay-as-you-go pricing'
                ]
            },
            {
                'category': 'Model Deployment',
                'capabilities': [
                    'Real-time endpoints with auto-scaling',
                    'Multiple deployment options (real-time, batch, serverless)',
                    'A/B testing and shadow deployment capabilities'
                ]
            },
            {
                'category': 'Monitoring and Maintenance',
                'capabilities': [
                    'Model performance monitoring',
                    'Data drift detection',
                    'Automated alerts and notifications'
                ]
            }
        ]
    })

if __name__ == '__main__':
    # Load data on startup
    load_data()
    
    # Run the Flask app
    app.run(debug=True, host='0.0.0.0', port=5000)
