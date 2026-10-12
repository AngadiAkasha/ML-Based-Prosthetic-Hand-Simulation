clc;
clear;
close all;

fprintf('\n=====================================\n');
fprintf('DECISION TREE EVALUATION\n');
fprintf('=====================================\n');

load('PredictionResults.mat');
load('DecisionTree_Model.mat');

%% Convert datatype

predictedLabel = cast(predictedLabel,class(testLabel));

predictedLabel = predictedLabel(:);

testLabel = testLabel(:);

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
        f1(i)=2*(precision(i)*recall(i))/...
            (precision(i)+recall(i));
    end

end

%% Print Results

fprintf('\nOverall Accuracy : %.2f %%\n',accuracy*100);

fprintf('Average Precision : %.4f\n',mean(precision));

fprintf('Average Recall    : %.4f\n',mean(recall));

fprintf('Average F1 Score  : %.4f\n',mean(f1));

%% Confusion Matrix

figure;

confusionchart(C);

title('Decision Tree');

%% Feature Importance

figure;

importance = predictorImportance(DecisionTreeModel);

bar(importance);

xlabel('Feature Number');

ylabel('Importance');

title('Decision Tree Feature Importance');

%% Save

save('EvaluationResults.mat',...
    'C',...
    'accuracy',...
    'precision',...
    'recall',...
    'f1',...
    'importance');

fprintf('\nEvaluationResults.mat Saved\n');