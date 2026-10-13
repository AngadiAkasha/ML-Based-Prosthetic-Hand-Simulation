clc;
clear;
close all;

fprintf('\n=====================================\n');
fprintf('TRAINING ANN MODEL\n');
fprintf('=====================================\n');

%% Load Training Data
load('../Common/NormalizedTrain.mat');

% Ensure labels are column vectors
trainLabel = trainLabel(:);

%% Convert labels to categorical indices
classes = unique(trainLabel);
numClasses = length(classes);

targets = zeros(numClasses,length(trainLabel));

for i = 1:length(trainLabel)
    idx = find(classes==trainLabel(i));
    targets(idx,i) = 1;
end

%% Create Neural Network

hiddenLayerSize = [64 32];

net = patternnet(hiddenLayerSize);

net.trainFcn = 'trainscg';
net.performFcn = 'crossentropy';

net.divideFcn = 'dividerand';
net.divideParam.trainRatio = 0.80;
net.divideParam.valRatio   = 0.20;
net.divideParam.testRatio  = 0.00;

net.trainParam.epochs = 500;
net.trainParam.goal = 1e-6;
net.trainParam.max_fail = 10;
net.trainParam.min_grad = 1e-7;

net.layers{1}.transferFcn = 'tansig';
net.layers{2}.transferFcn = 'tansig';
net.layers{3}.transferFcn = 'softmax';

%% Train

tic

[net,tr] = train(net,trainFeatNorm',targets);

trainingTime = toc;

save('ANN_Model.mat',...
    'net',...
    'classes',...
    'trainingTime',...
    'tr');

fprintf('\nTraining Completed Successfully\n');
fprintf('Training Time : %.2f seconds\n',trainingTime);