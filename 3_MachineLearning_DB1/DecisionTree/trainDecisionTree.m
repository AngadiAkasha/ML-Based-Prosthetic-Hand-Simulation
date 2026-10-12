clc;
clear;
close all;

fprintf('\n=====================================\n');
fprintf('TRAINING DECISION TREE\n');
fprintf('=====================================\n');

%% Load Training Data

load('../Common/NormalizedTrain.mat');

%% Train Decision Tree

tic

DecisionTreeModel = fitctree(...
    trainFeatNorm,...
    trainLabel,...
    'OptimizeHyperparameters','auto',...
    'HyperparameterOptimizationOptions',...
    struct('ShowPlots',false,'Verbose',0));

trainingTime = toc;

%% Save Model

save('DecisionTree_Model.mat',...
    'DecisionTreeModel',...
    'trainingTime');

fprintf('\nTraining Completed Successfully\n');
fprintf('Training Time : %.2f seconds\n',trainingTime);