clc;
clear;
close all;

fprintf('\n=====================================\n');
fprintf('       TESTING DECISION TREE - DB4\n');
fprintf('=====================================\n');

%% Load Model

fprintf('\nLoading Decision Tree model...\n');

load('DecisionTree_Model.mat');

%% Load Test Data

fprintf('Loading test data...\n');

load('../Common/NormalizedTest.mat');

%% Check Test Data

fprintf('\nTest samples  : %d\n',size(testFeatNorm,1));
fprintf('Features      : %d\n',size(testFeatNorm,2));

%% Convert labels to categorical

testLabel = categorical(testLabel);

%% Prediction

fprintf('\nStarting prediction...\n');

tic;

predictedLabel = predict(...
    DecisionTreeModel,...
    testFeatNorm);

predictionTime = toc;

%% Make sure predicted labels are categorical

predictedLabel = categorical(predictedLabel);

%% Accuracy

correctPredictions = sum(predictedLabel == testLabel);

totalPredictions = length(testLabel);

wrongPredictions = totalPredictions - correctPredictions;

accuracy = ...
    correctPredictions / totalPredictions * 100;

%% Display Results

fprintf('\n=====================================\n');
fprintf('       DECISION TREE TEST RESULTS\n');
fprintf('=====================================\n');

fprintf('\nTotal Test Samples : %d\n', ...
    totalPredictions);

fprintf('Correct Predictions : %d\n', ...
    correctPredictions);

fprintf('Wrong Predictions   : %d\n', ...
    wrongPredictions);

fprintf('\nAccuracy : %.2f %%\n', ...
    accuracy);

fprintf('Prediction Time : %.4f seconds\n', ...
    predictionTime);

fprintf('Prediction Time : %.4f minutes\n', ...
    predictionTime/60);

%% Save Results

save('PredictionResults.mat',...
    'predictedLabel',...
    'testLabel',...
    'accuracy',...
    'predictionTime',...
    'correctPredictions',...
    'wrongPredictions');

fprintf('\nPredictionResults.mat Saved Successfully\n');

fprintf('\n=====================================\n');
fprintf('       TESTING COMPLETED\n');
fprintf('=====================================\n');