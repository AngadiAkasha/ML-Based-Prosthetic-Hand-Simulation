# ================================================================
# CATBOOST CLASSIFICATION - NINAPRO DB1
#
# Dataset  : NinaPro DB1
# Classes  : 52 movement classes
# Features : 10 RMS features
#
# Pipeline:
#
# AllFeatures.mat
#       |
#       v
#  Remove REST
#       |
#       v
#  80/20 Stratified Split
#       |
#       v
#  Standardization
#       |
#       v
#  CatBoost Multiclass
#       |
#       v
#  Prediction
#       |
#       +---- Accuracy
#       +---- Precision
#       +---- Recall
#       +---- F1
#       +---- Confusion Matrix
#       +---- Feature Importance
#
# ================================================================


# ================================================================
# 1. IMPORT LIBRARIES
# ================================================================

import os
import sys

import numpy as np
import scipy.io as sio
import matplotlib.pyplot as plt
import seaborn as sns
import joblib

from catboost import CatBoostClassifier

from sklearn.model_selection import train_test_split
from sklearn.preprocessing import StandardScaler

from sklearn.metrics import (
    accuracy_score,
    precision_score,
    recall_score,
    f1_score,
    confusion_matrix,
    classification_report
)


# ================================================================
# 2. DISPLAY INFORMATION
# ================================================================

print("\n")
print("=" * 75)
print("              CATBOOST - NINAPRO DB1")
print("=" * 75)

print("")


# ================================================================
# 3. FIND PROJECT PATHS
# ================================================================

# Location of this Python file:
#
# ...\3_MachineLearning_DB1\CatBoost\trainCatBoost.py

current_folder = os.path.dirname(
    os.path.abspath(__file__)
)


# Move one level up:
#
# ...\3_MachineLearning_DB1

machine_learning_folder = os.path.dirname(
    current_folder
)


# Common folder:
#
# ...\3_MachineLearning_DB1\Common

common_folder = os.path.join(
    machine_learning_folder,
    "Common"
)


# AllFeatures.mat

all_features_file = os.path.join(
    common_folder,
    "AllFeatures.mat"
)


# Results folder

results_folder = os.path.join(
    current_folder,
    "Results"
)


# Create Results folder if it doesn't exist

os.makedirs(
    results_folder,
    exist_ok=True
)


print("Project folders:")
print("-" * 75)

print(
    "Machine Learning Folder :"
)
print(
    machine_learning_folder
)

print("")

print(
    "Common Folder           :"
)
print(
    common_folder
)

print("")

print(
    "AllFeatures.mat         :"
)
print(
    all_features_file
)

print("")

print(
    "Results Folder          :"
)
print(
    results_folder
)

print("")


# ================================================================
# 4. CHECK ALLFEATURES.MAT
# ================================================================

if not os.path.exists(all_features_file):

    print("=" * 75)
    print("ERROR")
    print("=" * 75)

    print("")
    print(
        "AllFeatures.mat was not found."
    )

    print("")
    print(
        "Expected location:"
    )

    print(
        all_features_file
    )

    print("")
    print(
        "Please check the Common folder."
    )

    sys.exit(1)


print("=" * 75)
print("Loading AllFeatures.mat")
print("=" * 75)


# ================================================================
# 5. LOAD MATLAB DATA
# ================================================================

try:

    data = sio.loadmat(
        all_features_file
    )

except Exception as e:

    print("")
    print(
        "ERROR while loading AllFeatures.mat"
    )

    print(
        str(e)
    )

    sys.exit(1)


print("")
print("Variables available in AllFeatures.mat:")
print("-" * 75)


for key in data.keys():

    if not key.startswith("__"):

        try:

            print(
                f"{key:20s} : {data[key].shape}"
            )

        except Exception:

            print(
                f"{key:20s}"
            )


# ================================================================
# 6. CHECK REQUIRED VARIABLES
# ================================================================

if "allFeat" not in data:

    print("")
    print(
        "ERROR: allFeat was not found."
    )

    print(
        "AllFeatures.mat must contain allFeat."
    )

    sys.exit(1)


if "allStim" not in data:

    print("")
    print(
        "ERROR: allStim was not found."
    )

    print(
        "AllFeatures.mat must contain allStim."
    )

    sys.exit(1)


# ================================================================
# 7. READ FEATURES
# ================================================================

X = np.asarray(
    data["allFeat"],
    dtype=np.float64
)


# Convert labels to 1-D vector

y = np.asarray(
    data["allStim"]
).ravel()


print("")
print("=" * 75)
print("Original Dataset")
print("=" * 75)

print(
    f"Feature matrix : {X.shape}"
)

print(
    f"Label vector   : {y.shape}"
)


# ================================================================
# 8. CHECK NUMBER OF FEATURES
# ================================================================

number_of_features = X.shape[1]

print("")
print(
    f"Number of features : {number_of_features}"
)


if number_of_features != 10:

    print("")
    print(
        "WARNING:"
    )

    print(
        "The dataset does not contain exactly 10 features."
    )

    print(
        "Your current DB1 experiment is expected to use"
    )

    print(
        "10 RMS features."
    )

    print("")

    # Do not stop automatically.
    # This allows the program to inspect the dataset.


# ================================================================
# 9. REMOVE NaN AND INF VALUES
# ================================================================

print("")
print(
    "Checking invalid values..."
)


valid_rows = (
    np.isfinite(X).all(axis=1)
    &
    np.isfinite(y)
)


invalid_count = np.sum(
    ~valid_rows
)


print(
    f"Invalid rows found : {invalid_count}"
)


if invalid_count > 0:

    X = X[valid_rows]

    y = y[valid_rows]


print("")
print(
    f"Dataset after cleaning : {X.shape}"
)


# ================================================================
# 10. DISPLAY ORIGINAL CLASSES
# ================================================================

original_classes = np.unique(
    y
)


print("")
print("=" * 75)
print("Original Classes")
print("=" * 75)

print(
    original_classes
)

print("")
print(
    f"Number of original classes : {len(original_classes)}"
)


# ================================================================
# 11. REMOVE REST CLASS
# ================================================================

# In your DB1 classification experiment:
#
# 0      = REST
# 1-52   = movement classes
#
# We train CatBoost only on the 52 movement classes.

print("")
print("=" * 75)
print("Removing REST class")
print("=" * 75)


movement_mask = (
    y >= 1
)


X = X[movement_mask]

y = y[movement_mask]


print(
    f"Dataset after removing REST : {X.shape}"
)


# ================================================================
# 12. VERIFY 52 CLASSES
# ================================================================

classes = np.unique(
    y
)


print("")
print("=" * 75)
print("Class Verification")
print("=" * 75)

print(
    "Classes:"
)

print(
    classes
)

print("")

print(
    f"Number of classes : {len(classes)}"
)


# Expected classes:
#
# 1, 2, 3, ..., 52

expected_classes = np.arange(
    1,
    53
)


if len(classes) != 52:

    print("")
    print(
        "ERROR:"
    )

    print(
        f"Expected 52 classes but found {len(classes)}."
    )

    print("")
    print(
        "CatBoost training stopped."
    )

    sys.exit(1)


if not np.array_equal(
    classes,
    expected_classes
):

    print("")
    print(
        "ERROR:"
    )

    print(
        "Class labels are not exactly 1 to 52."
    )

    print("")
    print(
        "Expected:"
    )

    print(
        expected_classes
    )

    print("")
    print(
        "Found:"
    )

    print(
        classes
    )

    sys.exit(1)


print("")
print(
    "SUCCESS: Exactly 52 movement classes found."
)


# ================================================================
# 13. CLASS DISTRIBUTION
# ================================================================

print("")
print("=" * 75)
print("Class Distribution")
print("=" * 75)

for class_id in classes:

    count = np.sum(
        y == class_id
    )

    print(
        f"Class {int(class_id):2d} : {count:6d} samples"
    )


# ================================================================
# 14. TRAIN / TEST SPLIT
# ================================================================

print("")
print("=" * 75)
print("Creating Train/Test Split")
print("=" * 75)

print("")
print(
    "Train : 80%"
)

print(
    "Test  : 20%"
)

print(
    "Random State : 42"
)


X_train, X_test, y_train, y_test = train_test_split(

    X,

    y,

    test_size=0.20,

    random_state=42,

    stratify=y
)


print("")
print(
    f"Training samples : {X_train.shape[0]}"
)

print(
    f"Testing samples  : {X_test.shape[0]}"
)

print(
    f"Features         : {X_train.shape[1]}"
)


# ================================================================
# 15. NORMALIZATION
# ================================================================

print("")
print("=" * 75)
print("Feature Normalization")
print("=" * 75)

print("")
print(
    "Using StandardScaler"
)

print(
    "Scaler is fitted ONLY on training data."
)


scaler = StandardScaler()


# Fit on training data

X_train = scaler.fit_transform(
    X_train
)


# Apply same transformation to test data

X_test = scaler.transform(
    X_test
)


print("")
print(
    "Normalization completed."
)


# ================================================================
# 16. CREATE CATBOOST MODEL
# ================================================================

print("")
print("=" * 75)
print("Creating CatBoost Model")
print("=" * 75)


model = CatBoostClassifier(

    # Number of boosting iterations
    iterations=500,

    # Learning rate
    learning_rate=0.05,

    # Maximum tree depth
    depth=6,

    # Multiclass objective
    loss_function="MultiClass",

    # Evaluation metric
    eval_metric="Accuracy",

    # Random seed
    random_seed=42,

    # L2 regularization
    l2_leaf_reg=3,

    # Random strength
    random_strength=1,

    # Bayesian bootstrap
    bootstrap_type="Bayesian",

    # Early stopping
    od_type="Iter",

    od_wait=50,

    # Training progress
    verbose=50,

    # CPU
    task_type="CPU"
)


print("")
print(
    "CatBoost parameters:"
)

print(
    "Iterations       : 500"
)

print(
    "Learning Rate    : 0.05"
)

print(
    "Depth            : 6"
)

print(
    "Loss Function    : MultiClass"
)

print(
    "Random Seed      : 42"
)

print(
    "Task Type        : CPU"
)


# ================================================================
# 17. TRAIN CATBOOST
# ================================================================

print("")
print("")
print("=" * 75)
print("STARTING CATBOOST TRAINING")
print("=" * 75)

print("")


model.fit(

    X_train,

    y_train,

    eval_set=(
        X_test,
        y_test
    ),

    use_best_model=True
)


print("")
print("=" * 75)
print("CATBOOST TRAINING COMPLETED")
print("=" * 75)


# ================================================================
# 18. BEST ITERATION
# ================================================================

try:

    best_iteration = (
        model.get_best_iteration()
    )

except Exception:

    best_iteration = -1


print("")
print(
    f"Best iteration : {best_iteration}"
)


# ================================================================
# 19. PREDICTION
# ================================================================

print("")
print("=" * 75)
print("Predicting Test Data")
print("=" * 75)


y_pred = model.predict(
    X_test
)


# CatBoost may return:
#
# [[1],
#  [2],
#  [3]]
#
# Convert to:
#
# [1, 2, 3]

y_pred = np.asarray(
    y_pred
).ravel()


y_pred = y_pred.astype(
    int
)

y_test = y_test.astype(
    int
)


print("")
print(
    "Prediction completed."
)


# ================================================================
# 20. CALCULATE ACCURACY
# ================================================================

accuracy = accuracy_score(

    y_test,

    y_pred
)


# ================================================================
# 21. CALCULATE MACRO PRECISION
# ================================================================

macro_precision = precision_score(

    y_test,

    y_pred,

    labels=expected_classes,

    average="macro",

    zero_division=0
)


# ================================================================
# 22. CALCULATE MACRO RECALL
# ================================================================

macro_recall = recall_score(

    y_test,

    y_pred,

    labels=expected_classes,

    average="macro",

    zero_division=0
)


# ================================================================
# 23. CALCULATE MACRO F1
# ================================================================

macro_f1 = f1_score(

    y_test,

    y_pred,

    labels=expected_classes,

    average="macro",

    zero_division=0
)


# ================================================================
# 24. CALCULATE WEIGHTED F1
# ================================================================

weighted_f1 = f1_score(

    y_test,

    y_pred,

    labels=expected_classes,

    average="weighted",

    zero_division=0
)


# ================================================================
# 25. DISPLAY FINAL RESULTS
# ================================================================

print("")
print("")
print("=" * 75)
print("             CATBOOST FINAL RESULTS - DB1")
print("=" * 75)

print("")

print(
    f"Classes          : {len(classes)}"
)

print(
    f"Training Samples : {len(y_train)}"
)

print(
    f"Testing Samples  : {len(y_test)}"
)

print(
    f"Features         : {X_train.shape[1]}"
)

print("")

print(
    f"Accuracy         : {accuracy * 100:.2f} %"
)

print(
    f"Macro Precision  : {macro_precision * 100:.2f} %"
)

print(
    f"Macro Recall     : {macro_recall * 100:.2f} %"
)

print(
    f"Macro F1         : {macro_f1 * 100:.2f} %"
)

print(
    f"Weighted F1      : {weighted_f1 * 100:.2f} %"
)

print("")

print("=" * 75)


# ================================================================
# 26. CLASSIFICATION REPORT
# ================================================================

print("")
print("=" * 75)
print("CLASSIFICATION REPORT")
print("=" * 75)


report = classification_report(

    y_test,

    y_pred,

    labels=expected_classes,

    digits=4,

    zero_division=0
)


print(
    report
)


# ================================================================
# 27. CONFUSION MATRIX
# ================================================================

print("")
print("=" * 75)
print("Creating Confusion Matrix")
print("=" * 75)


cm = confusion_matrix(

    y_test,

    y_pred,

    labels=expected_classes
)


plt.figure(
    figsize=(18, 16)
)


sns.heatmap(

    cm,

    cmap="Blues",

    xticklabels=expected_classes,

    yticklabels=expected_classes,

    cbar=True
)


plt.xlabel(
    "Predicted Class"
)

plt.ylabel(
    "True Class"
)

plt.title(
    "CatBoost Confusion Matrix - NinaPro DB1"
)


plt.tight_layout()


confusion_matrix_file = os.path.join(

    results_folder,

    "CatBoost_DB1_ConfusionMatrix.png"
)


plt.savefig(

    confusion_matrix_file,

    dpi=300,

    bbox_inches="tight"
)


plt.close()


print("")
print(
    "Confusion matrix saved:"
)

print(
    confusion_matrix_file
)


# ================================================================
# 28. FEATURE IMPORTANCE
# ================================================================

print("")
print("=" * 75)
print("Calculating Feature Importance")
print("=" * 75)


feature_importance = (
    model.get_feature_importance()
)


# Your current experiment has 10 features

feature_names = [

    "Feature 1",

    "Feature 2",

    "Feature 3",

    "Feature 4",

    "Feature 5",

    "Feature 6",

    "Feature 7",

    "Feature 8",

    "Feature 9",

    "Feature 10"

]


# If number of features is not 10,
# generate names automatically.

if len(feature_names) != X_train.shape[1]:

    feature_names = [

        f"Feature {i + 1}"

        for i in range(
            X_train.shape[1]
        )

    ]


plt.figure(
    figsize=(12, 6)
)


plt.bar(

    feature_names,

    feature_importance
)


plt.xlabel(
    "Feature"
)

plt.ylabel(
    "Importance"
)

plt.title(
    "CatBoost Feature Importance - NinaPro DB1"
)


plt.xticks(
    rotation=45
)


plt.tight_layout()


feature_importance_file = os.path.join(

    results_folder,

    "CatBoost_DB1_FeatureImportance.png"
)


plt.savefig(

    feature_importance_file,

    dpi=300,

    bbox_inches="tight"
)


plt.close()


print("")
print(
    "Feature importance saved:"
)

print(
    feature_importance_file
)


# ================================================================
# 29. PRINT FEATURE IMPORTANCE VALUES
# ================================================================

print("")
print("=" * 75)
print("Feature Importance Values")
print("=" * 75)


for name, importance in zip(

    feature_names,

    feature_importance

):

    print(
        f"{name:15s} : {importance:.6f}"
    )


# ================================================================
# 30. SAVE CATBOOST MODEL
# ================================================================

print("")
print("=" * 75)
print("Saving CatBoost Model")
print("=" * 75)


model_file = os.path.join(

    results_folder,

    "CatBoost_DB1_Model.cbm"
)


model.save_model(
    model_file
)


print("")
print(
    "Model saved:"
)

print(
    model_file
)


# ================================================================
# 31. SAVE SCALER
# ================================================================

scaler_file = os.path.join(

    results_folder,

    "CatBoost_DB1_Scaler.pkl"
)


joblib.dump(

    scaler,

    scaler_file
)


print("")
print(
    "Scaler saved:"
)

print(
    scaler_file
)


# ================================================================
# 32. SAVE PREDICTIONS
# ================================================================

prediction_file = os.path.join(

    results_folder,

    "CatBoost_DB1_Predictions.npz"
)


np.savez(

    prediction_file,

    y_test=y_test,

    y_pred=y_pred
)


print("")
print(
    "Predictions saved:"
)

print(
    prediction_file
)


# ================================================================
# 33. SAVE METRICS TO TEXT FILE
# ================================================================

results_file = os.path.join(

    results_folder,

    "CatBoost_DB1_Results.txt"
)


with open(

    results_file,

    "w",

    encoding="utf-8"

) as f:

    f.write(
        "CATBOOST - NINAPRO DB1\n"
    )

    f.write(
        "============================\n\n"
    )

    f.write(
        f"Number of classes : {len(classes)}\n"
    )

    f.write(
        f"Training samples  : {len(y_train)}\n"
    )

    f.write(
        f"Testing samples   : {len(y_test)}\n"
    )

    f.write(
        f"Number of features: {X_train.shape[1]}\n"
    )

    f.write(
        f"Best iteration    : {best_iteration}\n\n"
    )

    f.write(
        "MODEL PARAMETERS\n"
    )

    f.write(
        "----------------------------\n"
    )

    f.write(
        "Iterations      : 500\n"
    )

    f.write(
        "Learning Rate   : 0.05\n"
    )

    f.write(
        "Depth           : 6\n"
    )

    f.write(
        "Loss Function   : MultiClass\n"
    )

    f.write(
        "Random Seed     : 42\n\n"
    )

    f.write(
        "PERFORMANCE\n"
    )

    f.write(
        "----------------------------\n"
    )

    f.write(
        f"Accuracy        : "
        f"{accuracy * 100:.2f}%\n"
    )

    f.write(
        f"Macro Precision : "
        f"{macro_precision * 100:.2f}%\n"
    )

    f.write(
        f"Macro Recall    : "
        f"{macro_recall * 100:.2f}%\n"
    )

    f.write(
        f"Macro F1        : "
        f"{macro_f1 * 100:.2f}%\n"
    )

    f.write(
        f"Weighted F1     : "
        f"{weighted_f1 * 100:.2f}%\n\n"
    )

    f.write(
        "CLASSIFICATION REPORT\n"
    )

    f.write(
        "============================\n"
    )

    f.write(
        report
    )


print("")
print(
    "Results saved:"
)

print(
    results_file
)


# ================================================================
# 34. FINAL SUMMARY
# ================================================================

print("")
print("")
print("=" * 75)
print("          CATBOOST DB1 EXPERIMENT COMPLETED")
print("=" * 75)

print("")

print(
    "Final Accuracy        : "
    f"{accuracy * 100:.2f}%"
)

print(
    "Final Macro Precision : "
    f"{macro_precision * 100:.2f}%"
)

print(
    "Final Macro Recall    : "
    f"{macro_recall * 100:.2f}%"
)

print(
    "Final Macro F1        : "
    f"{macro_f1 * 100:.2f}%"
)

print(
    "Final Weighted F1     : "
    f"{weighted_f1 * 100:.2f}%"
)

print("")

print(
    "Output folder:"
)

print(
    results_folder
)

print("")

print(
    "Generated files:"
)

print(
    "1. CatBoost_DB1_Model.cbm"
)

print(
    "2. CatBoost_DB1_Scaler.pkl"
)

print(
    "3. CatBoost_DB1_Predictions.npz"
)

print(
    "4. CatBoost_DB1_Results.txt"
)

print(
    "5. CatBoost_DB1_ConfusionMatrix.png"
)

print(
    "6. CatBoost_DB1_FeatureImportance.png"
)

print("")

print("=" * 75)