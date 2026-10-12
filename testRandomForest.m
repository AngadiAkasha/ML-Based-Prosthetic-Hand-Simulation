function testRandomForest()
% TESTRANDOMFOREST
% Test the trained Random Forest model on DB1 test data.
%
% Input:
%   RF_Model.mat
%   ../Common/NormalizedTest.mat
%
% Output:
%   PredictionResults_RF.mat

clc;
clear;
close all;

fprintf('\n');
fprintf('============================================\n');
fprintf(' RANDOM FOREST TESTING - NINAPRO DB1\n');
fprintf('============================================\n');

%% ============================================================
% 1. CHECK MODEL FILE
% =============================================================

modelFile = 'RF_Model.mat';

if ~isfile(modelFile)

    error(['RF_Model.mat not found.\n' ...
           'Run trainRandomForest.m first.']);

end

%% ============================================================
% 2. CHECK TEST DATA
% =============================================================

testFile = '../Common/NormalizedTest.mat';

if ~isfile(testFile)

    error(['NormalizedTest.mat not found.\n' ...
           'Expected location:\n%s'], ...
           testFile);

end

%% ============================================================
% 3. LOAD MODEL
% =============================================================

load(modelFile,'RFModel');

fprintf('\nRandom Forest model loaded.\n');

%% ============================================================
% 4. LOAD TEST DATA
% =============================================================

load(testFile);

fprintf('Test data loaded.\n');

%% ============================================================
% 5. CHECK VARIABLES
% =============================================================

if ~exist('testFeatNorm','var')

    error('Variable "testFeatNorm" was not found.');

end

if ~exist('testLabel','var')

    error('Variable "testLabel" was not found.');

end

%% ============================================================
% 6. CONVERT FORMAT
% =============================================================

testFeatNorm = double(testFeatNorm);

testLabel = testLabel(:);

%% ============================================================
% 7. DATA INFORMATION
% =============================================================

testClasses = unique(testLabel);

numTestClasses = numel(testClasses);

numTestSamples = size(testFeatNorm,1);

numFeatures = size(testFeatNorm,2);

fprintf('\n============================================\n');
fprintf(' TEST DATA INFORMATION\n');
fprintf('============================================\n');

fprintf('Test samples  : %d\n',numTestSamples);

fprintf('Features      : %d\n',numFeatures);

fprintf('Test classes  : %d\n',numTestClasses);

fprintf('\nTest labels:\n');

disp(testClasses');

%% ============================================================
% 8. CHECK DATA DIMENSIONS
% =============================================================

if size(testFeatNorm,1) ~= numel(testLabel)

    error(['Number of test features and labels do not match.\n' ...
           'Features = %d\n' ...
           'Labels   = %d'], ...
           size(testFeatNorm,1), ...
           numel(testLabel));

end

%% ============================================================
% 9. CHECK NaN / INF
% =============================================================

if any(~isfinite(testFeatNorm(:)))

    error('Test feature matrix contains NaN or Inf values.');

end

%% ============================================================
% 10. PREDICTION
% =============================================================

fprintf('\n============================================\n');
fprintf(' PREDICTION\n');
fprintf('============================================\n');

fprintf('Predicting test samples...\n');

tic;

[predictedLabel,predictionScores] = ...
    predict(RFModel,testFeatNorm);

predictionTime = toc;

%% ============================================================
% 11. CONVERT PREDICTIONS TO NUMERIC
% ============================================================

if iscell(predictedLabel)

    predictedLabel = str2double(predictedLabel);

elseif isstring(predictedLabel)

    predictedLabel = str2double(predictedLabel);

elseif iscategorical(predictedLabel)

    predictedLabel = str2double(string(predictedLabel));

else

    predictedLabel = double(predictedLabel);

end

predictedLabel = predictedLabel(:);

%% ============================================================
% 12. CALCULATE ACCURACY
% ============================================================

correct = ...
    predictedLabel == testLabel;

accuracy = ...
    mean(correct);

%% ============================================================
% 13. PREDICTED CLASS INFORMATION
% ============================================================

predictedClasses = unique(predictedLabel);

fprintf('\n============================================\n');
fprintf(' PREDICTION RESULTS\n');
fprintf('============================================\n');

fprintf('Test samples       : %d\n',numTestSamples);

fprintf('Correct predictions: %d\n',sum(correct));

fprintf('Wrong predictions  : %d\n',sum(~correct));

fprintf('Accuracy           : %.4f %%\n', ...
    accuracy*100);

fprintf('Prediction time    : %.4f seconds\n', ...
    predictionTime);

fprintf('Average/sample     : %.6f ms\n', ...
    predictionTime/numTestSamples*1000);

fprintf('\nNumber of predicted classes: %d\n', ...
    numel(predictedClasses));

fprintf('\nPredicted classes:\n');

disp(predictedClasses');

%% ============================================================
% 14. CHECK EXPECTED CLASS RANGE
% =============================================================

fprintf('\nExpected test classes:\n');

disp(testClasses');

%% ============================================================
% 15. CONFUSION MATRIX
% ============================================================

classOrder = unique([testLabel; predictedLabel]);

C = confusionmat( ...
    testLabel, ...
    predictedLabel, ...
    'Order',classOrder);

figure( ...
    'Name','Random Forest Confusion Matrix', ...
    'Color','w');

confusionchart( ...
    C, ...
    string(classOrder));

title(sprintf( ...
    'Random Forest - DB1 (%d Classes)', ...
    numel(classOrder)));

%% ============================================================
% 16. SAVE PREDICTION RESULTS
% ============================================================

save( ...
    'PredictionResults_RF.mat', ...
    'predictedLabel', ...
    'predictionScores', ...
    'testLabel', ...
    'accuracy', ...
    'predictionTime', ...
    'testClasses', ...
    'predictedClasses', ...
    '-v7.3');

fprintf('\n============================================\n');
fprintf(' PREDICTION RESULTS SAVED\n');
fprintf('============================================\n');

fprintf('File: PredictionResults_RF.mat\n');

fprintf('\nRandom Forest testing complete.\n');

end