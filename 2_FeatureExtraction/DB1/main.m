clc;
clear;
close all;

%% ==========================================================
%        NINAPRO DB1 - 52 MOVEMENT CLASS EXTRACTION
%
% DB1:
%   Exercise 1 -> 12 movements
%   Exercise 2 -> 17 movements
%   Exercise 3 -> 23 movements
%
% Total:
%   12 + 17 + 23 = 52 movement classes
%
% IMPORTANT:
% Original DB1 labels restart from 1 in every exercise.
% Therefore, this program converts them into GLOBAL labels:
%
%   E1:  1 - 12
%   E2: 13 - 29
%   E3: 30 - 52
%
% Rest label 0 is removed.
% ==========================================================

fprintf('\n');
fprintf('=====================================================\n');
fprintf('       NINAPRO DB1 - 52 MOVEMENT CLASSES\n');
fprintf('=====================================================\n');

%% ==========================================================
% PARAMETERS
% ===========================================================

deadzone = 0.01;

winsize = 200;

wininc = 50;

feature = 'getrmsfeat';

cores = 4;

%% ==========================================================
% PATHS
% ===========================================================

addpath('../Common');
addpath(genpath('../Common/getFeatures'));

datasetFolder = fullfile( ...
    '..','..','Datasets','DB1');

outputFolder = fullfile( ...
    '..','..', ...
    '3_MachineLearning_DB1', ...
    'ExtractedFeatures');

%% ==========================================================
% CHECK DATASET
% ===========================================================

if ~exist(datasetFolder,'dir')

    error(['DB1 dataset folder was not found:\n\n%s'], ...
        datasetFolder);

end

%% ==========================================================
% CREATE OUTPUT FOLDER
% ===========================================================

if ~exist(outputFolder,'dir')

    mkdir(outputFolder);

end

%% ==========================================================
% START PARALLEL POOL
% ===========================================================

pool = gcp('nocreate');

if isempty(pool)

    fprintf('\nStarting parallel pool with %d workers...\n', ...
        cores);

    parpool(cores);

else

    fprintf('\nExisting parallel pool detected.\n');
    fprintf('Workers : %d\n',pool.NumWorkers);

end

%% ==========================================================
% FIND SUBJECTS
% ===========================================================

subjects = dir(fullfile(datasetFolder,'s*'));

subjects = subjects([subjects.isdir]);

fprintf('\n');
fprintf('=====================================================\n');
fprintf('Number of Subjects : %d\n',length(subjects));
fprintf('=====================================================\n');

%% ==========================================================
% GLOBAL LABEL STORAGE
% ===========================================================

globalLabels = [];

%% ==========================================================
% PROCESS EACH SUBJECT
% ===========================================================

for s = 1:length(subjects)

    fprintf('\n');
    fprintf('=====================================================\n');
    fprintf('Processing Subject : %s\n',subjects(s).name);
    fprintf('=====================================================\n');

    subjectFolder = fullfile( ...
        datasetFolder, ...
        subjects(s).name);

    %% ------------------------------------------------------
    % FIND MAT FILES
    % -------------------------------------------------------

    matFiles = dir(fullfile(subjectFolder,'*.mat'));

    fprintf('MAT Files : %d\n',length(matFiles));

    %% ------------------------------------------------------
    % PROCESS FILES
    % -------------------------------------------------------

    for f = 1:length(matFiles)

        fprintf('\n');
        fprintf('---------------------------------------------\n');
        fprintf('Loading : %s\n',matFiles(f).name);
        fprintf('---------------------------------------------\n');

        filePath = fullfile( ...
            subjectFolder, ...
            matFiles(f).name);

        %% --------------------------------------------------
        % LOAD FILE
        % ---------------------------------------------------

        data = load(filePath);

        %% --------------------------------------------------
        % CHECK VARIABLES
        % ---------------------------------------------------

        if ~isfield(data,'emg')

            warning('EMG variable missing. Skipping file.');

            continue;

        end

        if ~isfield(data,'stimulus')

            warning('Stimulus variable missing. Skipping file.');

            continue;

        end

        if ~isfield(data,'repetition')

            warning('Repetition variable missing. Skipping file.');

            continue;

        end

        %% --------------------------------------------------
        % ORIGINAL DATA
        % ---------------------------------------------------

        EMG = data.emg;

        Stimulus = data.stimulus;

        Repetition = data.repetition;

        %% --------------------------------------------------
        % DETERMINE EXERCISE
        % ---------------------------------------------------

        fileName = upper(matFiles(f).name);

        if contains(fileName,'_E1')

            exercise = 1;

        elseif contains(fileName,'_E2')

            exercise = 2;

        elseif contains(fileName,'_E3')

            exercise = 3;

        else

            warning( ...
                'Exercise could not be determined from %s. Skipping.', ...
                fileName);

            continue;

        end

        fprintf('\nExercise detected : E%d\n',exercise);

        %% --------------------------------------------------
        % ORIGINAL LABEL SUMMARY
        % ---------------------------------------------------

        originalLabels = unique(Stimulus);

        fprintf('\nOriginal stimulus labels:\n');

        disp(originalLabels');

        %% ==================================================
        % REMOVE REST
        %
        % Label 0 = rest/background.
        %
        % We want exactly 52 MOVEMENT classes.
        % Therefore, remove all samples with stimulus == 0.
        % ==================================================

        validSamples = Stimulus > 0;

        EMG = EMG(validSamples,:);

        Stimulus = Stimulus(validSamples);

        Repetition = Repetition(validSamples);

        %% --------------------------------------------------
        % CONVERT LOCAL LABELS TO GLOBAL 52-CLASS LABELS
        % ---------------------------------------------------

        switch exercise

            case 1

                % E1:
                % 1-12 -> 1-12

                globalStimulus = Stimulus;

                expectedMin = 1;

                expectedMax = 12;

            case 2

                % E2:
                % 1-17 -> 13-29

                globalStimulus = Stimulus + 12;

                expectedMin = 13;

                expectedMax = 29;

            case 3

                % E3:
                % 1-23 -> 30-52

                globalStimulus = Stimulus + 29;

                expectedMin = 30;

                expectedMax = 52;

        end

        %% --------------------------------------------------
        % CHECK GLOBAL LABELS
        % ---------------------------------------------------

        extractedGlobalLabels = unique(globalStimulus);

        fprintf('\nGlobal labels for E%d:\n',exercise);

        disp(extractedGlobalLabels');

        fprintf('Expected range : %d - %d\n', ...
            expectedMin,expectedMax);

        %% --------------------------------------------------
        % EXTRACT FEATURES
        % ---------------------------------------------------

        [feat,featStim,featRep] = ParFeatureExtractor( ...
            EMG, ...
            globalStimulus, ...
            Repetition, ...
            deadzone, ...
            winsize, ...
            wininc, ...
            feature, ...
            cores);

        %% --------------------------------------------------
        % CHECK EXTRACTED LABELS
        % ---------------------------------------------------

        extractedLabels = unique(featStim);

        fprintf('\nExtracted GLOBAL labels:\n');

        disp(extractedLabels');

        fprintf( ...
            'Number of extracted classes in this file : %d\n', ...
            length(extractedLabels));

        %% --------------------------------------------------
        % ADD TO GLOBAL CLASS LIST
        % ---------------------------------------------------

        globalLabels = [ ...
            globalLabels; ...
            extractedLabels(:)];

        %% --------------------------------------------------
        % SAVE FEATURES
        % ---------------------------------------------------

        [~,baseName,~] = ...
            fileparts(matFiles(f).name);

        saveName = fullfile( ...
            outputFolder, ...
            [baseName '_RMS.mat']);

        save( ...
            saveName, ...
            'feat', ...
            'featStim', ...
            'featRep', ...
            '-v7.3');

        fprintf('\nSaved:\n%s\n',saveName);

        fprintf( ...
            'Feature matrix size : %d x %d\n', ...
            size(feat,1), ...
            size(feat,2));

    end

end

%% ==========================================================
% FINAL GLOBAL LABEL SUMMARY
% ===========================================================

globalLabels = unique(globalLabels);

fprintf('\n');
fprintf('=====================================================\n');
fprintf('             FINAL 52-CLASS SUMMARY\n');
fprintf('=====================================================\n');

fprintf('\nTotal unique movement classes : %d\n', ...
    length(globalLabels));

fprintf('\nGlobal labels:\n');

disp(globalLabels');

%% ==========================================================
% VERIFY EXACTLY 52 CLASSES
% ===========================================================

expectedLabels = (1:52)';

missingLabels = setdiff(expectedLabels,globalLabels);

extraLabels = setdiff(globalLabels,expectedLabels);

%% ----------------------------------------------------------
% MISSING LABELS
% -----------------------------------------------------------

if ~isempty(missingLabels)

    fprintf('\nWARNING: Missing labels:\n');

    disp(missingLabels');

end

%% ----------------------------------------------------------
% EXTRA LABELS
% -----------------------------------------------------------

if ~isempty(extraLabels)

    fprintf('\nWARNING: Unexpected labels:\n');

    disp(extraLabels');

end

%% ==========================================================
% FINAL CHECK
% ===========================================================

if length(globalLabels) == 52 && ...
        isempty(missingLabels) && ...
        isempty(extraLabels)

    fprintf('\n');
    fprintf('=====================================================\n');
    fprintf('       SUCCESS: ALL 52 MOVEMENT CLASSES FOUND\n');
    fprintf('=====================================================\n');

else

    fprintf('\n');
    fprintf('=====================================================\n');
    fprintf('       ERROR: 52 CLASSES NOT FOUND\n');
    fprintf('=====================================================\n');

    fprintf('Found classes : %d\n', ...
        length(globalLabels));

    fprintf('Expected      : 52\n');

end

%% ==========================================================
% CLASS DISTRIBUTION
% ===========================================================

fprintf('\n');
fprintf('=====================================================\n');
fprintf('             GLOBAL CLASS DISTRIBUTION\n');
fprintf('=====================================================\n');

for c = 1:52

    count = sum( ...
        arrayfun(@(x) x == c,globalLabels));

    fprintf('Class %2d : present = %d\n', ...
        c,count);

end

%% ==========================================================
% CLOSE PARALLEL POOL
% ===========================================================

pool = gcp('nocreate');

if ~isempty(pool)

    delete(pool);

end

%% ==========================================================
% COMPLETED
% ===========================================================

fprintf('\n');
fprintf('=====================================================\n');
fprintf('       DB1 52-CLASS FEATURE EXTRACTION COMPLETE\n');
fprintf('=====================================================\n');