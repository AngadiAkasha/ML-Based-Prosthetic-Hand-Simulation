clc;
clear;
close all;

fprintf('\n=====================================\n');
fprintf('       DECISION TREE EVALUATION\n');
fprintf('=====================================\n');

%% Load Results

load('PredictionResults.mat');
load('DecisionTree_Model.mat');

%% Convert labels to categorical

testLabel = categorical(testLabel);
predictedLabel = categorical(predictedLabel);

testLabel = testLabel(:);
predictedLabel = predictedLabel(:);

%% Check dimensions

if length(testLabel) ~= length(predictedLabel)
    error('Test labels and predicted labels have different sizes.');
end

%% Confusion Matrix

C = confusionmat(testLabel,predictedLabel);

%% Accuracy

correctPredictions = sum(diag(C));
totalPredictions = sum(C(:));

accuracy = correctPredictions / totalPredictions;

%% Precision, Recall, F1

numClasses = size(C,1);

precision = zeros(numClasses,1);
recall = zeros(numClasses,1);
f1 = zeros(numClasses,1);

for i = 1:numClasses

    TP = C(i,i);

    FP = sum(C(:,i)) - TP;

    FN = sum(C(i,:)) - TP;

    % Precision
    precision(i) = TP / (TP + FP + eps);

    % Recall
    recall(i) = TP / (TP + FN + eps);

    % F1 Score
    f1(i) = 2 * precision(i) * recall(i) / ...
        (precision(i) + recall(i) + eps);

end

%% Macro Average

averagePrecision = mean(precision);
averageRecall = mean(recall);
averageF1 = mean(f1);

%% ============================================================
% DISPLAY FINAL RESULTS
% ============================================================

fprintf('\n=====================================\n');
fprintf('       DECISION TREE RESULTS\n');
fprintf('=====================================\n');

fprintf('\nTotal Test Samples : %d\n',totalPredictions);

fprintf('Correct Predictions: %d\n',correctPredictions);

fprintf('Wrong Predictions  : %d\n',...
    totalPredictions-correctPredictions);

fprintf('\n-------------------------------------\n');

fprintf('Accuracy  : %.2f %%\n',accuracy*100);

fprintf('Precision : %.4f\n',averagePrecision);

fprintf('Recall    : %.4f\n',averageRecall);

fprintf('F1 Score  : %.4f\n',averageF1);

fprintf('-------------------------------------\n');

%% ============================================================
% CONFUSION MATRIX
% ============================================================

figure;

cm = confusionchart(testLabel,predictedLabel);

cm.Title = sprintf(...
    'NinaPro DB4 Decision Tree - Accuracy %.2f%%',...
    accuracy*100);

cm.RowSummary = 'row-normalized';
cm.ColumnSummary = 'column-normalized';

%% ============================================================
% FEATURE IMPORTANCE
% ============================================================

importance = predictorImportance(DecisionTreeModel);

%% Feature Importance Plot

figure;

bar(importance);

xlabel('RMS Feature / EMG Channel');
ylabel('Importance');

title(sprintf(...
    'Decision Tree Feature Importance - Accuracy %.2f%%',...
    accuracy*100));

grid on;

%% ============================================================
% SAVE RESULTS
% ============================================================

save('EvaluationResults.mat',...
    'C',...
    'accuracy',...
    'precision',...
    'recall',...
    'f1',...
    'averagePrecision',...
    'averageRecall',...
    'averageF1',...
    'importance');

%% ============================================================

fprintf('\n=====================================\n');
fprintf('     EVALUATION COMPLETED\n');
fprintf('=====================================\n');

fprintf('\nFINAL RESULTS\n');
fprintf('Accuracy  : %.2f %%\n',accuracy*100);
fprintf('Precision : %.4f\n',averagePrecision);
fprintf('Recall    : %.4f\n',averageRecall);
fprintf('F1 Score  : %.4f\n',averageF1);

fprintf('\nEvaluationResults.mat Saved Successfully\n');