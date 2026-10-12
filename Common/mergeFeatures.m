clc;
clear;
close all;

fprintf('\n====================================\n');
fprintf('MERGING FEATURE FILES\n');
fprintf('====================================\n');

%% Folder containing extracted features

featureFolder = fullfile('..','ExtractedFeatures');

files = dir(fullfile(featureFolder,'*_RMS.mat'));

fprintf('Feature Files Found : %d\n\n',length(files));

allFeat = [];
allStim = [];
allRep = [];

%% Merge all feature files

for i = 1:length(files)

    fprintf('Reading : %s\n',files(i).name);

    data = load(fullfile(featureFolder,files(i).name));

    allFeat = [allFeat ; data.feat];
    allStim = [allStim ; data.featStim];
    allRep = [allRep ; data.featRep];

end

fprintf('\n');

fprintf('Total Samples  : %d\n',size(allFeat,1));
fprintf('Total Features : %d\n',size(allFeat,2));

save('AllFeatures.mat',...
    'allFeat',...
    'allStim',...
    'allRep');

fprintf('\nAllFeatures.mat Saved Successfully\n');