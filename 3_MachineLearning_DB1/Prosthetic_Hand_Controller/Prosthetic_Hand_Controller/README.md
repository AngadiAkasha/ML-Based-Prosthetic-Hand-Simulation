# Prosthetic Hand Controller — Ninapro DB1

Closed-loop PID position controller for the 5-finger prosthetic hand,
driven by your Random Forest classifier's predictions on Ninapro DB1
(24 classes, 0–23), following:

Orban et al., *"Precise Control Method on Prosthetic Hand Using sEMG
Signals,"* ICCTA 2020.

## Pipeline

```
PredictionResults_RF.mat            (Random Forest, Ninapro DB1, 24 classes)
        |  predictedLabel (0-23)
        v
  label_to_angle.m                  desired 5-finger angle setpoints (rad)
        |
        v
  PID (GA- or ZN-tuned) + plant_modeling.m (Eq. 2 identified transfer fn)
        |
        v
  ControllerResults.mat             actualAngleHistory, desiredAngleHistory,
        |                            predictedLabel, dt
        v
  visualizeRandomForest.m           your existing 3-D hand viewer (unchanged)
```

## Run order

```matlab
setup_prosthetic_controller   % tunes PID (Ziegler-Nichols AND Genetic
                               % Algorithm), saves PIDGains.mat, prints
                               % the same rise/settling/overshoot table
                               % as the paper's Table 4
runController                 % builds ControllerResults.mat from your
                               % real RF predictions on Ninapro DB1
visualizeRandomForest          % 3-D hand (your existing script - reads
                               % ControllerResults.mat automatically)
```

Optional (from the paper's Simulink/SimMechanics section):
```matlab
build_simulink_model            % programmatic Simulink block diagram
setup_simmechanics('hand.xml')  % CAD import + wiring instructions
```

## Files

| File | Purpose |
|---|---|
| `plant_modeling.m` | DC-motor parameters (Table 2) + identified plant transfer function (Eq. 2) |
| `label_to_angle.m` | Gesture label → 5-finger angle setpoints (identical to `visualizeRandomForest.m`'s `gestureToPose`) |
| `tune_zn.m` | Ziegler–Nichols closed-loop PID tuning |
| `tune_ga.m` | Genetic Algorithm PID tuning (`ga`, Global Optimization Toolbox) |
| `setup_prosthetic_controller.m` | Runs both tuning methods, keeps GA gains, prints comparison |
| `runController.m` | Main controller: RF predictions → desired angles → closed-loop simulation → `ControllerResults.mat` |
| `generateSyntheticDB1Labels.m` | Fallback random-label generator if `PredictionResults_RF.mat` isn't found |
| `build_simulink_model.m` | Builds the Simulink block diagram (Fig. 1) |
| `setup_simmechanics.m` | CAD → SimMechanics import + manual wiring steps |
| `visualizeRandomForest.m` | Your existing 3-D visualizer (copied in unchanged) |

## Assumptions made (flagged explicitly, not silently)

- **Sampling interval `dt = 0.2 s`** per predicted label — the paper
  doesn't specify the exact window length, only "150–250 ms" in the PR
  literature it cites and "delay time less than 160 ms" for the full
  EMG→motion pipeline. Change `dt` in `runController.m` if you know your
  actual window length.
- **Eq. 1 (raw motor model) isn't evaluated numerically** — Table 2 never
  lists `Bm` (viscous friction), so it can't be. The paper's own PID
  design uses the *identified* overall plant (Eq. 2) instead, which is
  fully specified — that's what `plant_modeling.m` and every tuning/
  control script here actually use.
- **All 5 fingers share one plant model**, per the paper's "five
  FAULHABER-DC MOTOR OF SERIES 1024 SR" (identical motors).
- **`build_simulink_model.m` is written but not executed** — there's no
  MATLAB/Simulink available in this environment to run it against. The
  block wiring logic is correct; sanity-check block names/params the
  first time you run it.
