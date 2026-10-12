function trainRandomForest()
% TRAINRANDOMFOREST
% Train Random Forest classifier for NinaPro DB1.
%
% Input:
%   ../Common/NormalizedTrain.mat
%
% Variables required:
%   trainFeatNorm
%   trainLabel
%
% Output:
%   RF_Model.mat
%
% IMPORTANT:
%   The number of classes is NOT manually specified here.
%   Random Forest learns the classes from trainLabel.
%
%   For the new experiment, trainLabel should contain
%   all selected DB1 movement classes.

clc;
clear;
close all;

fprintf('\n');
fprintf('============================================\n');
fprintf(' RANDOM FOREST TRAINING - NINAPRO DB1\n');
fprintf('============================================\n');

%% ============================================================
% 1. CHECK INPUT FILE
% =============================================================

inputFile = '../Common/NormalizedTrain.mat';

if ~isfile(inputFile)

    error(['NormalizedTrain.mat not found.\n' ...
           'Expected location:\n%s\n\n' ...
           'Run trainTestSplit.m and normalizeData.m first.'], ...
           inputFile);

end

%% ============================================================
% 2. LOAD TRAINING DATA
% =============================================================

load(inputFile);

fprintf('\nLoaded:\n%s\n',inputFile);

%% ============================================================
% 3. CHECK REQUIRED VARIABLES
% =============================================================

if ~exist('trainFeatNorm','var')

    error('Variable "trainFeatNorm" was not found.');

end

if ~exist('trainLabel','var')

    error('Variable "trainLabel" was not found.');

end

%% ============================================================
% 4. CONVERT DATA TO CORRECT FORMAT
% =============================================================

trainFeatNorm = double(trainFeatNorm);

trainLabel = trainLabel(:);

%% ============================================================
% 5. DISPLAY DATA INFORMATION
% =============================================================

classes = unique(trainLabel);

numClasses = numel(classes);

numSamples = size(trainFeatNorm,1);

numFeatures = size(trainFeatNorm,2);

fprintf('\n============================================\n');
fprintf(' TRAINING DATA INFORMATION\n');
fprintf('============================================\n');

fprintf('Training samples : %d\n',numSamples);

fprintf('Features/sample  : %d\n',numFeatures);

fprintf('Number of classes: %d\n',numClasses);

fprintf('\nClass labels:\n');

disp(classes');

%% ============================================================
% 6. CHECK SAMPLE COUNTS
% =============================================================

if size(trainFeatNorm,1) ~= numel(trainLabel)

    error(['Number of feature samples and labels do not match.\n' ...
           'Features = %d\n' ...
           'Labels   = %d'], ...
           size(trainFeatNorm,1), ...
           numel(trainLabel));

end

%% ============================================================
% 7. CHECK NaN / INF
% =============================================================

if any(~isfinite(trainFeatNorm(:)))

    error('Training feature matrix contains NaN or Inf values.');

end

%% ============================================================
% 8. CHECK CLASS SAMPLE COUNTS
% =============================================================

fprintf('\n============================================\n');
fprintf(' CLASS SAMPLE COUNTS\n');
fprintf('============================================\n');

for i = 1:numClasses

    n = sum(trainLabel == classes(i));

    fprintf('Class %g : %d samples\n', ...
        classes(i),n);

end

%% ============================================================
% 9. RANDOM FOREST PARAMETERS
% ============================================================

numTrees = 100;

fprintf('\n============================================\n');
fprintf(' RANDOM FOREST PARAMETERS\n');
fprintf('============================================\n');

fprintf('Number of trees : %d\n',numTrees);

fprintf('Method          : Classification\n');

fprintf('OOB prediction  : Enabled\n');

fprintf('OOB importance  : Enabled\n');

%% ============================================================
% 10. SET RANDOM SEED
% =============================================================

rng(42,'twister');

%% ============================================================
% 11. TRAIN RANDOM FOREST
% =============================================================

fprintf('\nTraining Random Forest...\n');

tic;

RFModel = TreeBagger( ...
    numTrees, ...
    trainFeatNorm, ...
    trainLabel, ...
    'Method','classification', ...
    'OOBPrediction','On', ...
    'OOBPredictorImportance','On');

trainingTime = toc;

fprintf('\nTraining completed.\n');

fprintf('Training time: %.3f seconds\n', ...
    trainingTime);

%% ============================================================
% 12. VERIFY MODEL CLASSES
% =============================================================

modelClasses = RFModel.ClassNames;

fprintf('\n============================================\n');
fprintf(' MODEL INFORMATION\n');
fprintf('============================================\n');

fprintf('Classes learned by RF: %d\n', ...
    numel(modelClasses));

fprintf('\nModel classes:\n');

disp(modelClasses);

%% ============================================================
% 13. CHECK CLASS COUNT
% =============================================================

if numel(modelClasses) ~= numClasses

    error(['Random Forest class count mismatch.\n' ...
           'Training classes = %d\n' ...
           'Model classes    = %d'], ...
           numClasses, ...
           numel(modelClasses));

end

%% ============================================================
% 14. OUT-OF-BAG ERROR
% =============================================================

oobErrorValues = oobError(RFModel);

finalOOBError = oobErrorValues(end);

fprintf('\nFinal OOB error: %.6f\n', ...
    finalOOBError);

fprintf('Final OOB accuracy: %.2f %%\n', ...
    (1-finalOOBError)*100);

%% ============================================================
% 15. PLOT OOB ERROR
% =============================================================

figure( ...
    'Name','Random Forest OOB Error', ...
    'Color','w');

plot( ...
    oobErrorValues, ...
    'LineWidth',2);

grid on;

xlabel('Number of Trees');

ylabel('Out-of-Bag Classification Error');

title(sprintf( ...
    'Random Forest OOB Error - DB1 (%d Classes)', ...
    numClasses));

%% ============================================================
% 16. VARIABLE IMPORTANCE
% =============================================================

if isprop(RFModel,'OOBPermutedPredictorDeltaError')

    importance = ...
        RFModel.OOBPermutedPredictorDeltaError;

    figure( ...
        'Name','Random Forest Feature Importance', ...
        'Color','w');

    bar(importance);

    grid on;

    xlabel('Feature Index');

    ylabel('OOB Permuted Predictor Importance');

    title(sprintf( ...
        'Random Forest Feature Importance - %d Features', ...
        numFeatures));

end

%% ============================================================
% 17. SAVE MODEL
% =============================================================

save( ...
    'RF_Model.mat', ...
    'RFModel', ...
    'numTrees', ...
    'classes', ...
    'numClasses', ...
    'numFeatures', ...
    'trainingTime', ...
    'oobErrorValues', ...
    '-v7.3');

fprintf('\n============================================\n');
fprintf(' MODEL SAVED\n');
fprintf('============================================\n');

fprintf('File: RF_Model.mat\n');

fprintf('Classes: %d\n',numClasses);

fprintf('Trees: %d\n',numTrees);

fprintf('\nRandom Forest training complete.\n');

end