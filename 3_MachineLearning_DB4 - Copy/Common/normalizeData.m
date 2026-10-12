clc;
clear;
close all;

fprintf('\n');
fprintf('=====================================================\n');
fprintf('          DB4 - FEATURE NORMALIZATION\n');
fprintf('=====================================================\n');

%% =====================================================
% PATH
% ======================================================

dataFolder = fullfile( ...
    '..','..', ...
    '3_MachineLearning_DB4');

%% =====================================================
% LOAD TRAIN / TEST
% ======================================================

trainData = load( ...
    fullfile(dataFolder,'TrainData.mat'));

testData = load( ...
    fullfile(dataFolder,'TestData.mat'));

trainFeat = trainData.trainFeat;

trainLabel = trainData.trainLabel;

trainRep = trainData.trainRep;

testFeat = testData.testFeat;

testLabel = testData.testLabel;

testRep = testData.testRep;

%% =====================================================
% CHECK DIMENSIONS
% ======================================================

fprintf('\nTraining data : %d x %d\n', ...
    size(trainFeat,1), ...
    size(trainFeat,2));

fprintf('Testing data  : %d x %d\n', ...
    size(testFeat,1), ...
    size(testFeat,2));

%% =====================================================
% TRAINING MEAN / STD
% ======================================================

mu = mean(trainFeat,1);

sigma = std(trainFeat,0,1);

%% =====================================================
% AVOID DIVISION BY ZERO
% ======================================================

sigma(sigma == 0) = 1;

%% =====================================================
% NORMALIZATION
% ======================================================

trainFeatNorm = ...
    (trainFeat - mu) ./ sigma;

testFeatNorm = ...
    (testFeat - mu) ./ sigma;

%% =====================================================
% CHECK
% ======================================================

fprintf('\nNormalized training mean:\n');

disp(mean(trainFeatNorm,1));

fprintf('\nNormalized training std:\n');

disp(std(trainFeatNorm,0,1));

%% =====================================================
% SAVE
% ======================================================

save( ...
    fullfile(dataFolder,'NormalizedTrain.mat'), ...
    'trainFeatNorm', ...
    'trainLabel', ...
    'trainRep', ...
    'mu', ...
    'sigma', ...
    '-v7.3');

save( ...
    fullfile(dataFolder,'NormalizedTest.mat'), ...
    'testFeatNorm', ...
    'testLabel', ...
    'testRep', ...
    'mu', ...
    'sigma', ...
    '-v7.3');

fprintf('\n');
fprintf('NormalizedTrain.mat saved.\n');

fprintf('NormalizedTest.mat saved.\n');

fprintf('\n');
fprintf('=====================================================\n');
fprintf('        DB4 NORMALIZATION COMPLETE\n');
fprintf('=====================================================\n');