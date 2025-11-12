# Voice-Controlled-Emotion-Detector-for-Password-Security-using-MyRIO

**🧠 Introduction**

With the increasing dependence on digital systems, data security has become a critical concern. Traditional password-based authentication methods are prone to hacking, password theft, and human error.
To overcome these issues, biometric authentication provides a more secure and convenient approach by using unique human traits. Among biometrics, voice authentication stands out for its ease of use, remote accessibility, and natural human interaction.

This project introduces a Voice-Controlled Emotion-Based Password Security System, which authenticates users based on both voice identity and emotional consistency.
The system ensures that access is granted only when the spoken password and registered voice characteristics match, forming the foundation for emotion-aware, next-generation authentication systems.

**⚙️ Project Overview**
**Phase 1 (Completed)**

Implemented a machine learning-based voice authentication model using MFCC features and the AudioMNIST dataset in MATLAB.

Achieved 94% accuracy in speaker verification.

Validated reliability by correctly accepting genuine users and rejecting impostors.

**Phase 2 (Future Scope)**

Integration of emotion detection to identify user stress, anger, or coercion during login.

Real-time deployment using NI MyRIO hardware for live authentication and device control.

Development of an interactive user interface for registration and verification.

Optimization of the system for speed, efficiency, and embedded use in IoT environments.

**👩‍💻 Work Done**

Developed a noise reduction pipeline to enhance audio clarity and signal quality.

Performed data standardization to ensure consistent feature scaling across all samples.

Implemented and trained the machine learning model for final speaker verification.

Contributed to achieving high accuracy and reliable authentication performance through model tuning and validation.

**📊 Results**

The developed voice-based password authentication system achieved 94% test accuracy.
The confusion matrix displayed strong diagonal dominance, indicating precise classification with minimal misidentification.
The Detection Error Tradeoff (DET) curve demonstrated a balanced performance at a threshold of 0.462, representing an optimal tradeoff between the False Acceptance Rate (FAR) and False Rejection Rate (FRR).

The system performed reliably even with short-duration speech samples, confirming that voice can serve as a powerful biometric for secure authentication.

**🚀 Future Enhancements**

In the next phase, the following improvements will be carried out:

Emotion Recognition Integration: Incorporate models to detect emotional states such as fear, stress, or coercion and deny access under non-neutral conditions.

Real-Time Implementation using NI MyRIO: Deploy the system on MyRIO hardware, using a microphone for live input and controlling physical devices such as relays or locks.

Graphical User Interface: Create an interactive GUI or mobile app for easy user registration, verification, and monitoring.

Performance Optimization: Improve computational efficiency and model compactness for deployment on low-power or IoT devices.

**🧰 Tools and Technologies Used**

- Language: MATLAB

- Dataset: AudioMNIST

- Features Used: MFCC, spectral features

- Model: SVM (Support Vector Machine)

- Hardware (Future): NI MyRIO

- Tools: LabVIEW for integration and deployment

**📈 Key Insights**

Voice-based authentication enhances usability and security simultaneously.

Emotion detection can prevent unauthorized access under coercion or stress.

A lightweight SVM model offers a balance between accuracy and computational efficiency, making it suitable for real-time embedded applications.
