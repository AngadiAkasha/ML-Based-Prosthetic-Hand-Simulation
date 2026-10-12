clc;
clear;
close all;

fprintf('\n=====================================\n');
fprintf('ANN EVALUATION\n');
fprintf('=====================================\n');

load('PredictionResults.mat');

predictedLabel = predictedLabel(:);
testLabel = testLabel(:);

predictedLabel = cast(predictedLabel,class(testLabel));

%% Confusion Matrix

C = confusionmat(testLabel,predictedLabel);

figure;
confusionchart(C);
title('ANN Confusion Matrix');

%% Accuracy

accuracy = sum(diag(C))/sum(C(:));

numClasses = size(C,1);

precision = zeros(numClasses,1);
recall = zeros(numClasses,1);
f1 = zeros(numClasses,1);

for i=1:numClasses

    TP = C(i,i);
    FP = sum(C(:,i))-TP;
    FN = sum(C(i,:))-TP;

    precision(i)=TP/(TP+FP+eps);
    recall(i)=TP/(TP+FN+eps);
    f1(i)=2*precision(i)*recall(i)/(precision(i)+recall(i)+eps);

end

fprintf('\nOverall Accuracy : %.2f %%\n',accuracy*100);

fprintf('Average Precision : %.4f\n',mean(precision));

fprintf('Average Recall    : %.4f\n',mean(recall));

fprintf('Average F1 Score  : %.4f\n',mean(f1));

save('EvaluationResults.mat',...
    'C',...
    'accuracy',...
    'precision',...
    'recall',...
    'f1');