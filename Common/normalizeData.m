function normalizeData()
% NORMALIZEDATA
% Normalize DB1 training and testing feature data.
%
% Input:
%   TrainData.mat
%       trainFeat
%       trainLabel
%       trainRep
%
%   TestData.mat
%       testFeat
%       testLabel
%       testRep
%
% Output:
%   NormalizedTrain.mat
%       trainFeatNorm
%       trainLabel
%       trainRep
%       mu
%       sigma
%
%   NormalizedTest.mat
%       testFeatNorm
%       testLabel
%       testRep
%
% IMPORTANT:
%   Mean and standard deviation are calculated ONLY from
%   training data. The same parameters are applied to test data.

clc;
clear;
close all;

fprintf('\n============================================\n');
fprintf(' DB1 FEATURE NORMALIZATION\n');
fprintf('============================================\n');

%% ============================================================
% 1. LOAD TRAINING DATA
% =============================================================

if ~isfile('TrainData.mat')

    error(['TrainData.mat not found.\n' ...
           'Run trainTestSplit.m first.']);

end

load('TrainData.mat');

fprintf('\nTrainData.mat loaded successfully.\n');

%% ============================================================
% 2. LOAD TESTING DATA
% =============================================================

if ~isfile('TestData.mat')

    error(['TestData.mat not found.\n' ...
           'Run trainTestSplit.m first.']);

end

load('TestData.mat');

fprintf('TestData.mat loaded successfully.\n');

%% ============================================================
% 3. CHECK REQUIRED VARIABLES
% =============================================================

requiredTrain = {'trainFeat','trainLabel'};

requiredTest = {'testFeat','testLabel'};

for i = 1:numel(requiredTrain)

    if ~exist(requiredTrain{i},'var')

        error('Variable %s not found in TrainData.mat.', ...
            requiredTrain{i});

    end

end

for i = 1:numel(requiredTest)

    if ~exist(requiredTest{i},'var')

        error('Variable %s not found in TestData.mat.', ...
            requiredTest{i});

    end

end

%% ============================================================
% 4. CONVERT TO DOUBLE
% =============================================================

trainFeat = double(trainFeat);

testFeat = double(testFeat);

trainLabel = double(trainLabel(:));

testLabel = double(testLabel(:));

%% ============================================================
% 5. DISPLAY INPUT INFORMATION
% =============================================================

fprintf('\n============================================\n');
fprintf(' INPUT DATA\n');
fprintf('============================================\n');

fprintf('Training samples : %d\n', ...
    size(trainFeat,1));

fprintf('Training features: %d\n', ...
    size(trainFeat,2));

fprintf('Testing samples  : %d\n', ...
    size(testFeat,1));

fprintf('Testing features : %d\n', ...
    size(testFeat,2));

fprintf('Training classes : %d\n', ...
    numel(unique(trainLabel)));

fprintf('Testing classes  : %d\n', ...
    numel(unique(testLabel)));

%% ============================================================
% 6. CHECK FEATURE DIMENSIONS
% =============================================================

if size(trainFeat,2) ~= size(testFeat,2)

    error(['Training and testing feature dimensions do not match.\n' ...
           'Training features = %d\n' ...
           'Testing features  = %d'], ...
           size(trainFeat,2), ...
           size(testFeat,2));

end

%% ============================================================
% 7. CHECK LABEL/SAMPLE COUNTS
% =============================================================

if size(trainFeat,1) ~= numel(trainLabel)

    error(['Training feature and label counts do not match.\n' ...
           'Features = %d\n' ...
           'Labels   = %d'], ...
           size(trainFeat,1), ...
           numel(trainLabel));

end

if size(testFeat,1) ~= numel(testLabel)

    error(['Testing feature and label counts do not match.\n' ...
           'Features = %d\n' ...
           'Labels   = %d'], ...
           size(testFeat,1), ...
           numel(testLabel));

end

%% ============================================================
% 8. CHECK CLASS INFORMATION
% =============================================================

trainClasses = unique(trainLabel);

testClasses = unique(testLabel);

fprintf('\n============================================\n');
fprintf(' CLASS CHECK\n');
fprintf('============================================\n');

fprintf('Training classes = %d\n', ...
    numel(trainClasses));

fprintf('Testing classes  = %d\n', ...
    numel(testClasses));

fprintf('\nTraining labels:\n');
disp(trainClasses');

fprintf('Testing labels:\n');
disp(testClasses');

%% ============================================================
% 9. CHECK FOR MISSING CLASSES
% =============================================================

missingTrain = setdiff(testClasses,trainClasses);

missingTest = setdiff(trainClasses,testClasses);

if ~isempty(missingTrain)

    warning(['These classes occur in testing data but not ' ...
             'training data: %s'], ...
             mat2str(missingTrain'));

end

if ~isempty(missingTest)

    warning(['These classes occur in training data but not ' ...
             'testing data: %s'], ...
             mat2str(missingTest'));

end

%% ============================================================
% 10. CHECK NaN / INF VALUES
% =============================================================

if any(~isfinite(trainFeat(:)))

    warning('Training features contain NaN or Inf values.');

end

if any(~isfinite(testFeat(:)))

    warning('Testing features contain NaN or Inf values.');

end

%% ============================================================
% 11. CALCULATE TRAINING MEAN
% ============================================================
%
% IMPORTANT:
% Only training data is used to calculate normalization
% parameters.
%
% Test data must NOT be used here.

mu = mean(trainFeat,1);

%% ============================================================
% 12. CALCULATE TRAINING STANDARD DEVIATION
% =============================================================

sigma = std(trainFeat,0,1);

%% ============================================================
% 13. PROTECT AGAINST ZERO STANDARD DEVIATION
% =============================================================

zeroStd = sigma == 0;

if any(zeroStd)

    fprintf('\nWarning: %d feature(s) have zero standard deviation.\n', ...
        sum(zeroStd));

    sigma(zeroStd) = 1;

end

%% ============================================================
% 14. NORMALIZE TRAINING FEATURES
% ============================================================
%
% Standardization:
%
% z = (x - mean) / standard deviation

trainFeatNorm = ...
    (trainFeat - mu) ./ sigma;

%% ============================================================
% 15. NORMALIZE TESTING FEATURES
% ============================================================
%
% IMPORTANT:
% Use the SAME mu and sigma obtained from training data.

testFeatNorm = ...
    (testFeat - mu) ./ sigma;

%% ============================================================
% 16. HANDLE INVALID NORMALIZED VALUES
% =============================================================

trainFeatNorm(~isfinite(trainFeatNorm)) = 0;

testFeatNorm(~isfinite(testFeatNorm)) = 0;

%% ============================================================
% 17. CHECK NORMALIZED DATA
% =============================================================

fprintf('\n============================================\n');
fprintf(' NORMALIZATION CHECK\n');
fprintf('============================================\n');

fprintf('Training normalized size: %d x %d\n', ...
    size(trainFeatNorm,1), ...
    size(trainFeatNorm,2));

fprintf('Testing normalized size : %d x %d\n', ...
    size(testFeatNorm,1), ...
    size(testFeatNorm,2));

fprintf('\nTraining normalized mean:\n');
disp(mean(trainFeatNorm,1));

fprintf('Training normalized standard deviation:\n');
disp(std(trainFeatNorm,0,1));

%% ============================================================
% 18. PRESERVE REPETITION INFORMATION
% =============================================================

if exist('trainRep','var')

    trainRep = double(trainRep(:));

end

if exist('testRep','var')

    testRep = double(testRep(:));

end

%% ============================================================
% 19. SAVE NORMALIZED TRAINING DATA
% =============================================================

save('NormalizedTrain.mat', ...
    'trainFeatNorm', ...
    'trainLabel', ...
    'mu', ...
    'sigma', ...
    '-v7.3');

%% ============================================================
% 20. SAVE NORMALIZED TESTING DATA
% =============================================================

save('NormalizedTest.mat', ...
    'testFeatNorm', ...
    'testLabel', ...
    '-v7.3');

%% ============================================================
% 21. FINAL SUMMARY
% =============================================================

fprintf('\n============================================\n');
fprintf(' NORMALIZATION COMPLETE\n');
fprintf('============================================\n');

fprintf('Training samples : %d\n', ...
    size(trainFeatNorm,1));

fprintf('Testing samples  : %d\n', ...
    size(testFeatNorm,1));

fprintf('Feature dimension: %d\n', ...
    size(trainFeatNorm,2));

fprintf('Training classes : %d\n', ...
    numel(unique(trainLabel)));

fprintf('Testing classes  : %d\n', ...
    numel(unique(testLabel)));

fprintf('\nSaved files:\n');

fprintf('  NormalizedTrain.mat\n');
fprintf('  NormalizedTest.mat\n');

fprintf('\n============================================\n');
fprintf(' NEXT STEP:\n');
fprintf(' Run trainRandomForest.m\n');
fprintf('============================================\n');

end