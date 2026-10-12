clc;
clear;
close all;

fprintf('\n=====================================\n');
fprintf('KNN EVALUATION\n');
fprintf('=====================================\n');

load('PredictionResults_KNN.mat');

%% Confusion Matrix

C = confusionmat(testLabel,predictedLabel);

disp('Confusion Matrix');
disp(C);

%% Accuracy

accuracy = sum(diag(C))/sum(C(:));

%% Precision Recall F1

numClasses = size(C,1);

precision = zeros(numClasses,1);
recall = zeros(numClasses,1);
f1 = zeros(numClasses,1);

for i = 1:numClasses

    TP = C(i,i);

    FP = sum(C(:,i))-TP;

    FN = sum(C(i,:))-TP;

    precision(i)=TP/(TP+FP+eps);

    recall(i)=TP/(TP+FN+eps);

    f1(i)=2*(precision(i)*recall(i))/...
        (precision(i)+recall(i)+eps);

end

%% Display Results

fprintf('\nOverall Accuracy : %.2f %%\n',accuracy*100);

fprintf('\nAverage Precision : %.4f\n',mean(precision));

fprintf('Average Recall    : %.4f\n',mean(recall));

fprintf('Average F1 Score  : %.4f\n',mean(f1));

%% Plot Confusion Matrix

figure;
confusionchart(C);
title('KNN Confusion Matrix');

%% Save Results

save('EvaluationResults_KNN.mat',...
    'C',...
    'accuracy',...
    'precision',...
    'recall',...
    'f1');

fprintf('\nEvaluationResults_KNN.mat Saved\n');