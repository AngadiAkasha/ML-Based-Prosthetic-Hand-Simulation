clc;
clear;
close all;

fprintf('\n');
fprintf('=====================================================\n');
fprintf('       NINAPRO DB4 - 52 MOVEMENT CLASSES\n');
fprintf('=====================================================\n');

%% =====================================================
% PARAMETERS
% ======================================================

deadzone = 0.01;
winsize  = 200;
wininc   = 50;

% Same feature used in DB1
feature = 'getrmsfeat';

cores = 4;

%% =====================================================
% CURRENT FILE LOCATION
% ======================================================

thisFile = mfilename('fullpath');
thisFolder = fileparts(thisFile);

fprintf('\nMain file location:\n');
fprintf('%s\n',thisFolder);

%% =====================================================
% PROJECT ROOT
%
% Current:
%
% ProjectRoot
%    |
%    +-- 2_FeatureExtraction
%          |
%          +-- DB4
%                |
%                +-- main.m
%
% ======================================================

projectRoot = fileparts(fileparts(thisFolder));

%% =====================================================
% PATHS
% ======================================================

datasetFolder = fullfile( ...
    projectRoot, ...
    'Datasets', ...
    'DB4');

getFeaturesFolder = fullfile( ...
    thisFolder, ...
    'getFeatures');

machineLearningFolder = fullfile( ...
    projectRoot, ...
    '3_MachineLearning_DB4');

commonFolder = fullfile( ...
    machineLearningFolder, ...
    'Common');

outputFolder = fullfile( ...
    machineLearningFolder, ...
    'ExtractedFeatures');

%% =====================================================
% DISPLAY PATHS
% ======================================================

fprintf('\n');
fprintf('=====================================================\n');
fprintf('                    PATH CHECK\n');
fprintf('=====================================================\n');

fprintf('\nProject Root:\n%s\n',projectRoot);

fprintf('\nDB4 Dataset:\n%s\n',datasetFolder);

fprintf('\nFeature Extraction:\n%s\n',thisFolder);

fprintf('\ngetFeatures:\n%s\n',getFeaturesFolder);

fprintf('\nMachine Learning:\n%s\n',machineLearningFolder);

fprintf('\nCommon:\n%s\n',commonFolder);

fprintf('\nOutput:\n%s\n',outputFolder);

%% =====================================================
% CHECK PATHS
% ======================================================

if ~exist(datasetFolder,'dir')

    error( ...
        'DB4 dataset folder not found:\n%s', ...
        datasetFolder);

end

if ~exist(getFeaturesFolder,'dir')

    error( ...
        'getFeatures folder not found:\n%s', ...
        getFeaturesFolder);

end

if ~exist(machineLearningFolder,'dir')

    error( ...
        '3_MachineLearning_DB4 folder not found:\n%s', ...
        machineLearningFolder);

end

if ~exist(commonFolder,'dir')

    error( ...
        'Common folder not found:\n%s', ...
        commonFolder);

end

%% =====================================================
% ADD MATLAB PATHS
% ======================================================

addpath(thisFolder);

addpath(commonFolder);

addpath(genpath(getFeaturesFolder));

%% =====================================================
% CHECK PARFEATUREEXTRACTOR
% ======================================================

if exist('ParFeatureExtractor','file') ~= 2

    error([ ...
        '\nParFeatureExtractor.m was not found.\n\n' ...
        'Expected it to be available from:\n%s\n'], ...
        thisFolder);

end

fprintf('\nParFeatureExtractor found successfully.\n');

%% =====================================================
% CREATE OUTPUT FOLDER
% ======================================================

if ~exist(outputFolder,'dir')

    mkdir(outputFolder);

end

%% =====================================================
% DELETE OLD RMS FILES
% ======================================================

oldFiles = dir( ...
    fullfile(outputFolder,'*_RMS.mat'));

if ~isempty(oldFiles)

    fprintf('\n');
    fprintf('Old RMS files found : %d\n', ...
        length(oldFiles));

    fprintf('Deleting old DB4 feature files...\n');

    for k = 1:length(oldFiles)

        delete( ...
            fullfile( ...
            outputFolder, ...
            oldFiles(k).name));

    end

    fprintf('Old files deleted.\n');

end

%% =====================================================
% FIND ALL DB4 MAT FILES RECURSIVELY
%
% This is the important correction.
%
% It searches:
%
% Datasets/DB4/
% Datasets/DB4/s1/
% Datasets/DB4/s1/s1/
% Datasets/DB4/s2/
% etc.
%
% ======================================================

fprintf('\n');
fprintf('Searching DB4 dataset recursively...\n');

matFiles = dir( ...
    fullfile(datasetFolder,'**','*.mat'));

fprintf('\nTotal MAT files found : %d\n', ...
    length(matFiles));

if isempty(matFiles)

    error([ ...
        '\nNo .mat files found inside:\n%s\n\n' ...
        'Please check the DB4 dataset extraction.\n'], ...
        datasetFolder);

end

%% =====================================================
% DISPLAY FIRST FEW FILES
% ======================================================

fprintf('\nFirst DB4 files detected:\n');

numberToDisplay = min(10,length(matFiles));

for k = 1:numberToDisplay

    fprintf('%s\n', ...
        fullfile( ...
        matFiles(k).folder, ...
        matFiles(k).name));

end

%% =====================================================
% START PARALLEL POOL
% ======================================================

pool = gcp('nocreate');

if isempty(pool)

    fprintf('\nStarting parallel pool with %d workers...\n', ...
        cores);

    parpool(cores);

else

    fprintf('\nExisting parallel pool detected.\n');

    fprintf('Workers : %d\n', ...
        pool.NumWorkers);

end

%% =====================================================
% GLOBAL LABEL TRACKING
% ======================================================

globalLabels = [];

totalFeatureSamples = 0;

processedFiles = 0;

skippedFiles = 0;

%% =====================================================
% PROCESS EACH MAT FILE
% ======================================================

for f = 1:length(matFiles)

    fprintf('\n');
    fprintf('=====================================================\n');

    fprintf( ...
        'Processing file %d / %d\n', ...
        f, ...
        length(matFiles));

    fprintf( ...
        'File : %s\n', ...
        matFiles(f).name);

    fprintf('=====================================================\n');

    %% =================================================
    % FILE PATH
    % ==================================================

    filePath = fullfile( ...
        matFiles(f).folder, ...
        matFiles(f).name);

    fprintf('\nLoading:\n%s\n',filePath);

    %% =================================================
    % DETERMINE EXERCISE FROM FILE NAME
    % ==================================================

    fileName = upper(matFiles(f).name);

    if contains(fileName,'_E1')

        exercise = 1;

    elseif contains(fileName,'_E2')

        exercise = 2;

    elseif contains(fileName,'_E3')

        exercise = 3;

    else

        fprintf( ...
            '\nExercise E1/E2/E3 not detected. Skipping.\n');

        skippedFiles = skippedFiles + 1;

        continue;

    end

    fprintf('\nExercise detected : E%d\n', ...
        exercise);

    %% =================================================
    % LOAD DATA
    % ==================================================

    try

        data = load(filePath);

    catch ME

        warning( ...
            'Could not load %s\n%s', ...
            filePath, ...
            ME.message);

        skippedFiles = skippedFiles + 1;

        continue;

    end

    %% =================================================
    % CHECK EMG
    % ==================================================

    if ~isfield(data,'emg')

        fprintf('EMG variable missing. Skipping.\n');

        skippedFiles = skippedFiles + 1;

        continue;

    end

    %% =================================================
    % USE RESTIMULUS IF AVAILABLE
    % ==================================================

    if isfield(data,'restimulus')

        Stimulus = data.restimulus;

        fprintf('Using variable : restimulus\n');

    elseif isfield(data,'stimulus')

        Stimulus = data.stimulus;

        fprintf( ...
            'WARNING: restimulus not found.\n');

        fprintf( ...
            'Using variable : stimulus\n');

    else

        fprintf( ...
            'No stimulus/restimulus variable. Skipping.\n');

        skippedFiles = skippedFiles + 1;

        continue;

    end

    %% =================================================
    % USE REREPETITION IF AVAILABLE
    % ==================================================

    if isfield(data,'rerepetition')

        Repetition = data.rerepetition;

        fprintf('Using variable : rerepetition\n');

    elseif isfield(data,'repetition')

        Repetition = data.repetition;

        fprintf( ...
            'WARNING: rerepetition not found.\n');

        fprintf( ...
            'Using variable : repetition\n');

    else

        fprintf( ...
            'No repetition variable. Skipping.\n');

        skippedFiles = skippedFiles + 1;

        continue;

    end

    %% =================================================
    % EMG
    % ==================================================

    EMG = data.emg;

    %% =================================================
    % MAKE COLUMN VECTORS
    % ==================================================

    Stimulus = Stimulus(:);

    Repetition = Repetition(:);

    %% =================================================
    % CHECK SAMPLE LENGTH
    % ==================================================

    if size(EMG,1) ~= length(Stimulus)

        fprintf('\n');
        fprintf('ERROR: EMG/stimulus length mismatch.\n');

        fprintf('EMG samples       : %d\n', ...
            size(EMG,1));

        fprintf('Stimulus samples  : %d\n', ...
            length(Stimulus));

        skippedFiles = skippedFiles + 1;

        continue;

    end

    if size(EMG,1) ~= length(Repetition)

        fprintf('\n');
        fprintf('ERROR: EMG/repetition length mismatch.\n');

        skippedFiles = skippedFiles + 1;

        continue;

    end

    %% =================================================
    % ORIGINAL LABELS
    % ==================================================

    originalLabels = unique(Stimulus);

    fprintf('\nOriginal labels:\n');

    disp(originalLabels');

    %% =================================================
    % GLOBAL 52-CLASS MAPPING
    %
    % E1: 1-12
    % E2: 1-17 -> 13-29
    % E3: 1-23 -> 30-52
    %
    % Rest = 0
    %
    % ==================================================

    switch exercise

        case 1

            globalStimulus = Stimulus;

            expectedMin = 1;
            expectedMax = 12;

        case 2

            globalStimulus = Stimulus;

            movementMask = Stimulus > 0;

            globalStimulus(movementMask) = ...
                Stimulus(movementMask) + 12;

            expectedMin = 13;
            expectedMax = 29;

        case 3

            globalStimulus = Stimulus;

            movementMask = Stimulus > 0;

            globalStimulus(movementMask) = ...
                Stimulus(movementMask) + 29;

            expectedMin = 30;
            expectedMax = 52;

    end

    %% =================================================
    % CHECK GLOBAL LABELS
    % ==================================================

    globalFileLabels = ...
        unique(globalStimulus);

    fprintf('\nGlobal labels for E%d:\n', ...
        exercise);

    disp(globalFileLabels');

    fprintf( ...
        'Expected movement range : %d - %d\n', ...
        expectedMin, ...
        expectedMax);

    %% =================================================
    % FEATURE EXTRACTION
    %
    % IMPORTANT:
    % Do NOT remove rest samples before extraction.
    %
    % This preserves the original time sequence and
    % prevents windows from joining across removed rest.
    %
    % Rest windows are removed AFTER extraction.
    %
    % ==================================================

    fprintf('\nStarting feature extraction...\n');

    try

        [feat,featStim,featRep] = ...
            ParFeatureExtractor( ...
                EMG, ...
                globalStimulus, ...
                Repetition, ...
                deadzone, ...
                winsize, ...
                wininc, ...
                feature, ...
                cores);

    catch ME

        fprintf('\n');
        fprintf('FEATURE EXTRACTION ERROR\n');

        fprintf('%s\n',ME.message);

        skippedFiles = skippedFiles + 1;

        continue;

    end

    %% =================================================
    % CHECK EMPTY
    % ==================================================

    if isempty(feat)

        fprintf( ...
            '\nNo features extracted. Skipping.\n');

        skippedFiles = skippedFiles + 1;

        continue;

    end

    %% =================================================
    % REMOVE REST WINDOWS
    %
    % Global movement classes are 1-52.
    % Rest is 0.
    %
    % ==================================================

    movementWindows = featStim > 0;

    feat = feat(movementWindows,:);

    featStim = featStim(movementWindows);

    featRep = featRep(movementWindows);

    %% =================================================
    % CHECK AFTER REST REMOVAL
    % ==================================================

    if isempty(feat)

        fprintf( ...
            '\nNo movement feature windows found.\n');

        skippedFiles = skippedFiles + 1;

        continue;

    end

    %% =================================================
    % EXTRACTED LABELS
    % ==================================================

    extractedLabels = unique(featStim);

    fprintf('\nExtracted movement labels:\n');

    disp(extractedLabels');

    fprintf( ...
        'Number of extracted classes : %d\n', ...
        length(extractedLabels));

    fprintf( ...
        'Feature samples             : %d\n', ...
        size(feat,1));

    fprintf( ...
        'Features per sample         : %d\n', ...
        size(feat,2));

    %% =================================================
    % TRACK LABELS
    % ==================================================

    globalLabels = [ ...
        globalLabels; ...
        extractedLabels(:)];

    totalFeatureSamples = ...
        totalFeatureSamples + size(feat,1);

    processedFiles = ...
        processedFiles + 1;

    %% =================================================
    % CREATE UNIQUE OUTPUT NAME
    % ==================================================

    [~,baseName,~] = ...
        fileparts(matFiles(f).name);

    saveName = fullfile( ...
        outputFolder, ...
        [baseName '_RMS.mat']);

    %% =================================================
    % SAVE
    % ==================================================

    save( ...
        saveName, ...
        'feat', ...
        'featStim', ...
        'featRep', ...
        '-v7.3');

    %% =================================================
    % VERIFY SAVE
    % ==================================================

    if exist(saveName,'file')

        fileInfo = dir(saveName);

        fprintf('\nSUCCESSFULLY SAVED:\n');

        fprintf('%s\n',saveName);

        fprintf( ...
            'File size : %.2f MB\n', ...
            fileInfo.bytes / (1024^2));

    else

        fprintf( ...
            '\nWARNING: File was not created.\n');

    end

end

%% =====================================================
% FINAL CLASS CHECK
% ======================================================

globalLabels = unique(globalLabels);

fprintf('\n');
fprintf('=====================================================\n');
fprintf('             FINAL DB4 EXTRACTION SUMMARY\n');
fprintf('=====================================================\n');

fprintf('\nFiles detected       : %d\n', ...
    length(matFiles));

fprintf('Files processed      : %d\n', ...
    processedFiles);

fprintf('Files skipped        : %d\n', ...
    skippedFiles);

fprintf('Total feature samples: %d\n', ...
    totalFeatureSamples);

fprintf('Unique classes       : %d\n', ...
    length(globalLabels));

fprintf('\nGlobal labels:\n');

disp(globalLabels');

%% =====================================================
% EXPECTED CLASSES
% ======================================================

expectedLabels = (1:52)';

missingLabels = setdiff( ...
    expectedLabels, ...
    globalLabels);

extraLabels = setdiff( ...
    globalLabels, ...
    expectedLabels);

%% =====================================================
% MISSING
% ======================================================

if ~isempty(missingLabels)

    fprintf('\nWARNING: Missing classes:\n');

    disp(missingLabels');

end

%% =====================================================
% EXTRA
% ======================================================

if ~isempty(extraLabels)

    fprintf('\nWARNING: Unexpected classes:\n');

    disp(extraLabels');

end

%% =====================================================
% SUCCESS
% ======================================================

if length(globalLabels) == 52 && ...
        isempty(missingLabels) && ...
        isempty(extraLabels)

    fprintf('\n');
    fprintf('=====================================================\n');
    fprintf('     SUCCESS: ALL 52 DB4 MOVEMENT CLASSES FOUND\n');
    fprintf('=====================================================\n');

else

    fprintf('\n');
    fprintf('=====================================================\n');
    fprintf('       DB4 52-CLASS CHECK FAILED\n');
    fprintf('=====================================================\n');

end

%% =====================================================
% OUTPUT FILE COUNT
% ======================================================

finalFiles = dir( ...
    fullfile(outputFolder,'*_RMS.mat'));

fprintf('\n');
fprintf('RMS files actually created : %d\n', ...
    length(finalFiles));

%% =====================================================
% CLOSE PARALLEL POOL
% ======================================================

pool = gcp('nocreate');

if ~isempty(pool)

    delete(pool);

end

fprintf('\n');
fprintf('=====================================================\n');
fprintf('      DB4 52-CLASS FEATURE EXTRACTION COMPLETE\n');
fprintf('=====================================================\n');

fprintf('\nFeature output folder:\n');

fprintf('%s\n',outputFolder);