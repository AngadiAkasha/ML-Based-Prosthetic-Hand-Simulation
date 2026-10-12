clc;
clear;
close all;

fprintf('\n=====================================\n');
fprintf('TESTING ANN MODEL\n');
fprintf('=====================================\n');

load('ANN_Model.mat');
load('../Common/NormalizedTest.mat');

testLabel = testLabel(:);

%% Prediction

tic

outputs = net(testFeatNorm');

predictionTime = toc;

[~,index] = max(outputs,[],1);

predictedLabel = classes(index);

predictedLabel = predictedLabel(:);

predictedLabel = cast(predictedLabel,class(testLabel));

%% Accuracy

accuracy = mean(predictedLabel==testLabel)*100;

fprintf('\nCorrect Predictions : %d\n',sum(predictedLabel==testLabel));

fprintf('Wrong Predictions   : %d\n',sum(predictedLabel~=testLabel));

fprintf('Accuracy            : %.2f %%\n',accuracy);

fprintf('Prediction Time     : %.4f sec\n',predictionTime);

save('PredictionResults.mat',...
    'predictedLabel',...
    'testLabel',...
    'accuracy',...
    'predictionTime');