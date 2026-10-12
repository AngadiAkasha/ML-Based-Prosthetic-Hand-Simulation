%% ============================================================
%  PHASE 1 - PROSTHETIC HAND CONTROLLER SETUP
%  Research paper:
%  "Precise Control Method on Prosthetic Hand Using sEMG Signals"
% =============================================================

clear;
clc;

%% ------------------------------------------------------------
% 1. Load Random Forest prediction results
% ------------------------------------------------------------

predictionFile = 'PredictionResults_RF.mat';

load(predictionFile);

disp('Prediction file loaded successfully.');

%% ------------------------------------------------------------
% 2. Check available variables
% ------------------------------------------------------------

disp('Variables available in workspace:');
whos;

%% ------------------------------------------------------------
% 3. Extract predicted labels
% ------------------------------------------------------------

if ~exist('predictedLabel','var')
    error('Variable "predictedLabel" was not found.');
end

predictedLabel = double(predictedLabel(:));

%% ------------------------------------------------------------
% 4. Extract test labels if available
% ------------------------------------------------------------

if exist('testLabel','var')
    testLabel = double(testLabel(:));
end

%% ------------------------------------------------------------
% 5. Display prediction information
% ------------------------------------------------------------

fprintf('\nNumber of predicted samples: %d\n', ...
    length(predictedLabel));

uniqueLabels = unique(predictedLabel);

fprintf('Number of unique predicted labels: %d\n', ...
    length(uniqueLabels));

disp('Unique predicted labels:');
disp(uniqueLabels.');

%% ------------------------------------------------------------
% 6. Display prediction accuracy if available
% ------------------------------------------------------------

if exist('accuracy','var')

    fprintf('Random Forest accuracy stored in file: %.4f %%\n', ...
        double(accuracy));

end

%% ------------------------------------------------------------
% 7. Sampling time
% ------------------------------------------------------------
%
% IMPORTANT:
% The control paper does not specify the sampling time of your
% Random Forest prediction sequence.
%
% Set this value according to your PR system later.

Ts = 0.01;       % Example only: 10 ms

%% ------------------------------------------------------------
% 8. Create simulation time vector
% ------------------------------------------------------------

N = length(predictedLabel);

time = (0:N-1)' * Ts;

%% ------------------------------------------------------------
% 9. Prepare prediction signal for Simulink
% ------------------------------------------------------------

predictionSignal = timeseries(predictedLabel, time);

%% ------------------------------------------------------------
% 10. Display first few predictions
% ------------------------------------------------------------

disp('First 20 predicted labels:');

disp(predictedLabel(1:min(20,N)));

%% ------------------------------------------------------------
% 11. Workspace information
% ------------------------------------------------------------

disp(' ');
disp('PHASE 1 SETUP COMPLETE.');
disp('Variables prepared for Simulink:');

disp('predictedLabel');
disp('predictionSignal');
disp('time');
disp('Ts');