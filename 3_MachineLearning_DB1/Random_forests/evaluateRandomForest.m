function evaluateRandomForest()
% EVALUATERANDOMFOREST
% Detailed evaluation of the DB1 Random Forest classifier.
%
% Input:
%   PredictionResults_RF.mat
%
% Calculates:
%   Accuracy
%   Macro Precision
%   Macro Recall
%   Macro F1
%   Weighted Precision
%   Weighted Recall
%   Weighted F1
%   Per-class Precision
%   Per-class Recall
%   Per-class F1
%   Confusion Matrix

clc;
clear;
close all;

fprintf('\n');
fprintf('============================================\n');
fprintf(' RANDOM FOREST EVALUATION - NINAPRO DB1\n');
fprintf('============================================\n');

%% ============================================================
% 1. CHECK RESULT FILE
% =============================================================

resultFile = 'PredictionResults_RF.mat';

if ~isfile(resultFile)

    error(['PredictionResults_RF.mat not found.\n' ...
           'Run testRandomForest.m first.']);

end

%% ============================================================
% 2. LOAD RESULTS
% =============================================================

load(resultFile);

fprintf('\nPrediction results loaded.\n');

%% ============================================================
% 3. CHECK VARIABLES
% =============================================================

if ~exist('testLabel','var')

    error('Variable "testLabel" not found.');

end

if ~exist('predictedLabel','var')

    error('Variable "predictedLabel" not found.');

end

%% ============================================================
% 4. CONVERT TO COLUMN VECTORS
% =============================================================

testLabel = double(testLabel(:));

predictedLabel = double(predictedLabel(:));

%% ============================================================
% 5. CHECK SAMPLE COUNTS
% =============================================================

if numel(testLabel) ~= numel(predictedLabel)

    error(['Test label and prediction lengths do not match.\n' ...
           'Test labels = %d\n' ...
           'Predictions = %d'], ...
           numel(testLabel), ...
           numel(predictedLabel));

end

%% ============================================================
% 6. DETERMINE CLASS LIST
% =============================================================

classes = unique([testLabel; predictedLabel]);

numClasses = numel(classes);

fprintf('\n============================================\n');
fprintf(' EVALUATION INFORMATION\n');
fprintf('============================================\n');

fprintf('Number of test samples: %d\n', ...
    numel(testLabel));

fprintf('Number of classes     : %d\n', ...
    numClasses);

fprintf('\nClasses:\n');

disp(classes');

%% ============================================================
% 7. CONFUSION MATRIX
% =============================================================

C = confusionmat( ...
    testLabel, ...
    predictedLabel, ...
    'Order',classes);

%% ============================================================
% 8. INITIALIZE METRICS
% =============================================================

precision = zeros(numClasses,1);

recall = zeros(numClasses,1);

F1 = zeros(numClasses,1);

support = zeros(numClasses,1);

%% ============================================================
% 9. CALCULATE CLASS-WISE METRICS
% =============================================================

for i = 1:numClasses

    TP = C(i,i);

    FP = sum(C(:,i)) - TP;

    FN = sum(C(i,:)) - TP;

    support(i) = sum(C(i,:));

    % Precision
    if TP + FP > 0

        precision(i) = ...
            TP / (TP + FP);

    else

        precision(i) = 0;

    end

    % Recall
    if TP + FN > 0

        recall(i) = ...
            TP / (TP + FN);

    else

        recall(i) = 0;

    end

    % F1
    if precision(i) + recall(i) > 0

        F1(i) = ...
            2 * precision(i) * recall(i) ...
            / (precision(i) + recall(i));

    else

        F1(i) = 0;

    end

end

%% ============================================================
% 10. OVERALL ACCURACY
% =============================================================

accuracy = ...
    sum(diag(C)) / sum(C(:));

%% ============================================================
% 11. MACRO METRICS
% =============================================================

macroPrecision = mean(precision);

macroRecall = mean(recall);

macroF1 = mean(F1);

%% ============================================================
% 12. WEIGHTED METRICS
% =============================================================

totalSamples = sum(support);

weightedPrecision = ...
    sum(precision .* support) / totalSamples;

weightedRecall = ...
    sum(recall .* support) / totalSamples;

weightedF1 = ...
    sum(F1 .* support) / totalSamples;

%% ============================================================
% 13. PRINT MAIN RESULTS
% =============================================================

fprintf('\n');
fprintf('============================================\n');
fprintf(' FINAL RANDOM FOREST RESULTS\n');
fprintf('============================================\n');

fprintf('\nAccuracy          : %.4f %%\n', ...
    accuracy*100);

fprintf('Macro Precision   : %.4f %%\n', ...
    macroPrecision*100);

fprintf('Macro Recall      : %.4f %%\n', ...
    macroRecall*100);

fprintf('Macro F1-score    : %.4f %%\n', ...
    macroF1*100);

fprintf('\nWeighted Precision: %.4f %%\n', ...
    weightedPrecision*100);

fprintf('Weighted Recall   : %.4f %%\n', ...
    weightedRecall*100);

fprintf('Weighted F1-score : %.4f %%\n', ...
    weightedF1*100);

%% ============================================================
% 14. CLASS-WISE RESULTS
% =============================================================

fprintf('\n');
fprintf('============================================\n');
fprintf(' CLASS-WISE RESULTS\n');
fprintf('============================================\n');

fprintf('\n');
fprintf('Class\tPrecision\tRecall\t\tF1\t\tSupport\n');

fprintf('------------------------------------------------------------\n');

for i = 1:numClasses

    fprintf( ...
        '%g\t%.4f\t\t%.4f\t\t%.4f\t\t%d\n', ...
        classes(i), ...
        precision(i), ...
        recall(i), ...
        F1(i), ...
        support(i));

end

%% ============================================================
% 15. CONFUSION MATRIX
% ============================================================

figure( ...
    'Name','DB1 Random Forest Confusion Matrix', ...
    'Color','w', ...
    'Position',[100 100 1200 900]);

cm = confusionchart( ...
    C, ...
    string(classes));

cm.Title = sprintf( ...
    'Random Forest Confusion Matrix - DB1 (%d Classes)', ...
    numClasses);

cm.RowSummary = 'row-normalized';

cm.ColumnSummary = 'column-normalized';

%% ============================================================
% 16. PRECISION / RECALL / F1 GRAPH
% ============================================================

figure( ...
    'Name','Class-wise Performance', ...
    'Color','w');

bar( ...
    classes, ...
    [precision recall F1]);

grid on;

xlabel('Class');

ylabel('Score');

ylim([0 1.05]);

legend( ...
    'Precision', ...
    'Recall', ...
    'F1-score', ...
    'Location','best');

title(sprintf( ...
    'Class-wise Performance - DB1 (%d Classes)', ...
    numClasses));

%% ============================================================
% 17. SAVE EVALUATION RESULTS
% =============================================================

save( ...
    'EvaluationResults_RF.mat', ...
    'C', ...
    'classes', ...
    'numClasses', ...
    'accuracy', ...
    'precision', ...
    'recall', ...
    'F1', ...
    'support', ...
    'macroPrecision', ...
    'macroRecall', ...
    'macroF1', ...
    'weightedPrecision', ...
    'weightedRecall', ...
    'weightedF1', ...
    '-v7.3');

%% ============================================================
% 18. FINAL SUMMARY
% =============================================================

fprintf('\n');
fprintf('============================================\n');
fprintf(' EVALUATION COMPLETE\n');
fprintf('============================================\n');

fprintf('Classes          : %d\n',numClasses);

fprintf('Accuracy         : %.2f %%\n', ...
    accuracy*100);

fprintf('Macro Precision  : %.2f %%\n', ...
    macroPrecision*100);

fprintf('Macro Recall     : %.2f %%\n', ...
    macroRecall*100);

fprintf('Macro F1         : %.2f %%\n', ...
    macroF1*100);

fprintf('Weighted F1      : %.2f %%\n', ...
    weightedF1*100);

fprintf('\nSaved:\n');

fprintf('EvaluationResults_RF.mat\n');

fprintf('\n============================================\n');
fprintf('\n=============================================\n');
fprintf('        CLASS DISTRIBUTION CHECK\n');
fprintf('=============================================\n');

classes = unique(testLabel);

for i = 1:length(classes)

    c = classes(i);

    n = sum(testLabel == c);

    fprintf('Class %2d : %d samples\n', c, n);

end

fprintf('=============================================\n');
fprintf('Total test samples : %d\n', length(testLabel));
end