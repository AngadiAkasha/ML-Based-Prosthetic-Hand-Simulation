# ML-Based-Prosthetic-Hand-Simulation

A MATLAB-based sEMG prosthetic-hand simulation framework integrating signal processing, machine learning, gesture-to-joint mapping, PID control, and 3D hand visualization using the NinaPro DB1 and DB4 datasets.

## Project Overview

This project investigates the integration of surface electromyography (sEMG)-based gesture recognition and feedback control for simulated prosthetic-hand movement.

The framework processes sEMG signals, extracts Root Mean Square (RMS) features, classifies hand movements, maps predicted gestures to predefined finger-joint angles, and applies PID control with a mathematical plant model to simulate finger trajectories in MATLAB.

The project also compares machine learning classifiers and investigates multiple PID tuning strategies.

## System Workflow

```text
NinaPro DB1 / DB4
        |
        v
sEMG Signal Processing
        |
        v
Sliding-Window Segmentation
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
Finger-Angle Trajectory Simulation
        |
        v
3D MATLAB Prosthetic-Hand Visualization
```

## Repository Structure

```text
ML-Based-Prosthetic-Hand-Simulation/
|
|-- 2_FeatureExtraction/
|   |-- Feature extraction and signal processing scripts
|
|-- 3_MachineLearning_DB1/
|   |-- DB1 machine learning implementations
|
|-- 3_MachineLearning_DB4 - Copy/
|   |-- DB4 machine learning implementations
|
|-- README.md
```

The directory descriptions are indicative. Refer to the actual MATLAB files in each folder to identify the entry-point scripts, dependencies, and execution order.

## Technologies Used

- MATLAB
- NinaPro DB1 and DB4 datasets
- sEMG signal processing
- RMS feature extraction
- Decision Tree
- K-Nearest Neighbors (KNN)
- Support Vector Machine (SVM)
- Artificial Neural Network (ANN)
- Random Forest
- TabICLv2 as an additional classification approach
- PID control and mathematical plant modeling
- Ziegler–Nichols tuning
- Genetic Algorithm (GA)
- Bayesian Optimization
- Multiple-Shooting Optimization
- Routh–Hurwitz-based optimization
- MATLAB 3D visualization

## Methodology

### 1. Dataset Preparation

The framework uses NinaPro DB1 and DB4. Obtain the datasets through their authorized access procedures and organize the files according to the paths expected by the MATLAB scripts.

The datasets are processed separately because their sEMG channel counts and sampling frequencies differ.

### 2. Signal Segmentation

The reported segmentation parameters are:

| Parameter | Value |
|---|---:|
| Window length | 200 samples |
| Window increment | 50 samples |
| Window overlap | 75% |

The corresponding window durations depend on the dataset sampling frequency. With the reported frequencies of 100 Hz for DB1 and 2000 Hz for DB4, a 200-sample window represents 2 seconds for DB1 and 0.1 seconds for DB4.

### 3. RMS Feature Extraction

RMS features represent the signal amplitude within each analysis window.

The RMS feature for a window is calculated as:

$$
RMS=\sqrt{\frac{1}{W}\sum_{n=1}^{W}x(n)^2}
$$

where \(x(n)\) is the sEMG sample and \(W\) is the window length.

With one RMS feature per channel:

- DB1 produces 10 features per window.
- DB4 produces 12 features per window.

### 4. Feature Normalization

Normalize the extracted features using statistics calculated from the training set. Apply the same transformation to validation and test data.

This prevents information from the evaluation data from leaking into the training process.

### 5. Machine Learning Classification

The conventional classifiers investigated include:

- Decision Tree
- KNN
- SVM
- ANN
- Random Forest

TabICLv2 is evaluated as an additional classification approach.

The reported evaluation metrics include accuracy, macro precision, macro recall, macro F1-score, and confusion matrices.

### 6. Gesture-to-Finger Angle Mapping

Predicted gesture labels are mapped to predefined finger-angle references.

The desired joint-angle vector is represented as:

$$
\boldsymbol{\theta}_d =
\begin{bmatrix}
\theta_T & \theta_I & \theta_M & \theta_R & \theta_L
\end{bmatrix}^{T}
$$

where \(T\), \(I\), \(M\), \(R\), and \(L\) denote the thumb, index, middle, ring, and little fingers, respectively.

The mapping uses predefined finger configurations; it does not by itself establish continuous joint-angle estimation from sEMG.

### 7. PID Controller

The tracking error is calculated as:

$$
e(t)=\theta_d(t)-\theta_a(t)
$$

The PID controller computes its control signal using:

$$
u(t)=K_p e(t)
+K_i\int_0^t e(\tau)\,d\tau
+K_d\frac{de(t)}{dt}
$$

where:

- \(K_p\): proportional gain
- \(K_i\): integral gain
- \(K_d\): derivative gain
- \(e(t)\): tracking error
- \(u(t)\): controller output

The control signal is applied to the mathematical plant model to simulate finger movement.

### 8. PID Tuning and Comparison

The research investigates five PID tuning approaches:

1. Ziegler–Nichols
2. Genetic Algorithm
3. Bayesian Optimization
4. Multiple-Shooting Optimization
5. Routh–Hurwitz-based optimization

The tuning methods are compared using rise time, settling time, percentage overshoot, and stability.

The numerical results should be taken from the final validated MATLAB experiment outputs. Different controller implementations or result tables should not be combined without verifying their configurations.

### 9. 3D Visualization

The MATLAB visualization displays the simulated prosthetic-hand pose and finger movements. It provides a graphical representation of the relationship between gesture classification, desired joint angles, and simulated controller response.

The visualization is a software simulation and does not demonstrate the performance of a physical prosthetic device.

## Reported Classification Results

The following values are reported in the current research manuscript. They should be interpreted in the context of the corresponding dataset, class selection, data split, and evaluation protocol.

| Model | Dataset | Accuracy | Macro Precision | Macro Recall | Macro F1-score |
|---|---|---:|---:|---:|---:|
| TabICLv2 | DB1 | 95.21% | 95.25% | 95.21% | 95.21% |
| Random Forest | DB1 | 85.46% | 85.77% | 85.46% | 85.44% |
| Random Forest | DB4 | 80.08% | 73.39% | 63.54% | 67.95% |
| KNN | DB1 | 75.06% | 75.62% | 75.07% | 75.03% |
| SVM | DB1 | 74.30% | 75.00% | 74.31% | 74.31% |
| Decision Tree | DB1 | 56.47% | 56.59% | 56.47% | 56.33% |
| ANN | DB1 | 38.92% | 36.97% | 38.93% | 38.77% |

**Important:** These values are reported manuscript results, not independently revalidated measurements. Confirm them against the final result files before treating this table as the definitive benchmark. In particular, do not combine these values with earlier experiments that used different movement classes or evaluation protocols.

TabICLv2 is an additional approach and should only be compared directly with the conventional classifiers when the evaluation conditions are equivalent.

## Requirements

- MATLAB
- NinaPro DB1 and/or DB4 dataset files obtained through authorized access
- Required MATLAB toolboxes, depending on the scripts used
- Project source files and their dependencies
- Any additional dependencies required by the TabICLv2 experiment, if applicable

## How to Run

1. Clone or download the repository.
2. Open MATLAB and set the repository root as the Current Folder.
3. Add the required project folders to the MATLAB path.
4. Place the authorized dataset files in the locations expected by the scripts.
5. Run the appropriate feature-extraction script.
6. Verify the generated feature matrices and labels.
7. Run the selected DB1 or DB4 classification script.
8. Inspect the evaluation metrics and confusion matrices.
9. Configure and run the PID controller simulation.
10. Run the 3D hand visualization script.
11. Save the final classification metrics, controller measurements, and figures.

The exact script names and execution commands depend on the files present in each directory. Check each script's input requirements before execution.

## Limitations

- Classification performance depends on the dataset, movement classes, data split, and evaluation protocol.
- Subject-independent generalization requires dedicated testing.
- DB1 and DB4 have different sampling frequencies, so identical window lengths in samples do not represent identical durations.
- Gesture-to-angle mapping relies on predefined configurations.
- PID performance is evaluated through software simulation.
- A 3D visualization does not establish physical device performance or clinical effectiveness.
- Reported benchmark results require reproducible experiment configurations and saved evaluation outputs.

## Future Work

- Subject-independent gesture recognition
- Cross-dataset evaluation
- Deep learning-based sEMG classification
- Continuous finger-angle estimation
- Improved controller optimization and robustness
- Real-time latency and computational-cost measurement
- Physical prosthetic-hand implementation and testing

## License and Dataset Usage

Refer to the repository's `LICENSE` file for the software licensing terms.

NinaPro dataset access, use, and redistribution are governed by the dataset's own terms. Do not upload restricted raw dataset files to the repository unless redistribution is explicitly permitted.

## Disclaimer

This project is intended for academic and educational research. Reported classification and controller measurements describe specific experiments and do not establish real-time operation, physical prosthetic-hand performance, or clinical effectiveness.
