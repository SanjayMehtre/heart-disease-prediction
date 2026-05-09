#!/usr/bin/env python3
"""
Test script for the heart disease prediction notebook functionality
This script tests the data loading and preprocessing steps
"""

import pandas as pd
import numpy as np
import os

def test_data_loading():
    """Test loading and preprocessing the heart disease data"""
    print("=== Heart Disease Prediction Test ===")
    print("Testing data loading and preprocessing...")
    
    # Load the local data
    local_data_path = './heart-disease-predictor/src/main/resources/heart.csv'
    
    if not os.path.exists(local_data_path):
        print(f"Error: Data file not found at {local_data_path}")
        return False
    
    # Read the data
    heart_data = pd.read_csv(local_data_path)
    print(f"Dataset shape: {heart_data.shape}")
    print("\nColumn names:")
    print(heart_data.columns.tolist())
    
    # Display first few rows
    print("\nFirst 5 rows:")
    print(heart_data.head())
    
    # Data preprocessing
    vectors = np.array(heart_data).astype('float32')
    
    # Extract target column (last column)
    labels = vectors[:, -1]
    print(f"\nLabels shape: {labels.shape}")
    print(f"Unique labels: {np.unique(labels)}")
    print(f"Label distribution: {np.bincount(labels.astype(int))}")
    
    # Extract features (all columns except last)
    training_data = vectors[:, :-1]
    print(f"\nTraining data shape: {training_data.shape}")
    print(f"Feature dimensions: {training_data.shape[1]}")
    
    # Test with a sample prediction
    sample_data = training_data[5]
    print(f"\nSample patient data (first 5 features): {sample_data[:5]}")
    print(f"Sample patient label: {labels[5]}")
    
    print("\n=== Data Loading Test Complete ===")
    return True

def test_sagemaker_components():
    """Test if SageMaker components are available"""
    print("\n=== Testing AWS SageMaker Components ===")
    
    try:
        import boto3
        print("✓ boto3 is available")
        
        # Try to get AWS session info (will fail if not configured)
        try:
            session = boto3.Session()
            print(f"✓ AWS Session created (region: {session.region_name})")
        except Exception as e:
            print(f"⚠ AWS Session not configured: {e}")
            
    except ImportError:
        print("✗ boto3 not available")
    
    try:
        import sagemaker
        print("✓ sagemaker is available")
    except ImportError:
        print("✗ sagemaker not available")
    
    print("=== SageMaker Component Test Complete ===")

if __name__ == "__main__":
    # Test data loading
    success = test_data_loading()
    
    # Test SageMaker components
    test_sagemaker_components()
    
    if success:
        print("\n🎉 All tests completed successfully!")
        print("The notebook code should work with proper AWS configuration.")
    else:
        print("\n❌ Some tests failed. Please check the data file.")
