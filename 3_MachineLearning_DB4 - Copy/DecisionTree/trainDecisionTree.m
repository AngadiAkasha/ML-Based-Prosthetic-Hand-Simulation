clc;
clear;
close all;

fprintf('\n========================================\n');
fprintf('       TRAINING DECISION TREE - DB4\n');
fprintf('========================================\n');

%% Load Training Data

fprintf('\nLoading training data...\n');

data = load('../Common/NormalizedTrain.mat');

trainFeatNorm = data.trainFeatNorm;
trainLabel    = data.trainLabel;

%% Check dimensions

fprintf('\nTraining feature size : %d x %d\n', ...
    size(trainFeatNorm,1), size(trainFeatNorm,2));

fprintf('Training label size   : %d x %d\n', ...
    size(trainLabel,1), size(trainLabel,2));

fprintf('Number of classes     : %d\n', ...
    numel(unique(trainLabel)));

%% Convert labels

trainLabel = categorical(trainLabel);

%% Check class distribution

fprintf('\nClass distribution:\n');

classCounts = countcats(trainLabel);
classNames = categories(trainLabel);

for i = 1:numel(classNames)
    fprintf('Class %-4s : %d samples\n', ...
        classNames{i}, classCounts(i));
end

%% Train Decision Tree

fprintf('\n========================================\n');
fprintf('Training Decision Tree...\n');
fprintf('========================================\n');

tic;

DecisionTreeModel = fitctree( ...
    trainFeatNorm, ...
    trainLabel, ...
    'SplitCriterion','gdi', ...
    'MaxNumSplits',500, ...
    'MinLeafSize',5);

trainingTime = toc;

fprintf('\nTraining completed.\n');
fprintf('Training time : %.2f seconds\n',trainingTime);
fprintf('Training time : %.2f minutes\n',trainingTime/60);

%% Training prediction

predictedTrain = predict( ...
    DecisionTreeModel, ...
    trainFeatNorm);

trainAccuracy = mean( ...
    predictedTrain == trainLabel) * 100;

fprintf('\nTraining Accuracy : %.2f %%\n', ...
    trainAccuracy);

%% Save model

save('DecisionTree_Model.mat', ...
    'DecisionTreeModel', ...
    'trainingTime', ...
    'trainAccuracy');

fprintf('\n========================================\n');
fprintf('DECISION TREE TRAINED SUCCESSFULLY\n');
fprintf('========================================\n');

fprintf('\nModel saved:\n');
fprintf('DecisionTree_Model.mat\n');