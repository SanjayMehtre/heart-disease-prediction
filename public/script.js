// Heart Disease Prediction System JavaScript
// This script handles form validation, prediction logic, and UI interactions

// Sample data for testing
const sampleData = {
    name: 'John Doe',
    age: 57,
    sex: 1,
    trestbps: 140,
    chol: 192,
    fbs: 0,
    thalach: 148
};

// Initialize the application
document.addEventListener('DOMContentLoaded', function() {
    const form = document.getElementById('predictionForm');
    if (form) {
        form.addEventListener('submit', handleFormSubmit);
    }
    
    // Add input validation
    addInputValidation();
    
    // Smooth scroll for navigation
    addSmoothScroll();
});

// Handle form submission
async function handleFormSubmit(event) {
    event.preventDefault();
    
    // Validate form
    if (!validateForm()) {
        showNotification('Please fill in all required fields correctly.', 'error');
        return;
    }
    
    // Get form data
    const formData = getFormData();
    
    // Show loading state
    showLoadingState();
    
    try {
        // Call prediction API
        const prediction = await predictHeartDisease(formData);
        
        // Display results
        displayResults(prediction, formData);
        
    } catch (error) {
        console.error('Prediction error:', error);
        showNotification('An error occurred during prediction. Please try again.', 'error');
    } finally {
        hideLoadingState();
    }
}

// Validate form inputs
function validateForm() {
    const form = document.getElementById('predictionForm');
    const inputs = form.querySelectorAll('input[required], select[required]');
    
    for (let input of inputs) {
        if (!input.value || (input.type === 'number' && isNaN(input.value))) {
            input.classList.add('border-red-500');
            input.focus();
            return false;
        }
        input.classList.remove('border-red-500');
    }
    
    return true;
}

// Get form data as object
function getFormData() {
    const formData = {};
    const form = document.getElementById('predictionForm');
    
    // Get all form inputs
    const inputs = form.querySelectorAll('input, select');
    inputs.forEach(input => {
        if (input.name) {
            formData[input.name] = parseFloat(input.value) || input.value;
        }
    });
    
    return formData;
}

// Call backend API for heart disease prediction
async function predictHeartDisease(data) {
    try {
        const response = await fetch('/predict', {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json',
            },
            body: JSON.stringify(data)
        });
        
        if (!response.ok) {
            throw new Error(`HTTP error! status: ${response.status}`);
        }
        
        const result = await response.json();
        
        if (!result.success) {
            throw new Error(result.error || 'Prediction failed');
        }
        
        console.log('Prediction result:', result); // Debug log
        
        return {
            riskScore: result.risk_score,
            prediction: result.prediction,
            confidence: result.confidence,
            riskLevel: getRiskLevel(result.risk_score),
            recommendations: result.recommendations || [],
            aiTreatmentPlan: result.ai_treatment_plan || {},
            usingSageMaker: result.using_sagemaker || false,
            modelInfo: result.model_info || {}
        };
        
    } catch (error) {
        console.error('API call failed:', error);
        throw error;
    }
}

// Get risk level based on score
function getRiskLevel(score) {
    if (score < 0.3) return { level: 'Low', color: 'green', icon: 'fa-check-circle' };
    if (score < 0.6) return { level: 'Moderate', color: 'yellow', icon: 'fa-exclamation-triangle' };
    return { level: 'High', color: 'red', icon: 'fa-exclamation-circle' };
}

// Display prediction results
function displayResults(prediction, formData) {
    const resultsSection = document.getElementById('resultsSection');
    const resultsDiv = document.getElementById('predictionResults');
    
    const riskLevel = prediction.riskLevel;
    const riskPercentage = Math.round(prediction.riskScore * 100);
    
    resultsDiv.innerHTML = `
        <div class="mb-6">
            <div class="text-center mb-4">
                <h3 class="text-2xl font-bold text-blue-800 mb-2">
                    <i class="fas fa-user-injured mr-2"></i>Patient Assessment Report
                </h3>
                <p class="text-lg text-gray-600">Name: <strong>${formData.name}</strong></p>
                ${prediction.usingSageMaker ? '<p class="text-sm text-green-600"><i class="fas fa-cloud mr-1"></i>Powered by AWS SageMaker</p>' : '<p class="text-sm text-yellow-600"><i class="fas fa-laptop mr-1"></i>Using Local Model</p>'}
            </div>
            <div class="text-6xl mb-4 text-${riskLevel.color}-500">
                <i class="fas ${riskLevel.icon}"></i>
            </div>
            <h3 class="text-3xl font-bold mb-2 text-${riskLevel.color}-600">
                ${riskLevel.level} Risk Level
            </h3>
            <div class="text-5xl font-bold mb-4 text-gray-800">
                ${riskPercentage}%
            </div>
            <p class="text-lg text-gray-600 mb-4">
                Risk Score: ${prediction.riskScore.toFixed(3)} | 
                Confidence: ${Math.round(prediction.confidence * 100)}%
            </p>
        </div>
        
        <!-- AI Treatment Plan Section -->
        <div class="mb-6">
            <h3 class="text-2xl font-bold mb-4 text-purple-600">
                <i class="fas fa-robot mr-2"></i>AI-Powered Treatment Plan
            </h3>
            
            <div class="grid md:grid-cols-2 lg:grid-cols-3 gap-4 mb-6">
                <!-- Immediate Actions -->
                <div class="bg-red-50 rounded-lg p-4 border-l-4 border-red-500">
                    <h4 class="font-semibold mb-3 text-red-800">
                        <i class="fas fa-exclamation-triangle mr-2"></i>Immediate Actions
                    </h4>
                    <ul class="space-y-2 text-sm">
                        ${(prediction.aiTreatmentPlan.recommendations || []).slice(0, 5).map(action => 
                            `<li class="flex items-start">
                                <i class="fas fa-chevron-right text-red-500 mt-1 mr-2 text-xs"></i>
                                <span>${action}</span>
                            </li>`
                        ).join('')}
                    </ul>
                </div>
                
                <!-- Lifestyle Modifications -->
                <div class="bg-green-50 rounded-lg p-4 border-l-4 border-green-500">
                    <h4 class="font-semibold mb-3 text-green-800">
                        <i class="fas fa-heart mr-2"></i>Lifestyle Modifications
                    </h4>
                    <ul class="space-y-2 text-sm">
                        ${(prediction.aiTreatmentPlan.lifestyle_changes || []).map(mod => 
                            `<li class="flex items-start">
                                <i class="fas fa-chevron-right text-green-500 mt-1 mr-2 text-xs"></i>
                                <span>${mod}</span>
                            </li>`
                        ).join('')}
                    </ul>
                </div>
                
                <!-- Monitoring Plan -->
                <div class="bg-yellow-50 rounded-lg p-4 border-l-4 border-yellow-500">
                    <h4 class="font-semibold mb-3 text-yellow-800">
                        <i class="fas fa-chart-line mr-2"></i>Monitoring Plan
                    </h4>
                    <ul class="space-y-2 text-sm">
                        <li class="flex items-start">
                            <i class="fas fa-chevron-right text-yellow-500 mt-1 mr-2 text-xs"></i>
                            <span>${prediction.aiTreatmentPlan.follow_up || 'Follow up with healthcare provider in 3 months'}</span>
                        </li>
                    </ul>
                </div>
                
                <!-- Emergency Contacts -->
                <div class="bg-red-100 rounded-lg p-4 border-l-4 border-red-600">
                    <h4 class="font-semibold mb-3 text-red-900">
                        <i class="fas fa-ambulance mr-2"></i>Emergency Contacts
                    </h4>
                    <ul class="space-y-2 text-sm">
                        ${(prediction.aiTreatmentPlan.emergency_contacts || []).map(emergency => 
                            `<li class="flex items-start">
                                <i class="fas fa-exclamation-circle text-red-600 mt-1 mr-2 text-xs"></i>
                                <span class="font-semibold">${emergency}</span>
                            </li>`
                        ).join('')}
                    </ul>
                </div>
            </div>
        </div>
        
        <!-- Original Recommendations and Data -->
        <div class="grid md:grid-cols-2 gap-6 mb-6">
            <div class="bg-gray-50 rounded-lg p-4">
                <h4 class="font-semibold mb-3 text-gray-800">
                    <i class="fas fa-user-md mr-2"></i>Basic Medical Recommendations
                </h4>
                <ul class="space-y-2 text-left">
                    ${(prediction.recommendations || []).map(rec => 
                        `<li class="flex items-start">
                            <i class="fas fa-arrow-right text-blue-500 mt-1 mr-2"></i>
                            <span>${rec}</span>
                        </li>`
                    ).join('')}
                </ul>
            </div>
            
            <div class="bg-blue-50 rounded-lg p-4">
                <h4 class="font-semibold mb-3 text-gray-800">
                    <i class="fas fa-heartbeat mr-2"></i>Your Input Data
                </h4>
                <div class="text-left space-y-1 text-sm">
                    <p><strong>Age:</strong> ${formData.age} years</p>
                    <p><strong>Sex:</strong> ${formData.sex === 1 ? 'Male' : 'Female'}</p>
                    <p><strong>Blood Pressure:</strong> ${formData.trestbps} mm Hg</p>
                    <p><strong>Cholesterol:</strong> ${formData.chol} mg/dl</p>
                    <p><strong>Max Heart Rate:</strong> ${formData.thalach} bpm</p>
                </div>
            </div>
        </div>
        
        <!-- Model Information -->
        ${prediction.modelInfo && prediction.modelInfo.sagemaker_available ? `
        <div class="bg-purple-50 rounded-lg p-4 mb-6">
            <h4 class="font-semibold mb-3 text-purple-800">
                <i class="fas fa-cloud mr-2"></i>Model Information
            </h4>
            <div class="text-left space-y-1 text-sm">
                <p><strong>Model:</strong> AWS SageMaker</p>
                <p><strong>Endpoint:</strong> ${prediction.modelInfo.endpoint_name || 'Not configured'}</p>
                <p><strong>Region:</strong> ${prediction.modelInfo.region || 'Not configured'}</p>
            </div>
        </div>
        ` : ''}
        
        <div class="bg-green-50 rounded-lg p-4">
            <h4 class="font-semibold mb-2 text-green-800">
                <i class="fas fa-info-circle mr-2"></i>Important Disclaimer
            </h4>
            <p class="text-sm text-green-700">
                This AI-powered treatment plan is for educational purposes only and should not replace professional medical advice. 
                Always consult with qualified healthcare providers for medical decisions. In case of emergency, call emergency services immediately.
            </p>
        </div>
        
        <div class="mt-6 flex justify-center space-x-4">
            <button onclick="window.print()" 
                    class="bg-blue-600 text-white px-4 py-2 rounded-lg hover:bg-blue-700 transition duration-200">
                <i class="fas fa-print mr-2"></i>Print Results
            </button>
            <button onclick="resetForm()" 
                    class="bg-gray-500 text-white px-4 py-2 rounded-lg hover:bg-gray-600 transition duration-200">
                <i class="fas fa-redo mr-2"></i>New Assessment
            </button>
        </div>
    `;
    
    resultsSection.classList.remove('hidden');
    resultsSection.scrollIntoView({ behavior: 'smooth' });
}

// Load sample data into form
function loadSampleData() {
    const form = document.getElementById('predictionForm');
    
    Object.keys(sampleData).forEach(key => {
        const input = form.querySelector(`[name="${key}"]`);
        if (input) {
            input.value = sampleData[key];
            input.classList.remove('border-red-500');
        }
    });
    
    showNotification('Sample data loaded. Click "Predict Heart Disease Risk" to see results.', 'success');
}

// Reset form
function resetForm() {
    const form = document.getElementById('predictionForm');
    form.reset();
    document.getElementById('resultsSection').classList.add('hidden');
    window.scrollTo({ top: 0, behavior: 'smooth' });
}

// Show loading state
function showLoadingState() {
    const submitButton = document.querySelector('button[type="submit"]');
    submitButton.disabled = true;
    submitButton.innerHTML = '<i class="fas fa-spinner fa-spin mr-2"></i>Analyzing...';
}

// Hide loading state
function hideLoadingState() {
    const submitButton = document.querySelector('button[type="submit"]');
    submitButton.disabled = false;
    submitButton.innerHTML = '<i class="fas fa-search mr-2"></i> Predict Heart Disease Risk';
}

// Show notification
function showNotification(message, type = 'info') {
    const notification = document.createElement('div');
    notification.className = `fixed top-4 right-4 p-4 rounded-lg shadow-lg z-50 ${
        type === 'error' ? 'bg-red-500' : 
        type === 'success' ? 'bg-green-500' : 'bg-blue-500'
    } text-white`;
    notification.innerHTML = `
        <div class="flex items-center">
            <i class="fas ${
                type === 'error' ? 'fa-exclamation-circle' : 
                type === 'success' ? 'fa-check-circle' : 'fa-info-circle'
            } mr-2"></i>
            <span>${message}</span>
        </div>
    `;
    
    document.body.appendChild(notification);
    
    setTimeout(() => {
        notification.remove();
    }, 5000);
}

// Add input validation
function addInputValidation() {
    const numberInputs = document.querySelectorAll('input[type="number"]');
    
    numberInputs.forEach(input => {
        input.addEventListener('input', function() {
            const min = parseFloat(this.min);
            const max = parseFloat(this.max);
            const value = parseFloat(this.value);
            
            if (value < min || value > max || isNaN(value)) {
                this.classList.add('border-red-500');
            } else {
                this.classList.remove('border-red-500');
            }
        });
    });
}

// Add smooth scroll
function addSmoothScroll() {
    document.querySelectorAll('a[href^="#"]').forEach(anchor => {
        anchor.addEventListener('click', function (e) {
            e.preventDefault();
            const target = document.querySelector(this.getAttribute('href'));
            if (target) {
                target.scrollIntoView({ behavior: 'smooth' });
            }
        });
    });
}
