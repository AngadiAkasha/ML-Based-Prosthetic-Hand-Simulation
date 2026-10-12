clc;
clear;
close all;

fprintf('\n');
fprintf('=====================================================\n');
fprintf('        DB4 - MERGING 52-CLASS FEATURES\n');
fprintf('=====================================================\n');

%% =====================================================
% FIND CURRENT FILE LOCATION
% ======================================================

thisFile = mfilename('fullpath');
commonFolder = fileparts(thisFile);

fprintf('\nMergeFeatures location:\n%s\n', commonFolder);

%% =====================================================
% FIND DB4 MACHINE LEARNING FOLDER
%
% Current:
%
% 3_MachineLearning_DB4
%       |
%       +-- Common
%             |
%             +-- mergeFeatures.m
%
% ======================================================

machineLearningFolder = fileparts(commonFolder);

%% =====================================================
% PROJECT ROOT
% ======================================================

projectRoot = fileparts(machineLearningFolder);

%% =====================================================
% DEFINE PATHS
% ======================================================

featureFolder = fullfile( ...
    machineLearningFolder, ...
    'ExtractedFeatures');

outputFile = fullfile( ...
    machineLearningFolder, ...
    'AllFeatures.mat');

%% =====================================================
% DISPLAY PATHS
% ======================================================

fprintf('\n');
fprintf('=====================================================\n');
fprintf('                    PATH CHECK\n');
fprintf('=====================================================\n');

fprintf('\nProject Root:\n%s\n', ...
    projectRoot);

fprintf('\nMachine Learning Folder:\n%s\n', ...
    machineLearningFolder);

fprintf('\nFeature Folder:\n%s\n', ...
    featureFolder);

fprintf('\nOutput File:\n%s\n', ...
    outputFile);

%% =====================================================
% CHECK FEATURE FOLDER
% ======================================================

if ~exist(featureFolder,'dir')

    error([ ...
        '\nExtractedFeatures folder not found:\n%s\n\n' ...
        'Run the DB4 feature extraction main.m first.\n'], ...
        featureFolder);

end

%% =====================================================
% FIND ALL RMS FILES
% ======================================================

files = dir( ...
    fullfile(featureFolder,'*_RMS.mat'));

fprintf('\n');
fprintf('Feature files found : %d\n', ...
    length(files));

if isempty(files)

    fprintf('\nContents of ExtractedFeatures folder:\n');

    dir(featureFolder)

    error([ ...
        '\nNo *_RMS.mat files were found.\n\n' ...
        'Please run main.m first.\n']);

end

%% =====================================================
% INITIALIZE MERGED DATA
% ======================================================

allFeat = [];

allStim = [];

allRep = [];

%% =====================================================
% FILE COUNTER
% ======================================================

validFiles = 0;

skippedFiles = 0;

%% =====================================================
% MERGE ALL FEATURE FILES
% ======================================================

for i = 1:length(files)

    fprintf('\n');
    fprintf('---------------------------------------------\n');

    fprintf( ...
        'Processing file %d / %d\n', ...
        i, ...
        length(files));

    fprintf( ...
        '%s\n', ...
        files(i).name);

    fprintf('---------------------------------------------\n');

    %% ================================================
    % FILE PATH
    % =================================================

    filePath = fullfile( ...
        featureFolder, ...
        files(i).name);

    %% ================================================
    % LOAD FILE
    % =================================================

    data = load(filePath);

    %% ================================================
    % CHECK VARIABLES
    % =================================================

    requiredVariables = ...
        {'feat','featStim','featRep'};

    missingVariable = false;

    for v = 1:length(requiredVariables)

        if ~isfield( ...
                data, ...
                requiredVariables{v})

            fprintf( ...
                'Missing variable: %s\n', ...
                requiredVariables{v});

            missingVariable = true;

        end

    end

    if missingVariable

        fprintf('Skipping file.\n');

        skippedFiles = skippedFiles + 1;

        continue;

    end

    %% ================================================
    % READ DATA
    % =================================================

    feat = data.feat;

    featStim = data.featStim;

    featRep = data.featRep;

    %% ================================================
    % BASIC SIZE CHECK
    % =================================================

    numberSamples = size(feat,1);

    if length(featStim) ~= numberSamples

        warning( ...
            'Feature/Stimulus size mismatch. Skipping file.');

        skippedFiles = skippedFiles + 1;

        continue;

    end

    if length(featRep) ~= numberSamples

        warning( ...
            'Feature/Repetition size mismatch. Skipping file.');

        skippedFiles = skippedFiles + 1;

        continue;

    end

    %% ================================================
    % CHECK LABEL RANGE
    % =================================================

    invalidLabels = ...
        featStim < 1 | featStim > 52;

    if any(invalidLabels)

        warning( ...
            'Invalid labels found in %s.', ...
            files(i).name);

        fprintf( ...
            'Invalid labels:\n');

        disp(unique(featStim(invalidLabels))');

        skippedFiles = skippedFiles + 1;

        continue;

    end

    %% ================================================
    % APPEND FEATURES
    % =================================================

    allFeat = [ ...
        allFeat; ...
        feat];

    %% ================================================
    % APPEND LABELS
    % =================================================

    allStim = [ ...
        allStim; ...
        featStim];

    %% ================================================
    % APPEND REPETITIONS
    % =================================================

    allRep = [ ...
        allRep; ...
        featRep];

    validFiles = validFiles + 1;

    %% ================================================
    % FILE INFORMATION
    % =================================================

    fprintf('\nSamples in file : %d\n', ...
        numberSamples);

    fprintf('Features        : %d\n', ...
        size(feat,2));

    fprintf('Classes in file : %d\n', ...
        length(unique(featStim)));

end

%% =====================================================
% CHECK MERGED DATA
% ======================================================

fprintf('\n');
fprintf('=====================================================\n');
fprintf('             MERGING SUMMARY\n');
fprintf('=====================================================\n');

fprintf('\nTotal files found   : %d\n', ...
    length(files));

fprintf('Valid files merged  : %d\n', ...
    validFiles);

fprintf('Skipped files       : %d\n', ...
    skippedFiles);

fprintf('Total samples       : %d\n', ...
    size(allFeat,1));

fprintf('Total features      : %d\n', ...
    size(allFeat,2));

fprintf('Total labels        : %d\n', ...
    length(allStim));

fprintf('Total repetitions   : %d\n', ...
    length(allRep));

%% =====================================================
% EMPTY DATA CHECK
% ======================================================

if isempty(allFeat)

    error( ...
        'No valid feature data was merged.');

end

%% =====================================================
% CHECK ROW CONSISTENCY
% ======================================================

if size(allFeat,1) ~= length(allStim)

    error( ...
        'allFeat and allStim have different numbers of samples.');

end

if size(allFeat,1) ~= length(allRep)

    error( ...
        'allFeat and allRep have different numbers of samples.');

end

%% =====================================================
% CHECK UNIQUE CLASSES
% ======================================================

classes = unique(allStim);

fprintf('\n');
fprintf('=====================================================\n');
fprintf('             52-CLASS VERIFICATION\n');
fprintf('=====================================================\n');

fprintf('\nNumber of unique classes : %d\n', ...
    length(classes));

fprintf('\nClasses found:\n');

disp(classes');

%% =====================================================
% EXPECTED CLASSES
% ======================================================

expectedClasses = (1:52)';

%% =====================================================
% FIND MISSING CLASSES
% ======================================================

missingClasses = setdiff( ...
    expectedClasses, ...
    classes);

%% =====================================================
% FIND EXTRA CLASSES
% ======================================================

extraClasses = setdiff( ...
    classes, ...
    expectedClasses);

%% =====================================================
% REPORT MISSING
% ======================================================

if ~isempty(missingClasses)

    fprintf('\nWARNING: Missing classes:\n');

    disp(missingClasses');

else

    fprintf('\nNo missing classes.\n');

end

%% =====================================================
% REPORT EXTRA
% ======================================================

if ~isempty(extraClasses)

    fprintf('\nWARNING: Unexpected classes:\n');

    disp(extraClasses');

else

    fprintf('No unexpected classes.\n');

end

%% =====================================================
% FINAL 52-CLASS CHECK
% ======================================================

if length(classes) ~= 52 || ...
        ~isempty(missingClasses) || ...
        ~isempty(extraClasses)

    error([ ...
        '\nDB4 does NOT contain exactly classes 1-52.\n' ...
        'Do not continue to train the classifier.\n']);

end

fprintf('\n');
fprintf('=====================================================\n');
fprintf('       SUCCESS: ALL 52 CLASSES ARE PRESENT\n');
fprintf('=====================================================\n');

%% =====================================================
% CLASS DISTRIBUTION
% ======================================================

fprintf('\n');
fprintf('=====================================================\n');
fprintf('             DB4 CLASS DISTRIBUTION\n');
fprintf('=====================================================\n');

classCounts = zeros(52,1);

for c = 1:52

    classCounts(c) = ...
        sum(allStim == c);

    fprintf( ...
        'Class %2d : %d samples\n', ...
        c, ...
        classCounts(c));

end

%% =====================================================
% MIN / MAX CLASS SIZE
% ======================================================

fprintf('\n');
fprintf('Minimum samples/class : %d\n', ...
    min(classCounts));

fprintf('Maximum samples/class : %d\n', ...
    max(classCounts));

fprintf('Average samples/class : %.2f\n', ...
    mean(classCounts));

%% =====================================================
% SAVE CLASS COUNTS
% ======================================================

classDistribution = table( ...
    (1:52)', ...
    classCounts, ...
    'VariableNames', ...
    {'Class','SampleCount'});

%% =====================================================
% SAVE MERGED DATA
% ======================================================

fprintf('\nSaving AllFeatures.mat...\n');

save( ...
    outputFile, ...
    'allFeat', ...
    'allStim', ...
    'allRep', ...
    'classDistribution', ...
    '-v7.3');

fprintf('\nSaved successfully:\n%s\n', ...
    outputFile);

%% =====================================================
% FINAL SUMMARY
% ======================================================

fprintf('\n');
fprintf('=====================================================\n');
fprintf('       DB4 ALL FEATURES CREATED SUCCESSFULLY\n');
fprintf('=====================================================\n');

fprintf('\nDataset summary:\n');

fprintf('Subjects/files merged : %d\n', ...
    validFiles);

fprintf('Samples               : %d\n', ...
    size(allFeat,1));

fprintf('Features per sample   : %d\n', ...
    size(allFeat,2));

fprintf('Classes               : %d\n', ...
    length(classes));

fprintf('Labels                : 1 - 52\n');

fprintf('\nOutput:\n%s\n', ...
    outputFile);

fprintf('\n');
fprintf('=====================================================\n');
fprintf('              NEXT STEP: TRAIN/TEST SPLIT\n');
fprintf('=====================================================\n');