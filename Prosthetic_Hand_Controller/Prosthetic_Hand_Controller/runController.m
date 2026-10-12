
function runController()
% RUNCONTROLLER
% TabICLv2 predictions -> gesture mapping -> PID tuning -> hand simulation.
%
% Supported tuning methods:
%   ZN     : Ziegler-Nichols
%   GA     : Genetic Algorithm
%   BO     : Bayesian Optimization
%   MS     : Multiple-Shooting Optimization
%   ROUTH  : Routh-Hurwitz stability-screened optimization
%   SAVED  : Load previously saved PID gains
%
% Required:
%   PredictionResults.mat containing predictedLabel
%   label_to_angle.m
%   plant_modeling.m
%   tune_zn.m
%   tune_ga.m
%   tune_bo.m
%   tune_ms_collocation.m
%   tune_routh_pid.m
%
% Outputs:
%   PIDGains.mat
%   ControllerResults.mat

    clc;
    fprintf('=== TabICLv2 Prosthetic Hand Controller ===\n\n');

    %% 1. Select PID tuning method
    % Change this one line to select your method.

    tuningMethod = 'ROUTH';

    % Options: 'ZN', 'GA', 'BO', 'MS', 'ROUTH', 'SAVED'

    %% 2. Locate TabICLv2 prediction file

    controllerDir = fileparts(mfilename('fullpath'));
    mlRoot = fileparts(fileparts(controllerDir));

    candidateFiles = {
        fullfile(mlRoot, 'TabICL', 'PredictionResults.mat')
        fullfile(mlRoot, 'TabICL', 'Results', 'PredictionResults.mat')
        fullfile(mlRoot, 'TabICL', 'PredictionResults_TabICL.mat')
        fullfile(mlRoot, 'TabICL', 'Results', ...
                 'PredictionResults_TabICL.mat')
        fullfile(mlRoot, 'TabICL_Results', 'PredictionResults.mat')
        fullfile(mlRoot, 'TabICL_Results', ...
                 'PredictionResults_TabICL.mat')
    };

    predFile = '';

    for i = 1:numel(candidateFiles)
        if isfile(candidateFiles{i})
            predFile = candidateFiles{i};
            break;
        end
    end

    if isempty(predFile)
        error(['PredictionResults.mat was not found.\n', ...
            'Expected it in one of the configured TabICL folders.\n', ...
            'Project root searched: %s'], mlRoot);
    end

    S = load(predFile);

    if ~isfield(S, 'predictedLabel')
        error('Prediction file must contain the variable predictedLabel.');
    end

    originalPredictedLabel = double(S.predictedLabel(:));

    if isempty(originalPredictedLabel)
        error('The predictedLabel vector is empty.');
    end

    if any(~isfinite(originalPredictedLabel))
        error('Predicted labels contain NaN or Inf.');
    end

    if any(originalPredictedLabel ~= round(originalPredictedLabel)) || ...
       any(originalPredictedLabel < 1 | originalPredictedLabel > 52)
        error('Expected integer DB1 movement labels in the range 1..52.');
    end

    originalPredictedLabel = round(originalPredictedLabel);

    fprintf('Prediction file:\n%s\n', predFile);
    fprintf('Number of predictions: %d\n', ...
        numel(originalPredictedLabel));
    fprintf('Unique predicted classes: %d\n\n', ...
        numel(unique(originalPredictedLabel)));

    %% 3. Set up MATLAB paths

    addpath(controllerDir);

    if isfolder(mlRoot)
        addpath(genpath(mlRoot));
    end

    requiredBaseFunctions = {
        'label_to_angle'
        'plant_modeling'
    };

    for i = 1:numel(requiredBaseFunctions)
        if exist(requiredBaseFunctions{i}, 'file') ~= 2
            error('Required function not found: %s.m', ...
                requiredBaseFunctions{i});
        end
    end

    %% 4. Validate the label-to-angle mapping

    fprintf('Validating gesture mapping for labels 1..52...\n');

    for label = 1:52
        angles = label_to_angle(label);

        if ~isnumeric(angles) || numel(angles) ~= 5
            error(['label_to_angle(%d) must return exactly ', ...
                'five numeric finger-angle setpoints.'], label);
        end

        if any(~isfinite(angles(:)))
            error('Class %d returned invalid angle values.', label);
        end
    end

    fprintf('Gesture mapping validation passed.\n\n');

    % Numeric validation does not prove that each gesture is mapped
    % to the correct physical finger movement.

    %% 5. Build desired finger-angle trajectory

    dtOriginal = 0.2;
    replicateFactor = 4;
    dt = dtOriginal / replicateFactor;

    predictedLabel = repelem( ...
        originalPredictedLabel, replicateFactor);

    N = numel(predictedLabel);
    t = (0:N-1)' * dt;

    desiredAngleHistory = zeros(N, 5);

    for k = 1:N
        angles = label_to_angle(predictedLabel(k));
        desiredAngleHistory(k, :) = reshape(double(angles), 1, 5);
    end

    % Smoothly interpolate between the original gesture setpoints.
    originalIndices = 1:replicateFactor:N;

    for f = 1:5
        desiredAngleHistory(:, f) = interp1( ...
            originalIndices, ...
            desiredAngleHistory(originalIndices, f), ...
            1:N, 'linear', 'extrap')';
    end

    fprintf('Simulation frames: %d\n', N);
    fprintf('Time step: %.3f seconds\n', dt);
    fprintf('Simulated duration: %.2f seconds\n\n', N * dt);

    %% 6. Initialize plant model

    G_plant = plant_modeling();

    %% 7. Locate existing PID gains

    gainCandidates = {
        fullfile(controllerDir, 'PIDGains.mat')
        fullfile(mlRoot, 'PIDGains.mat')
    };

    gainsFile = '';

    for i = 1:numel(gainCandidates)
        if isfile(gainCandidates{i})
            gainsFile = gainCandidates{i};
            break;
        end
    end

    %% 8. Execute selected PID tuning method

    tuningInfo = struct();

    fprintf('Selected PID tuning method: %s\n\n', ...
        upper(tuningMethod));

    switch upper(strtrim(tuningMethod))

        case 'ZN'
            % Ziegler-Nichols tuning

            checkFunction('tune_zn');

            fprintf('Running Ziegler-Nichols tuning...\n');

            [Kp, Ki, Kd] = tune_zn(G_plant);

        case 'GA'
            % Genetic Algorithm tuning

            checkFunction('tune_ga');

            fprintf('Running Genetic Algorithm tuning...\n');

            [Kp, Ki, Kd, tuningInfo] = tune_ga(G_plant);

        case 'BO'
            % Bayesian Optimization tuning

            checkFunction('tune_bo');

            fprintf('Running Bayesian Optimization tuning...\n');

            [Kp, Ki, Kd, tuningInfo] = tune_bo(G_plant);

        case 'MS'
            % Multiple-Shooting Optimization

            checkFunction('tune_ms_collocation');

            fprintf('Running Multiple-Shooting optimization...\n');

            [Kp, Ki, Kd, tuningInfo] = ...
                tune_ms_collocation(G_plant);

        case 'ROUTH'
            % Routh-Hurwitz stability-screened optimization

            checkFunction('tune_routh_pid');

            fprintf('Running Routh-Hurwitz PID optimization...\n');

            [Kp, Ki, Kd, tuningInfo] = ...
                tune_routh_pid(G_plant);

        case 'SAVED'
            % Load gains without running a new optimization.

            if isempty(gainsFile)
                error(['PIDGains.mat was not found. ', ...
                    'Run one of the tuning methods first.']);
            end

            G = load(gainsFile);

            if ~all(isfield(G, {'Kp', 'Ki', 'Kd'}))
                error('PIDGains.mat must contain Kp, Ki, and Kd.');
            end

            Kp = double(G.Kp);
            Ki = double(G.Ki);
            Kd = double(G.Kd);

            fprintf('Loaded gains from:\n%s\n', gainsFile);

        otherwise
            error(['Unknown tuning method "%s". Use ZN, GA, BO, ', ...
                'MS, ROUTH, or SAVED.'], tuningMethod);
    end

    %% 9. Validate selected gains

    if ~isnumeric([Kp, Ki, Kd]) || ...
       ~all(isfinite([Kp, Ki, Kd])) || ...
       ~isscalar(Kp) || ~isscalar(Ki) || ~isscalar(Kd)

        error('The selected tuning method returned invalid PID gains.');
    end

    fprintf('\nSelected gains:\n');
    fprintf('Kp = %.8g\n', Kp);
    fprintf('Ki = %.8g\n', Ki);
    fprintf('Kd = %.8g\n\n', Kd);

    %% 10. Create closed-loop system and check stability

    C = pid(Kp, Ki, Kd);
    Tcl = minreal(feedback(C * G_plant, 1));

    if ~isstable(Tcl)
        error(['The selected PID gains produce an unstable ', ...
            'closed-loop model. Simulation stopped.']);
    end

    performance = stepinfo(Tcl);

    fprintf('Closed-loop unit-step performance:\n');
    fprintf('Rise time       : %.6g seconds\n', ...
        performance.RiseTime);
    fprintf('Settling time   : %.6g seconds\n', ...
        performance.SettlingTime);
    fprintf('Overshoot       : %.4f %%\n\n', ...
        performance.Overshoot);

    %% 11. Save gains for later use

    % Save beside runController.m so that the location is predictable.
    gainsOutputFile = fullfile(controllerDir, 'PIDGains.mat');

    save(gainsOutputFile, ...
        'Kp', 'Ki', 'Kd', 'tuningMethod');

    fprintf('PID gains saved to:\n%s\n\n', gainsOutputFile);

    %% 12. Simulate five finger trajectories

    fingerNames = {'Thumb', 'Index', 'Middle', 'Ring', 'Little'};
    actualAngleHistory = zeros(N, 5);

    fprintf('Simulating PID-controlled finger movements...\n');

    for f = 1:5
        actualAngleHistory(:, f) = lsim( ...
            Tcl, desiredAngleHistory(:, f), t);

        fprintf('  %s finger simulated.\n', fingerNames{f});
    end

    %% 13. Calculate tracking metrics

    trackingError = desiredAngleHistory - actualAngleHistory;

    rmsePerFinger = sqrt(mean(trackingError.^2, 1));
    maePerFinger = mean(abs(trackingError), 1);

    fprintf('\nTracking metrics:\n');

    for f = 1:5
        fprintf('%-7s RMSE = %.4f, MAE = %.4f\n', ...
            fingerNames{f}, rmsePerFinger(f), maePerFinger(f));
    end

    overallRMSE = sqrt(mean(trackingError(:).^2));
    overallMAE = mean(abs(trackingError(:)));

    fprintf('\nOverall RMSE: %.6f\n', overallRMSE);
    fprintf('Overall MAE : %.6f\n', overallMAE);

    %% 14. Save controller results

    outputFile = fullfile(controllerDir, 'ControllerResults.mat');

    save(outputFile, ...
        'actualAngleHistory', ...
        'desiredAngleHistory', ...
        'originalPredictedLabel', ...
        'predictedLabel', ...
        'dt', 't', ...
        'Kp', 'Ki', 'Kd', ...
        'tuningMethod', ...
        'tuningInfo', ...
        'performance', ...
        'trackingError', ...
        'rmsePerFinger', ...
        'maePerFinger', ...
        'overallRMSE', ...
        'overallMAE', ...
        'fingerNames', ...
        'predFile');

    fprintf('\nControllerResults.mat saved to:\n%s\n', outputFile);
    fprintf('Total frames: %d\n', N);
    fprintf('Simulated duration: %.2f seconds\n', N * dt);
    fprintf('\nController simulation completed.\n');
    fprintf('Run your compatible 3-D visualization next.\n');

end


function checkFunction(functionName)
% Confirm the selected tuning function exists.

    if exist(functionName, 'file') ~= 2
        error(['Required tuning file %s.m was not found. ', ...
            'Place it in the controller folder or on the MATLAB path.'], ...
            functionName);
    end

end
