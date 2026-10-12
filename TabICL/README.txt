# TabICLv2 DB1 package

## Folder placement
Place this `TabICL` folder under:
`3_MachineLearning_DB1/TabICL/`

The script expects:
`3_MachineLearning_DB1/Common/AllFeatures.mat`

with MATLAB variables `allFeat` and `allStim`, and movement labels globally mapped to 1..52. Label 0 (rest) is excluded.

## Run
In Command Prompt:
```cmd
"%USERPROFILE%\tabicl_env\Scripts\activate"
cd /d "YOUR_PROJECT_PATH\3_MachineLearning_DB1\TabICL"
python -u trainTabICL.py
```

## Generated files
Under `Results/`:
- `PredictionResults_TabICL.mat`: `predictedLabel`, `testLabel`, `predictedClasses`, `testClasses`, `accuracy`, `predictionTime`; `predictionScores` is included only if supported by the installed API.
- `EvaluationResults_TabICL.mat`: metrics, timings, confusion matrix, class labels.
- `TabICL_Model.pkl`: serialized fitted object if joblib serialization succeeds.
- `metrics.txt`, `classification_report.txt`, `confusion_matrix.csv`, `confusion_matrix.png`, `split_indices.npz`.

The `.mat` files are the MATLAB hand-off outputs. The `.pkl` file is Python-specific and is not a MATLAB RF_Model.mat equivalent. TabICLv2 is pretrained and uses in-context learning; do not describe this as training a foundation model from scratch.

## MATLAB
After the Python run, from MATLAB change directory to this folder and run:
```matlab
evaluateTabICL
[predictedLabel, testLabel] = testTabICL;
```

Important: existing prosthetic-hand demo scripts may assume a particular label mapping and exact variable names. Verify them before swapping Random Forest predictions for TabICLv2.
