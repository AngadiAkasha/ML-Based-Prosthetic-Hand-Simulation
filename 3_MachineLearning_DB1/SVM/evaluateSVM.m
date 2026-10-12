clc;
clear;
close all;

fprintf('\n=============================================\n');
fprintf('            SVM PERFORMANCE\n');
fprintf('=============================================\n');

load('PredictionResults.mat');

%% Confusion Matrix

C = confusionmat(testLabel,predictedLabel);

figure;

confusionchart(C);

title('Support Vector Machine');

%% Metrics

numClasses = size(C,1);

precision = zeros(numClasses,1);
recall = zeros(numClasses,1);
f1 = zeros(numClasses,1);

for i=1:numClasses

    TP = C(i,i);

    FP = sum(C(:,i))-TP;

    FN = sum(C(i,:))-TP;

    if TP+FP==0
        precision(i)=0;
    else
        precision(i)=TP/(TP+FP);
    end

    if TP+FN==0
        recall(i)=0;
    else
        recall(i)=TP/(TP+FN);
    end

    if precision(i)+recall(i)==0
        f1(i)=0;
    else
        f1(i)=2*(precision(i)*recall(i))/(precision(i)+recall(i));
    end

end

overallAccuracy = sum(diag(C))/sum(C(:));

macroPrecision = mean(precision);

macroRecall = mean(recall);

macroF1 = mean(f1);

fprintf('\n=============================================\n');

fprintf('Overall Accuracy : %.2f %%\n',overallAccuracy*100);

fprintf('Macro Precision  : %.4f\n',macroPrecision);

fprintf('Macro Recall     : %.4f\n',macroRecall);

fprintf('Macro F1 Score   : %.4f\n',macroF1);

fprintf('=============================================\n');

%% Save

save('EvaluationResults.mat',...
    'C',...
    'overallAccuracy',...
    'macroPrecision',...
    'macroRecall',...
    'macroF1',...
    'precision',...
    'recall',...
    'f1');

fprintf('\nEvaluationResults.mat Saved Successfully\n');