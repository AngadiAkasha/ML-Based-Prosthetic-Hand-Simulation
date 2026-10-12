clc;
clear;
close all;

fprintf('\n=====================================\n');
fprintf('TESTING DECISION TREE\n');
fprintf('=====================================\n');

%% Load Model

load('DecisionTree_Model.mat');

%% Load Test Data

load('../Common/NormalizedTest.mat');

%% Prediction

tic

predictedLabel = predict(DecisionTreeModel,testFeatNorm);

predictionTime = toc;

%% Convert datatype

predictedLabel = cast(predictedLabel,class(testLabel));

%% Accuracy

accuracy = mean(predictedLabel==testLabel)*100;

fprintf('\nCorrect Predictions : %d\n',sum(predictedLabel==testLabel));

fprintf('Wrong Predictions   : %d\n',sum(predictedLabel~=testLabel));

fprintf('Accuracy            : %.2f %%\n',accuracy);

fprintf('Prediction Time     : %.4f seconds\n',predictionTime);

%% Save

save('PredictionResults.mat',...
    'predictedLabel',...
    'testLabel',...
    'accuracy',...
    'predictionTime');

fprintf('\nPredictionResults.mat Saved\n');