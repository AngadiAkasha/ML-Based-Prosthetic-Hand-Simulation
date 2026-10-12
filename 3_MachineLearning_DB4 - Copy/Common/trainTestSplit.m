clc;
clear;
close all;

fprintf('\n');
fprintf('=====================================================\n');
fprintf('          DB4 - TRAIN / TEST SPLIT\n');
fprintf('=====================================================\n');

%% =====================================================
% LOAD
% ======================================================

dataFile = fullfile( ...
    '..','..', ...
    '3_MachineLearning_DB4', ...
    'AllFeatures.mat');

if ~exist(dataFile,'file')

    error('AllFeatures.mat not found.');

end

data = load(dataFile);

allFeat = data.allFeat;

allStim = data.allStim;

allRep = data.allRep;

%% =====================================================
% CHECK 52 CLASSES
% ======================================================

classes = unique(allStim);

fprintf('\nNumber of classes : %d\n',length(classes));

if length(classes) ~= 52

    error( ...
        'Expected 52 classes but found %d.', ...
        length(classes));

end

%% =====================================================
% RANDOM SEED
% ======================================================

rng(42);

%% =====================================================
% STRATIFIED SPLIT
% ======================================================

trainRatio = 0.80;

trainIdx = [];

testIdx = [];

for i = 1:length(classes)

    c = classes(i);

    idx = find(allStim == c);

    idx = idx(randperm(length(idx)));

    nTrain = floor(trainRatio * length(idx));

    trainIdx = [ ...
        trainIdx; ...
        idx(1:nTrain)];

    testIdx = [ ...
        testIdx; ...
        idx(nTrain+1:end)];

end

%% =====================================================
% SHUFFLE
% ======================================================

trainIdx = trainIdx(randperm(length(trainIdx)));

testIdx = testIdx(randperm(length(testIdx)));

%% =====================================================
% CREATE DATASETS
% ======================================================

trainFeat = allFeat(trainIdx,:);

trainLabel = allStim(trainIdx);

trainRep = allRep(trainIdx);

testFeat = allFeat(testIdx,:);

testLabel = allStim(testIdx);

testRep = allRep(testIdx);

%% =====================================================
% DISPLAY
% ======================================================

fprintf('\n');
fprintf('Training samples : %d\n',size(trainFeat,1));

fprintf('Testing samples  : %d\n',size(testFeat,1));

fprintf('Features/sample  : %d\n',size(trainFeat,2));

%% =====================================================
% CLASS CHECK
% ======================================================

fprintf('\nTraining class distribution:\n');

for c = 1:52

    fprintf( ...
        'Class %2d : %d\n', ...
        c, ...
        sum(trainLabel == c));

end

fprintf('\nTesting class distribution:\n');

for c = 1:52

    fprintf( ...
        'Class %2d : %d\n', ...
        c, ...
        sum(testLabel == c));

end

%% =====================================================
% SAVE
% ======================================================

outputFolder = fullfile( ...
    '..','..', ...
    '3_MachineLearning_DB4');

save( ...
    fullfile(outputFolder,'TrainData.mat'), ...
    'trainFeat', ...
    'trainLabel', ...
    'trainRep', ...
    '-v7.3');

save( ...
    fullfile(outputFolder,'TestData.mat'), ...
    'testFeat', ...
    'testLabel', ...
    'testRep', ...
    '-v7.3');

fprintf('\n');
fprintf('TrainData.mat saved.\n');
fprintf('TestData.mat saved.\n');

fprintf('\n');
fprintf('=====================================================\n');
fprintf('       DB4 TRAIN / TEST SPLIT COMPLETE\n');
fprintf('=====================================================\n');