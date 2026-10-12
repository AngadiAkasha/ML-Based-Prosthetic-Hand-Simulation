"""
TabICLv2 on NinaPro DB1 (52 movement classes).
Run inside the tabicl_env Python environment:
    python -u trainTabICL.py

Input:
    ../Common/AllFeatures.mat with allFeat and allStim

Outputs in Results/:
    PredictionResults_TabICL.mat
    EvaluationResults_TabICL.mat
    TabICL_Model.pkl
    metrics.txt
    classification_report.txt
    confusion_matrix.csv
    confusion_matrix.png
    split_indices.npz
"""
import sys, time, traceback
from pathlib import Path

import numpy as np
import scipy.io as sio
from scipy.io import savemat
import matplotlib
matplotlib.use("Agg")
import matplotlib.pyplot as plt
import seaborn as sns
from joblib import dump
from tabicl import TabICLClassifier
from sklearn.model_selection import train_test_split
from sklearn.metrics import (
    accuracy_score, precision_score, recall_score, f1_score,
    classification_report, confusion_matrix
)

HERE = Path(__file__).resolve().parent
DATA_FILE = HERE.parent / "Common" / "AllFeatures.mat"
OUT = HERE / "Results"
OUT.mkdir(parents=True, exist_ok=True)
SEED = 42
TEST_SIZE = 0.20
CLASSES = np.arange(1, 53, dtype=np.int64)

def load_data():
    print(f"Loading: {DATA_FILE}")
    if not DATA_FILE.exists():
        raise FileNotFoundError(
            f"Cannot find {DATA_FILE}. Put AllFeatures.mat in "
            "3_MachineLearning_DB1/Common/."
        )
    mat = sio.loadmat(DATA_FILE)
    if "allFeat" not in mat or "allStim" not in mat:
        raise KeyError(f"Expected allFeat and allStim. Found: {list(mat)}")
    X = np.asarray(mat["allFeat"], dtype=np.float32)
    y0 = np.asarray(mat["allStim"]).reshape(-1)
    if X.ndim != 2 or len(y0) != X.shape[0]:
        raise ValueError(f"Shape mismatch: X={X.shape}, labels={y0.shape}")
    if not np.isfinite(y0).all() or not np.allclose(y0, np.round(y0)):
        raise ValueError("Labels must be finite integer values.")
    y = np.round(y0).astype(np.int64)
    # Exclude rest label 0 and rows with non-finite feature values.
    keep = (y != 0) & np.isfinite(X).all(axis=1)
    X, y = X[keep], y[keep]
    observed = np.unique(y)
    unexpected = np.setdiff1d(observed, CLASSES)
    missing = np.setdiff1d(CLASSES, observed)
    if unexpected.size:
        raise ValueError(f"Unexpected labels {unexpected.tolist()}; expected 1..52.")
    if missing.size:
        raise ValueError(
            f"Missing labels {missing.tolist()}. Check that DB1 exercise labels "
            "were converted to global labels 1..52 correctly."
        )
    counts = np.unique(y, return_counts=True)[1]
    if counts.min() < 2:
        raise ValueError("Every class needs at least two samples for stratification.")
    print(f"X shape: {X.shape}; classes: {len(observed)}; samples: {len(y)}")
    return X, y

def main():
    start = time.time()
    X, y = load_data()
    # Save original row indices are not recoverable after row filtering here;
    # these indices refer to the filtered X/y arrays.
    idx = np.arange(len(y))
    train_idx, test_idx = train_test_split(
        idx, test_size=TEST_SIZE, random_state=SEED, stratify=y
    )
    X_train, X_test = X[train_idx], X[test_idx]
    y_train, y_test = y[train_idx], y[test_idx]
    np.savez_compressed(OUT / "split_indices.npz",
                        train_idx=train_idx, test_idx=test_idx)

    print("Initializing TabICLv2 on CPU. First run may download a checkpoint.")
    model = TabICLClassifier(
        n_estimators=8,
        support_many_classes=True,
        batch_size=1,
        device="cpu",
        n_jobs=2,
        random_state=SEED,
        verbose=True,
        allow_auto_download=True,
        offload_mode="auto",
    )

    t0 = time.time()
    model.fit(X_train, y_train)
    fit_seconds = time.time() - t0
    print(f"Fit/context preparation time: {fit_seconds:.2f} seconds")

    print("Predicting test samples...")
    t0 = time.time()
    y_pred = np.asarray(model.predict(X_test)).reshape(-1).astype(np.int64)
    predict_seconds = time.time() - t0
    if y_pred.size != y_test.size:
        raise RuntimeError(f"Expected {y_test.size} predictions; got {y_pred.size}.")

    acc = accuracy_score(y_test, y_pred)
    p = precision_score(y_test, y_pred, labels=CLASSES, average="macro", zero_division=0)
    r = recall_score(y_test, y_pred, labels=CLASSES, average="macro", zero_division=0)
    f1m = f1_score(y_test, y_pred, labels=CLASSES, average="macro", zero_division=0)
    f1w = f1_score(y_test, y_pred, labels=CLASSES, average="weighted", zero_division=0)
    report = classification_report(y_test, y_pred, labels=CLASSES, zero_division=0, digits=4)
    cm = confusion_matrix(y_test, y_pred, labels=CLASSES)

    # Probabilities are optional: save them only if the installed TabICL API supports it.
    scores = np.empty((0, 0), dtype=np.float64)
    try:
        if hasattr(model, "predict_proba"):
            prob = np.asarray(model.predict_proba(X_test))
            model_classes = np.asarray(getattr(model, "classes_", CLASSES)).reshape(-1)
            if prob.ndim == 2 and prob.shape[0] == len(y_test):
                if len(model_classes) == prob.shape[1] and set(model_classes.tolist()) == set(CLASSES.tolist()):
                    order = [int(np.where(model_classes == c)[0][0]) for c in CLASSES]
                    scores = prob[:, order].T.astype(np.float64)  # 52 x N
                elif prob.shape[1] == len(CLASSES):
                    scores = prob.T.astype(np.float64)
    except Exception as e:
        print(f"Probability export skipped (predictions are still valid): {e}")

    prediction_mat = {
        "predictedLabel": y_pred.reshape(1, -1).astype(np.float64),
        "testLabel": y_test.reshape(1, -1).astype(np.float64),
        "predictedClasses": CLASSES.reshape(1, -1).astype(np.float64),
        "testClasses": CLASSES.reshape(1, -1).astype(np.float64),
        "accuracy": np.array([[acc]], dtype=np.float64),
        "predictionTime": np.array([[predict_seconds]], dtype=np.float64),
    }
    if scores.size:
        prediction_mat["predictionScores"] = scores
    savemat(str(OUT / "PredictionResults_TabICL.mat"), prediction_mat)

    eval_mat = {
        "accuracy": np.array([[acc]], dtype=np.float64),
        "macroPrecision": np.array([[p]], dtype=np.float64),
        "macroRecall": np.array([[r]], dtype=np.float64),
        "macroF1": np.array([[f1m]], dtype=np.float64),
        "weightedF1": np.array([[f1w]], dtype=np.float64),
        "fitTime": np.array([[fit_seconds]], dtype=np.float64),
        "predictionTime": np.array([[predict_seconds]], dtype=np.float64),
        "totalTime": np.array([[time.time() - start]], dtype=np.float64),
        "confusionMatrix": cm.astype(np.float64),
        "classLabels": CLASSES.reshape(1, -1).astype(np.float64),
    }
    savemat(str(OUT / "EvaluationResults_TabICL.mat"), eval_mat)

    with open(OUT / "metrics.txt", "w", encoding="utf-8") as f:
        f.write("TabICLv2 - NinaPro DB1\n")
        f.write(f"Accuracy: {acc:.6f} ({acc*100:.2f}%)\n")
        f.write(f"Macro precision: {p:.6f}\nMacro recall: {r:.6f}\n")
        f.write(f"Macro F1: {f1m:.6f}\nWeighted F1: {f1w:.6f}\n")
        f.write(f"Fit/context preparation time: {fit_seconds:.2f} s\n")
        f.write(f"Prediction time: {predict_seconds:.2f} s\n")
        f.write(f"Total time: {time.time()-start:.2f} s\n")
    (OUT / "classification_report.txt").write_text(report, encoding="utf-8")
    np.savetxt(OUT / "confusion_matrix.csv", cm, delimiter=",", fmt="%d")

    plt.figure(figsize=(20, 17))
    sns.heatmap(cm, cmap="Blues", xticklabels=CLASSES, yticklabels=CLASSES)
    plt.xlabel("Predicted class")
    plt.ylabel("True class")
    plt.title("TabICLv2 - NinaPro DB1 Confusion Matrix")
    plt.tight_layout()
    plt.savefig(OUT / "confusion_matrix.png", dpi=180)
    plt.close()

    # Save the fitted object for possible reuse. Re-loading may depend on the
    # TabICL version and its checkpoint availability; the .mat predictions are
    # the stable hand-off artifact for MATLAB.
    try:
        dump(model, OUT / "TabICL_Model.pkl")
        print("Saved TabICL_Model.pkl")
    except Exception as e:
        print(f"Model object could not be serialized: {e}")

    print("\n" + "=" * 50)
    print(f"Accuracy:          {acc*100:.2f}%")
    print(f"Macro precision:   {p:.4f}")
    print(f"Macro recall:      {r:.4f}")
    print(f"Macro F1-score:    {f1m:.4f}")
    print(f"Weighted F1-score: {f1w:.4f}")
    print(f"Outputs: {OUT}")
    print("Done.")

if __name__ == "__main__":
    try:
        main()
    except KeyboardInterrupt:
        print("Interrupted by user.")
        sys.exit(130)
    except Exception as exc:
        print(f"ERROR: {type(exc).__name__}: {exc}")
        traceback.print_exc()
        sys.exit(1)
