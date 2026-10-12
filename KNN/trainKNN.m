clc;
clear;
close all;

fprintf('\n=====================================\n');
fprintf('TRAINING K-NEAREST NEIGHBOR\n');
fprintf('=====================================\n');

%% Load Training Data

load('../Common/NormalizedTrain.mat');

%% Number of Neighbors

k = 5;

%% Train KNN

KNNModel = fitcknn(...
    trainFeatNorm,...
    trainLabel,...
    'NumNeighbors',k,...
    'Distance','euclidean',...
    'Standardize',false);

%% Save Model

save('KNN_Model.mat','KNNModel');

fprintf('\nKNN Model Saved Successfully\n');
fprintf('Number of Neighbors : %d\n',k);