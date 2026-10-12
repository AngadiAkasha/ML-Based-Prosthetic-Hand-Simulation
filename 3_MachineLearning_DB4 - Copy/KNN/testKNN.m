clc;
clear;
close all;

fprintf('\n=====================================\n');
fprintf('TESTING KNN\n');
fprintf('=====================================\n');

%% Load Model

load('KNN_Model.mat');

%% Load Test Data

load('../Common/NormalizedTest.mat');

%% Prediction

predictedLabel = predict(KNNModel,testFeatNorm);

%% Accuracy

accuracy = sum(predictedLabel==testLabel)/length(testLabel)*100;

fprintf('\nAccuracy : %.2f %%\n',accuracy);

%% Save Results

save('PredictionResults_KNN.mat',...
    'predictedLabel',...
    'testLabel',...
    'accuracy');

fprintf('\nPredictionResults_KNN.mat Saved\n');