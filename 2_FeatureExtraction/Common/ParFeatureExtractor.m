function [feat, featStim, featRep] = ParFeatureExtractor(...
    emg,...
    stimulus,...
    repetition,...
    deadzone,...
    winsize,...
    wininc,...
    featFunc,...
    ker)

%% Add Feature Functions

addpath(genpath(fileparts(mfilename('fullpath'))));

%% Parallel Pool

if nargin>=8

    pool = gcp('nocreate');

    if isempty(pool)
        parpool(ker);
    end

end

%% Parameters

nSamples = size(emg,1);
nSignals = size(emg,2);

numwin = floor((nSamples-winsize)/wininc)+1;

datawin = ones(winsize,1);

edges = -3:0.3:3;

%% Allocate Memory

switch featFunc

    case 'getHISTfeat'
        feat = zeros(numwin,nSignals*length(edges),'single');

    case 'getTDfeat'
        feat = zeros(numwin,nSignals*5,'single');

    case 'getmDWTfeat'
        feat = zeros(numwin,nSignals*4,'single');

    otherwise
        feat = zeros(numwin,nSignals,'single');

end

featStim = zeros(numwin,1);

featRep = zeros(numwin,1);

check = false(numwin,1);

%% Feature Extraction

parfor k = 1:numwin

    startIdx = (k-1)*wininc + 1;

    endIdx = startIdx + winsize - 1;

    stim = stimulus(startIdx:endIdx);

    rep = repetition(startIdx:endIdx);

    if numel(unique(stim))==1 && numel(unique(rep))==1

        check(k)=true;

        featStim(k)=stim(1);

        featRep(k)=rep(1);

        window = emg(startIdx:endIdx,:);

        switch featFunc

            case 'getrmsfeat'
                feat(k,:) = getrmsfeat(window,winsize,wininc);

            case 'getmavfeat'
                feat(k,:) = getmavfeat(window,winsize,wininc,datawin);

            case 'getzcfeat'
                feat(k,:) = getzcfeat(window,deadzone,winsize,wininc,datawin);

            case 'getsscfeat'
                feat(k,:) = getsscfeat(window,deadzone,winsize,wininc,datawin);

            case 'getwlfeat'
                feat(k,:) = getwlfeat(window,winsize,wininc,datawin);

            case 'getiavfeat'
                feat(k,:) = getiavfeat(window,winsize,wininc,datawin);

            case 'getTDfeat'
                feat(k,:) = getTDfeat(window,deadzone,winsize,wininc);

            case 'getarfeat'
                feat(k,:) = getarfeat(double(window),1,winsize,wininc,datawin);

            case 'getHISTfeat'
                feat(k,:) = getHISTfeat(window,winsize,wininc,edges);

            case 'getmDWTfeat'
                feat(k,:) = getmDWTfeat(window,winsize,wininc);

        end

    end

end

%% Remove Invalid Windows

feat = feat(check,:);

featStim = featStim(check);

featRep = featRep(check);

end