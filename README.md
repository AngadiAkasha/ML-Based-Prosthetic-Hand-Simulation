# ML-Based-Prosthetic-Hand-Simulation

MATLAB implementation of an sEMG-based prosthetic hand simulation framework using NinaPro DB1 and DB4 datasets, RMS feature extraction, machine learning classification, gesture-to-joint mapping, PID control, and 3D hand visualization.

## Project Overview

This project integrates surface electromyography (sEMG) signal processing, machine learning, and control systems to simulate prosthetic-hand movements.

The workflow processes sEMG signals, extracts RMS features, classifies hand gestures, converts predicted gesture labels into five-finger joint-angle references, and uses PID control with a mathematical plant model to simulate finger movement.

## System Workflow

```text
NinaPro DB1 / DB4
        |
        v
sEMG Signal Processing
        |
        v
Sliding Window Segmentation
        |
        v
RMS Feature Extraction
        |
        v
Feature Normalization
        |
        v
Machine Learning Classification
        |
        v
Gesture-to-Finger Angle Mapping
        |
        v
PID Controller and Plant Model
        |
        v
Simulated Finger-Angle Tracking
        |
        v
3D MATLAB Hand Visualization
```

## Repository Structure

- `2_FeatureExtraction/` — Signal processing and feature extraction.
- `3_MachineLearning_DB1/` — Machine learning implementations for NinaPro DB1.
- `3_MachineLearning_DB4 - Copy/` — Machine learning implementations for NinaPro DB4.

Refer to the MATLAB scripts in each folder for the exact execution order and dependencies.

## Technologies Used

- MATLAB
- NinaPro DB1 and DB4 datasets
- RMS feature extraction
- Decision Tree
- K-Nearest Neighbors (KNN)
- Support Vector Machine (SVM)
- Artificial Neural Network (ANN)
- Random Forest
- TabICLv2 (additional classification experiment)
- PID controller
- Ziegler–Nichols and Genetic Algorithm tuning
- MATLAB 3D visualization

## Implementation Steps

### 1. Dataset Preparation

Obtain the authorized NinaPro DB1 or DB4 dataset. Load the sEMG signals and corresponding movement labels. Process the datasets separately because their channel configurations differ.

### 2. Signal Segmentation

The reported segmentation parameters are:

- Window length: 200 samples
- Window increment: 50 samples
- Window overlap: 75%

### 3. RMS Feature Extraction

Calculate the RMS value for each channel in each window:

\[
RMS=\sqrt{\frac{1}{W}\sum_{n=1}^{W}x(n)^2}
\]

DB1 produces 10 RMS features per window, while DB4 produces 12.

### 4. Feature Normalization

Normalize features using statistics calculated from the training data. Apply the same normalization parameters to the evaluation data to avoid data leakage.

### 5. Machine Learning Classification

Train and evaluate Decision Tree, KNN, SVM, ANN, and Random Forest classifiers. TabICLv2 is evaluated as an additional approach.

Evaluate classification using accuracy, macro precision, macro recall, macro F1-score, and confusion matrices.

### 6. Gesture-to-Joint Mapping

Convert the predicted gesture into a five-finger angle vector:

$$
\boldsymbol{\theta}_d =
\begin{bmatrix}
\theta_T & \theta_I & \theta_M & \theta_R & \theta_L
\end{bmatrix}^{T}
$$

The five elements represent the thumb, index, middle, ring, and little fingers.

### 7. PID Control

Calculate the tracking error:

$$
e(t) = \theta_d(t) - \theta_a(t)
$$

The PID controller computes the control signal:

$$
u(t) = K_p e(t)
+ K_i \int_0^t e(\tau)\,d\tau
+ K_d \frac{de(t)}{dt}
$$

where:

- \(K_p\) is the proportional gain.
- \(K_i\) is the integral gain.
- \(K_d\) is the derivative gain.
- \(e(t)\) is the tracking error.
- \(u(t)\) is the controller output.

The controller output is applied to the mathematical plant model to simulate finger movement.

### 8. PID Tuning

The research investigates five PID tuning methods:

1. Ziegler–Nichols
2. Genetic Algorithm
3. Bayesian Optimization
4. Multiple-Shooting Optimization
5. Routh–Hurwitz-based optimization

The methods are compared using rise time, settling time, percentage overshoot, and stability.### 9. 3D Visualization

The MATLAB visualization displays the desired gesture pose and simulated finger movements. This provides a graphical representation of the connection between gesture recognition and controller output.

## Reported Classification Results

The following results are reported in the research paper.

| Model | Dataset | Accuracy |
|---|---|---:|
| KNN | DB1 | 89.15% |
| Decision Tree | DB1 | 80.50% |
| ANN | DB1 | 77.35% |
| SVM | DB1 | 88.82% |
| Random Forest | DB1 | 93.36% |
| TabICLv2 | DB1 | 95.21% |
| KNN | DB4 | 82.77% |
| Random Forest | DB4 | 80.19% |

The reported experiments use selected movement classes. The TabICLv2 result should not be treated as a directly comparable improvement unless the evaluation protocols are confirmed to match.

## Requirements

- MATLAB
- Required MATLAB toolboxes for the implemented scripts
- Authorized NinaPro dataset files
- Project source files and dependencies

## How to Run

1. Download or clone this repository.
2. Open MATLAB and set the project root as the Current Folder.
3. Add the required project folders to the MATLAB path.
4. Place the authorized dataset files in the locations expected by the scripts.
5. Run the feature-extraction entry point.
6. Verify the generated features and labels.
7. Run the appropriate DB1 or DB4 classification script.
8. Configure and run the PID controller simulation.
9. Run the 3D visualization script.
10. Save the evaluation metrics and simulation figures.

**Note:** Check the actual MATLAB filenames and required inputs before running the scripts; execution commands depend on the implementation in each folder.

## Limitations

- Classification results depend on the selected classes and evaluation protocol.
- Subject-independent generalization requires additional testing.
- Gesture-to-angle mapping uses predefined finger configurations.
- PID performance is evaluated through software simulation.
- The 3D hand is a simplified model and does not establish physical or clinical performance.

## Future Work

- Subject-independent gesture recognition
- Cross-dataset validation
- Deep learning-based classification
- Continuous finger-angle estimation
- Improved controller optimization
- Real-time latency measurement
- Physical prosthetic-hand implementation and testing

## License and Dataset Usage

Refer to the repository's `LICENSE` file for software licensing information. NinaPro dataset access and redistribution are subject to the dataset's own terms.

## Disclaimer

This project is intended for academic and educational research. Reported classification and controller results describe the evaluated experiments and do not establish real-time operation, physical prosthetic-hand performance, or clinical effectiveness.
