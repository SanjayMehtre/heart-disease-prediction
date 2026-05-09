#!/usr/bin/env python3
"""
Test script to verify the Flask API is working correctly
"""

import requests
import json

def test_api():
    """Test the Flask API endpoints"""
    base_url = "http://127.0.0.1:5000"
    
    print("=== Testing Flask API ===")
    
    # Test health endpoint
    try:
        response = requests.get(f"{base_url}/health")
        print(f"Health check: {response.status_code}")
        if response.status_code == 200:
            print(f"Health response: {response.json()}")
    except Exception as e:
        print(f"Health check failed: {e}")
    
    # Test prediction with sample data
    sample_data = {
        "age": 57,
        "sex": 1,
        "trestbps": 140,
        "chol": 192,
        "fbs": 0,
        "restecg": 1,
        "thalach": 148,
        "exang": 0,
        "oldpeak": 0.4,
        "slope": 1,
        "ca": 0
    }
    
    try:
        response = requests.post(f"{base_url}/predict", 
                               json=sample_data,
                               headers={'Content-Type': 'application/json'})
        print(f"Prediction test: {response.status_code}")
        if response.status_code == 200:
            result = response.json()
            print(f"Prediction successful: {result['success']}")
            if result['success']:
                prediction = result['prediction']
                print(f"Risk Score: {prediction['risk_score']:.3f}")
                print(f"Risk Level: {prediction['risk_level']}")
                print(f"Prediction: {prediction['prediction']}")
                print(f"AI Treatment Plan sections: {len(prediction['ai_treatment_plan'])}")
            else:
                print(f"Prediction failed: {result.get('error', 'Unknown error')}")
        else:
            print(f"Prediction failed with status {response.status_code}")
            print(f"Response: {response.text}")
    except Exception as e:
        print(f"Prediction test failed: {e}")
    
    print("=== API Test Complete ===")

if __name__ == "__main__":
    test_api()
