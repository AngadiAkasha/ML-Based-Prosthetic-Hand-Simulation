function visualizeRandomForest()
% VISUALIZECONTROLLER
% Fresh MATLAB R2025b-compatible prosthetic-hand visualizer.
%
% INPUT:
%   ControllerResults.mat
%
% Expected data (directly or inside a structure):
%   actualAngleHistory / actualAngles
%   desiredAngleHistory / desiredAngles
%   predictedLabel / predictedLabels / currentGesture / gesture
%   dt
%
% Finger order:
%   [Thumb Index Middle Ring Little]
%
% IMPORTANT FIX:
%   The timer Period is fixed at 0.05 s.
%   The Speed control changes the number of frames advanced per tick.
%   It NEVER changes timer.Period, so the sub-millisecond timer warning
%   from the previous speedCallback is removed.
%
% The 3-D hand is driven by the selected pose:
%   Gesture Target -> classified gesture -> joint-angle mapping
%   Actual PID    -> actualAngleHistory
%   Blend        -> combination of both
%
% Gesture mapping is a visualization mapping. It is not an anatomical
% measurement unless your controller explicitly defines it that way.

clc;
close all;

%% ========================= SETTINGS ===============================
LABEL_BASE = 0;          % DB1 convention: 0...52
DEFAULT_MODE = 1;        % 1 Gesture Target, 2 Actual PID, 3 Blend
BLEND_ALPHA = 0.50;
TIMER_PERIOD = 0.05;     % FIXED; do not make this depend on speed
FINGER_NAMES = {'Thumb','Index','Middle','Ring','Little'};

%% ========================= LOAD RESULTS ===========================
currentFolder = fileparts(mfilename('fullpath'));
if isempty(currentFolder)
    currentFolder = pwd;
end

resultFile = fullfile(currentFolder,'ControllerResults.mat');

if ~isfile(resultFile)
    error(['ControllerResults.mat was not found.' newline newline ...
           'Expected:' newline '%s' newline newline ...
           'Run runController.m first.'], resultFile);
end

S = load(resultFile);

actualHistory = getVariableRecursive(S, ...
    {'actualAngleHistory','actualAngles'});

desiredHistory = getVariableRecursive(S, ...
    {'desiredAngleHistory','desiredAngles'});

gestureVector = getVariableRecursive(S, ...
    {'predictedLabel','predictedLabels','currentGesture','gesture'});

dt = getVariableRecursive(S,{'dt'});

if isempty(dt) || ~isnumeric(dt) || ~isscalar(dt) || ...
        ~isfinite(dt) || dt <= 0
    dt = 0.01;
else
    dt = double(dt);
end

%% ========================= RANDOM FOREST FALLBACK ==================
% If ControllerResults.mat does not contain one prediction per frame,
% use Random_forests/PredictionResults_RF.mat when available.

gestureVector = prepareGestureVector(gestureVector);

if numel(gestureVector) <= 1
    predictionFile = fullfile(currentFolder, ...
                              'Random_forests', ...
                              'PredictionResults_RF.mat');

    if isfile(predictionFile)
        try
            P = load(predictionFile);
            rfLabels = getVariableRecursive(P, ...
                {'predictedLabel','predictedLabels'});

            rfLabels = prepareGestureVector(rfLabels);

            if numel(rfLabels) > 1
                gestureVector = rfLabels;
                fprintf('Using Random Forest predictions: %d labels\n', ...
                        numel(gestureVector));
            end
        catch ME
            warning('Could not load RF predictions: %s',ME.message);
        end
    end
end

%% ========================= PREPARE ANGLES ==========================
actualHistory = prepareAngleHistory(actualHistory);
desiredHistory = prepareAngleHistory(desiredHistory);

if isempty(actualHistory) && isempty(desiredHistory)
    error(['No usable finger-angle history was found.' newline ...
           'Expected actualAngleHistory/actualAngles or ' ...
           'desiredAngleHistory/desiredAngles.']);
end

if isempty(actualHistory)
    actualHistory = desiredHistory;
end

if isempty(desiredHistory)
    desiredHistory = actualHistory;
end

N = max([size(actualHistory,1), ...
         size(desiredHistory,1), ...
         numel(gestureVector)]);

if N < 1
    error('No controller frames are available.');
end

actualHistory  = resizeHistory(actualHistory,N);
desiredHistory = resizeHistory(desiredHistory,N);
gestureVector  = resizeVector(gestureVector,N);

actualHistory  = convertToRadiansIfNeeded(actualHistory);
desiredHistory = convertToRadiansIfNeeded(desiredHistory);

actualHistory(~isfinite(actualHistory)) = 0;
desiredHistory(~isfinite(desiredHistory)) = 0;

%% ========================= GESTURE TARGETS =========================
targetHistory = zeros(N,5);

for k = 1:N
    if isfinite(gestureVector(k))
        targetHistory(k,:) = gestureToPose(gestureVector(k),LABEL_BASE);
    else
        targetHistory(k,:) = desiredHistory(k,:);
    end
end

targetHistory(~isfinite(targetHistory)) = 0;

fprintf('\n===============================================\n');
fprintf('3-D PROSTHETIC HAND CONTROLLER\n');
fprintf('===============================================\n');
fprintf('Frames       : %d\n',N);
fprintf('dt           : %.4f sec\n',dt);
fprintf('Timer period : %.3f sec (fixed)\n',TIMER_PERIOD);
fprintf('===============================================\n\n');

%% ========================= STATE ==================================
currentFrame = 1;
isPlaying = false;
playSpeed = 1;
poseMode = DEFAULT_MODE;
timerObj = [];

%% ========================= FIGURE ================================
fig = figure( ...
    'Name','3-D Prosthetic Hand Controller', ...
    'NumberTitle','off', ...
    'Color',[0.035 0.045 0.060], ...
    'Position',[50 40 1500 850], ...
    'CloseRequestFcn',@closeFigure);

ax = axes( ...
    'Parent',fig, ...
    'Units','normalized', ...
    'Position',[0.035 0.17 0.60 0.75], ...
    'Color',[0.055 0.065 0.085], ...
    'XColor','w','YColor','w','ZColor','w', ...
    'FontSize',10);

hold(ax,'on');
grid(ax,'on');
axis(ax,'equal');
xlim(ax,[-6.5 6.5]);
ylim(ax,[-5.5 7.0]);
zlim(ax,[-2.5 7.5]);
view(ax,135,24);

xlabel(ax,'X','Color','w');
ylabel(ax,'Y','Color','w');
zlabel(ax,'Z','Color','w');

%% ========================= INFO PANEL ============================
infoText = uicontrol(fig, ...
    'Style','text', ...
    'String','', ...
    'Units','normalized', ...
    'Position',[0.665 0.665 0.31 0.235], ...
    'BackgroundColor',[0.075 0.085 0.11], ...
    'ForegroundColor','w', ...
    'HorizontalAlignment','left', ...
    'FontSize',11);

angleText = uicontrol(fig, ...
    'Style','text', ...
    'String','', ...
    'Units','normalized', ...
    'Position',[0.665 0.385 0.31 0.245], ...
    'BackgroundColor',[0.075 0.085 0.11], ...
    'ForegroundColor','w', ...
    'HorizontalAlignment','left', ...
    'FontSize',10);

%% ========================= MODE ===================================
uicontrol(fig,'Style','text', ...
    'String','Pose source', ...
    'Units','normalized', ...
    'Position',[0.665 0.315 0.09 0.035], ...
    'BackgroundColor',[0.035 0.045 0.060], ...
    'ForegroundColor','w', ...
    'HorizontalAlignment','left');

modeMenu = uicontrol(fig, ...
    'Style','popupmenu', ...
    'String',{'Gesture Target','Actual PID','Blend'}, ...
    'Value',poseMode, ...
    'Units','normalized', ...
    'Position',[0.755 0.315 0.20 0.04], ...
    'Callback',@changeMode);

%% ========================= SPEED ==================================
uicontrol(fig,'Style','text', ...
    'String','Speed', ...
    'Units','normalized', ...
    'Position',[0.665 0.255 0.09 0.035], ...
    'BackgroundColor',[0.035 0.045 0.060], ...
    'ForegroundColor','w', ...
    'HorizontalAlignment','left');

speedMenu = uicontrol(fig, ...
    'Style','popupmenu', ...
    'String',{'0.25x','0.5x','1x','2x','4x','8x'}, ...
    'Value',3, ...
    'Units','normalized', ...
    'Position',[0.755 0.255 0.20 0.04], ...
    'Callback',@changeSpeed);

%% ========================= CAMERA =================================
uicontrol(fig, ...
    'Style','pushbutton', ...
    'String','RESET CAMERA', ...
    'Units','normalized', ...
    'Position',[0.665 0.185 0.29 0.055], ...
    'FontSize',10, ...
    'Callback',@resetCamera);

%% ========================= SLIDER =================================
slider = uicontrol(fig, ...
    'Style','slider', ...
    'Units','normalized', ...
    'Position',[0.075 0.095 0.57 0.035], ...
    'Min',1, ...
    'Max',max(2,N), ...
    'Value',1, ...
    'SliderStep',[1/max(1,N-1),min(20/max(1,N-1),1)], ...
    'Callback',@sliderCallback);

frameText = uicontrol(fig, ...
    'Style','text', ...
    'String','Frame: 1', ...
    'Units','normalized', ...
    'Position',[0.075 0.045 0.17 0.04], ...
    'BackgroundColor',[0.035 0.045 0.060], ...
    'ForegroundColor','w', ...
    'FontSize',11, ...
    'HorizontalAlignment','left');

playButton = uicontrol(fig, ...
    'Style','pushbutton', ...
    'String','PLAY', ...
    'Units','normalized', ...
    'Position',[0.255 0.04 0.10 0.055], ...
    'FontSize',11, ...
    'FontWeight','bold', ...
    'Callback',@playPause);

uicontrol(fig, ...
    'Style','pushbutton', ...
    'String','<< PREVIOUS', ...
    'Units','normalized', ...
    'Position',[0.365 0.04 0.11 0.055], ...
    'Callback',@previousFrame);

uicontrol(fig, ...
    'Style','pushbutton', ...
    'String','NEXT >>', ...
    'Units','normalized', ...
    'Position',[0.485 0.04 0.10 0.055], ...
    'Callback',@nextFrame);

uicontrol(fig, ...
    'Style','pushbutton', ...
    'String','RESET', ...
    'Units','normalized', ...
    'Position',[0.595 0.04 0.09 0.055], ...
    'Callback',@resetFrame);

%% ========================= TIMER ==================================
% FIX: keep timer period constant.
% Speed is handled by frame increment in timerCallback().
timerObj = timer( ...
    'ExecutionMode','fixedSpacing', ...
    'Period',TIMER_PERIOD, ...
    'BusyMode','drop', ...
    'TimerFcn',@timerCallback);

%% ========================= INITIAL DISPLAY ========================
updateDisplay();
drawnow;
start(timerObj);

%% ==================================================================
% CALLBACKS
% ==================================================================

    function sliderCallback(src,~)
        currentFrame = round(get(src,'Value'));
        currentFrame = max(1,min(N,currentFrame));
        isPlaying = false;
        set(playButton,'String','PLAY');
        updateDisplay();
    end

    function playPause(~,~)
        isPlaying = ~isPlaying;

        if isPlaying
            set(playButton,'String','PAUSE');
        else
            set(playButton,'String','PLAY');
        end
    end

    function timerCallback(~,~)
        if ~isvalidFigure(fig)
            return;
        end

        if ~isPlaying
            return;
        end

        % FIX:
        % Do NOT modify timerObj.Period here.
        % Change only the number of frames moved per timer tick.
        frameStep = max(1,round(playSpeed * TIMER_PERIOD / dt));

        currentFrame = currentFrame + frameStep;

        if currentFrame >= N
            currentFrame = N;
            isPlaying = false;
            set(playButton,'String','PLAY');
        end

        if isvalidGraphics(slider)
            set(slider,'Value',currentFrame);
        end

        updateDisplay();
    end

    function nextFrame(~,~)
        isPlaying = false;
        set(playButton,'String','PLAY');

        currentFrame = min(N,currentFrame+1);
        set(slider,'Value',currentFrame);
        updateDisplay();
    end

    function previousFrame(~,~)
        isPlaying = false;
        set(playButton,'String','PLAY');

        currentFrame = max(1,currentFrame-1);
        set(slider,'Value',currentFrame);
        updateDisplay();
    end

    function resetFrame(~,~)
        isPlaying = false;
        set(playButton,'String','PLAY');

        currentFrame = 1;
        set(slider,'Value',1);
        updateDisplay();
    end

    function changeMode(src,~)
        poseMode = get(src,'Value');
        updateDisplay();
    end

    function changeSpeed(src,~)
        values = [0.25 0.5 1 2 4 8];
        idx = max(1,min(numel(values),round(get(src,'Value'))));
        playSpeed = values(idx);

        % IMPORTANT:
        % There is intentionally NO:
        %   timerObj.Period = ...
        %
        % This removes the sub-millisecond timer warning.
    end

    function resetCamera(~,~)
        view(ax,135,24);
        axis(ax,'equal');
        xlim(ax,[-6.5 6.5]);
        ylim(ax,[-5.5 7.0]);
        zlim(ax,[-2.5 7.5]);
    end

%% ==================================================================
% DISPLAY
% ==================================================================

    function updateDisplay()
        if ~isvalidFigure(fig)
            return;
        end

        currentFrame = max(1,min(N,currentFrame));

        actual  = actualHistory(currentFrame,:);
        desired = desiredHistory(currentFrame,:);
        target  = targetHistory(currentFrame,:);

        switch poseMode
            case 1
                displayAngles = target;
                poseName = 'GESTURE TARGET';
            case 2
                displayAngles = actual;
                poseName = 'ACTUAL PID';
            otherwise
                displayAngles = (1-BLEND_ALPHA)*actual + ...
                                BLEND_ALPHA*target;
                poseName = 'BLEND';
        end

        displayAngles = clampForVisualization(displayAngles);
        actual = clampForVisualization(actual);
        desired = clampForVisualization(desired);
        target = clampForVisualization(target);

        cla(ax);
        drawHand(ax,displayAngles);

        label = getGestureNumber(currentFrame);
        gestureLabel = getGestureLabel(currentFrame);

        errorDeg = rad2deg(desired-actual);
        rmsError = sqrt(mean(errorDeg.^2));

        set(frameText,'String',sprintf( ...
            'Frame: %d / %d   |   t = %.3f s', ...
            currentFrame,N,(currentFrame-1)*dt));

        infoString = sprintf([ ...
            'PROSTHETIC HAND CONTROLLER\n\n' ...
            'Frame       : %d / %d\n' ...
            'Time        : %.3f sec\n\n' ...
            'Gesture     : %s\n' ...
            'Class       : %s\n\n' ...
            'Pose source : %s\n' ...
            'Output      : Finger Joint Angles\n' ...
            'RMS error   : %.2f deg'], ...
            currentFrame,N,(currentFrame-1)*dt, ...
            gestureLabel,formatLabel(label), ...
            poseName,rmsError);

        set(infoText,'String',infoString);

        angleString = sprintf('FINGER JOINT ANGLES\n\n');

        for i = 1:5
            angleString = sprintf([ ...
                '%s%-8s  Pose: %6.1f deg\n' ...
                '          Actual: %6.1f deg\n' ...
                '          Target: %6.1f deg\n\n'], ...
                angleString,FINGER_NAMES{i}, ...
                rad2deg(displayAngles(i)), ...
                rad2deg(actual(i)), ...
                rad2deg(target(i)));
        end

        set(angleText,'String',angleString);

        title(ax,sprintf('3-D PROSTHETIC HAND - %s',gestureLabel), ...
            'Color','w','FontSize',16,'FontWeight','bold');

        drawnow limitrate;
    end

%% ==================================================================
% GESTURE INFORMATION
% ==================================================================

    function label = getGestureNumber(frame)
        label = NaN;

        if isempty(gestureVector) || frame > numel(gestureVector)
            return;
        end

        value = gestureVector(frame);

        if isnumeric(value) && isscalar(value) && isfinite(value)
            label = double(value);
        end
    end

    function name = getGestureLabel(frame)
        names = gestureNamesDB1();
        label = getGestureNumber(frame);

        if isfinite(label)
            idx = round(label)-LABEL_BASE+1;

            if idx >= 1 && idx <= numel(names)
                name = names{idx};
            else
                name = sprintf('Gesture %g',label);
            end
        else
            name = 'Unknown';
        end
    end

%% ==================================================================
% 3-D HAND
% ==================================================================

    function drawHand(parent,angles)
        % Palm
        [Xs,Ys,Zs] = sphere(40);

        surf(parent, ...
            2.45*Xs, ...
            1.35*Ys, ...
            0.62*Zs-0.15, ...
            'FaceColor',[0.32 0.37 0.43], ...
            'EdgeColor','none');

        % Wrist
        drawBone(parent,[0 0 -0.95],[0 0 -0.05], ...
            0.62,[0.22 0.27 0.32]);

        % Finger base positions
        baseX = [-2.0 -1.0 0 1.0 2.0];
        baseY = [0.15 0 0 0 0.15];
        baseZ = [0.55 0.72 0.82 0.72 0.55];

        lengths = [1.75 2.00 2.15 2.00 1.75];

        % Index, Middle, Ring, Little
        for f = 2:5
            drawFinger(parent, ...
                [baseX(f) baseY(f) baseZ(f)], ...
                lengths(f),angles(f),false,f);
        end

        % Thumb
        drawFinger(parent, ...
            [baseX(1) baseY(1) baseZ(1)], ...
            lengths(1),angles(1),true,1);

        % Wrist/palm connector
        [Xw,Yw,Zw] = sphere(20);
        surf(parent, ...
            0.70*Xw, ...
            0.70*Yw, ...
            0.70*Zw-0.95, ...
            'FaceColor',[0.20 0.24 0.29], ...
            'EdgeColor','none');

        camlight(ax,'headlight');
        camlight(ax,'right');
        lighting(ax,'gouraud');
        material(ax,'dull');
    end

    function drawFinger(parent,base,L,totalAngle,isThumb,fingerIndex)
        % The important change is here:
        % each joint uses a cumulative angle, so the physical joint
        % locations visibly move when the angle changes.

        x0 = base(1);
        y0 = base(2);
        z0 = base(3);

        L1 = 0.40*L;
        L2 = 0.34*L;
        L3 = 0.26*L;

        totalAngle = max(0,min(deg2rad(95),totalAngle));

        % Split one finger command across 3 physical joints.
        a1 = 0.45*totalAngle;
        a2 = 0.35*totalAngle;
        a3 = 0.20*totalAngle;

        p0 = [x0 y0 z0];

        if isThumb
            % Thumb bends toward the palm in the Y-Z plane.
            p1 = p0 + [-0.18 0 0.95*L1];

            q1 = totalAngle;
            q2 = 0.70*totalAngle;
            q3 = 0.35*totalAngle;

            p2 = p1 + [ ...
                -0.20*L2, ...
                -sin(q1)*L2, ...
                 cos(q1)*L2];

            p3 = p2 + [ ...
                -0.16*L3, ...
                -sin(q1+q2)*L3, ...
                 cos(q1+q2)*L3];

            % A small distal offset gives the thumb a visible joint.
            p3 = p3 + [0 -0.05*sin(q3)*L3 0.05*cos(q3)*L3];

        else
            spread = 0.07*(fingerIndex-3);

            p1 = p0 + [0 spread L1];

            q1 = a1;
            q2 = a1+a2;
            q3 = a1+a2+a3;

            p2 = p1 + [ ...
                0, ...
                sin(q1)*L2, ...
                cos(q1)*L2];

            p3 = p2 + [ ...
                0, ...
                sin(q2)*L3, ...
                cos(q2)*L3];
        end

        % Bones
        drawBone(parent,p0,p1,0.23,[0.55 0.59 0.64]);
        drawBone(parent,p1,p2,0.20,[0.48 0.53 0.59]);
        drawBone(parent,p2,p3,0.17,[0.42 0.48 0.55]);

        % Joints
        drawJoint(parent,p0,0.28);
        drawJoint(parent,p1,0.24);
        drawJoint(parent,p2,0.20);
        drawJoint(parent,p3,0.17);
    end

    function drawBone(parent,p1,p2,r,faceColor)
        v = p2-p1;
        Lbone = norm(v);

        if Lbone < 1e-9
            return;
        end

        [Xc,Yc,Zc] = cylinder(r,20);
        Zc = Zc*Lbone;

        direction = v/Lbone;
        zAxis = [0 0 1];

        c = cross(zAxis,direction);
        d = max(-1,min(1,dot(zAxis,direction)));

        if norm(c) < 1e-9
            if d >= 0
                R = eye(3);
            else
                R = diag([1 -1 -1]);
            end
        else
            c = c/norm(c);
            angle = acos(d);

            K = [ ...
                 0     -c(3)  c(2); ...
                 c(3)   0    -c(1); ...
                -c(2)  c(1)  0];

            R = eye(3) + sin(angle)*K + ...
                (1-cos(angle))*(K*K);
        end

        P = R*[Xc(:)';Yc(:)';Zc(:)'];

        X = reshape(P(1,:),size(Xc))+p1(1);
        Y = reshape(P(2,:),size(Yc))+p1(2);
        Z = reshape(P(3,:),size(Zc))+p1(3);

        surf(parent,X,Y,Z, ...
            'FaceColor',faceColor, ...
            'EdgeColor','none');
    end

    function drawJoint(parent,p,r)
        [X,Y,Z] = sphere(18);

        surf(parent, ...
            r*X+p(1), ...
            r*Y+p(2), ...
            r*Z+p(3), ...
            'FaceColor',[0.17 0.21 0.26], ...
            'EdgeColor','none');
    end

%% ==================================================================
% DATA HELPERS
% ==================================================================

    function history = prepareAngleHistory(history)
        if isempty(history) || ~isnumeric(history)
            history = [];
            return;
        end

        history = double(history);

        if size(history,2) == 5
            return;
        end

        if size(history,1) == 5
            history = history';
            return;
        end

        history = [];
    end

    function out = resizeHistory(in,Nout)
        if isempty(in)
            out = zeros(Nout,5);
            return;
        end

        out = zeros(Nout,5);
        n = min(Nout,size(in,1));

        out(1:n,:) = in(1:n,:);

        if n < Nout
            out(n+1:Nout,:) = repmat(in(n,:),Nout-n,1);
        end
    end

    function out = resizeVector(in,Nout)
        out = nan(Nout,1);

        if isempty(in)
            return;
        end

        in = in(:);
        n = min(Nout,numel(in));

        if n > 0
            out(1:n) = in(1:n);

            if n < Nout
                out(n+1:Nout) = in(n);
            end
        end
    end

    function history = convertToRadiansIfNeeded(history)
        if isempty(history)
            return;
        end

        finiteValues = abs(history(isfinite(history)));

        if isempty(finiteValues)
            history(:) = 0;
            return;
        end

        % If values look like degrees, convert to radians.
        if max(finiteValues) > (2*pi+0.25)
            history = deg2rad(history);
        end
    end

    function angles = clampForVisualization(angles)
        angles = double(angles);
        angles(~isfinite(angles)) = 0;

        % Physical visualization range.
        angles(1) = min(max(angles(1),0),deg2rad(80));
        angles(2:5) = min(max(angles(2:5),0),deg2rad(95));
    end

    function v = prepareGestureVector(g)
        v = [];

        if isempty(g)
            return;
        end

        try
            if isnumeric(g) || islogical(g)
                v = double(g(:));
                return;
            end

            if iscell(g)
                v = nan(numel(g),1);

                for ii = 1:numel(g)
                    value = g{ii};

                    if isnumeric(value) && isscalar(value)
                        v(ii) = double(value);
                    elseif isstring(value) || ischar(value)
                        n = str2double(string(value));

                        if isfinite(n)
                            v(ii) = n;
                        end
                    end
                end
            end
        catch
            v = [];
        end
    end

    function result = getVariableRecursive(root,names)
        result = [];

        if ~isstruct(root)
            return;
        end

        fields = fieldnames(root);

        % First search current level.
        for ii = 1:numel(names)
            for jj = 1:numel(fields)
                if strcmpi(fields{jj},names{ii})
                    value = root.(fields{jj});

                    if (isnumeric(value) || islogical(value) || ...
                            iscell(value)) && ~isempty(value)
                        result = value;
                        return;
                    end
                end
            end
        end

        % Then recursively search structures.
        for jj = 1:numel(fields)
            value = root.(fields{jj});

            if isstruct(value)
                result = getVariableRecursive(value,names);

                if ~isempty(result)
                    return;
                end
            end
        end
    end

    function tf = isvalidFigure(h)
        tf = false;

        try
            tf = ~isempty(h) && isgraphics(h,'figure');
        catch
            tf = false;
        end
    end

    function tf = isvalidGraphics(h)
        tf = false;

        try
            tf = ~isempty(h) && isgraphics(h);
        catch
            tf = false;
        end
    end

    function txt = formatLabel(label)
        if isfinite(label)
            txt = sprintf('%g',label);
        else
            txt = 'N/A';
        end
    end

%% ==================================================================
% DB1 GESTURE -> HAND POSE
% ==================================================================

    function pose = gestureToPose(label,labelBase)
        % [Thumb Index Middle Ring Little], degrees.
        %
        % These are visualization target angles.
        % They provide a visible prosthetic-hand pose for each DB1 class.

        poseDeg = [0 0 0 0 0];

        if ~isfinite(label)
            pose = deg2rad(poseDeg);
            return;
        end

        idx = round(label)-labelBase;

        switch idx
            case 0
                poseDeg = [0 0 0 0 0];              % Rest
            case 1
                poseDeg = [0 65 0 0 0];             % Index flexion
            case 2
                poseDeg = [0 5 0 0 0];              % Index extension
            case 3
                poseDeg = [0 0 65 0 0];             % Middle flexion
            case 4
                poseDeg = [0 0 5 0 0];              % Middle extension
            case 5
                poseDeg = [0 0 0 65 0];             % Ring flexion
            case 6
                poseDeg = [0 0 0 5 0];              % Ring extension
            case 7
                poseDeg = [0 0 0 0 65];             % Little flexion
            case 8
                poseDeg = [0 0 0 0 5];              % Little extension
            case 9
                poseDeg = [35 0 0 0 0];             % Thumb adduction
            case 10
                poseDeg = [0 0 0 0 0];              % Thumb abduction
            case 11
                poseDeg = [65 0 0 0 0];             % Thumb flexion
            case 12
                poseDeg = [5 0 0 0 0];              % Thumb extension
            case 13
                poseDeg = [15 0 0 0 0];             % Thumb up
            case 14
                poseDeg = [0 5 5 0 0];              % Index + middle
            case 15
                poseDeg = [0 0 0 65 65];            % Ring + little
            case 16
                poseDeg = [65 0 0 0 65];            % Thumb + little
            case 17
                poseDeg = [0 0 0 0 0];              % All fingers open
            case 18
                poseDeg = [65 70 70 70 70];         % Fist
            case 19
                poseDeg = [45 5 70 70 70];          % Pointing index
            case 20
                poseDeg = [0 5 5 5 5];              % Extended adduction
            case 21
                poseDeg = [0 0 0 0 0];              % Wrist supination
            case 22
                poseDeg = [0 0 0 0 0];              % Wrist pronation
            case 23
                poseDeg = [0 0 0 0 0];              % Wrist axis
            case 24
                poseDeg = [0 0 0 0 0];              % Wrist axis
            case 25
                poseDeg = [20 20 20 20 20];         % Wrist flexion
            case 26
                poseDeg = [0 0 0 0 0];              % Wrist extension
            case 27
                poseDeg = [0 0 0 0 0];              % Radial deviation
            case 28
                poseDeg = [0 0 0 0 0];              % Ulnar deviation
            case 29
                poseDeg = [60 65 65 65 65];         % Closed hand
            case 30
                poseDeg = [45 50 50 50 50];         % Large diameter grasp
            case 31
                poseDeg = [55 60 60 60 60];         % Small diameter grasp
            case 32
                poseDeg = [65 70 70 0 70];          % Hook grasp
            case 33
                poseDeg = [35 5 60 60 60];          % Index extension grasp
            case 34
                poseDeg = [55 60 60 60 60];         % Medium wrap
            case 35
                poseDeg = [45 35 35 70 35];         % Ring grasp
            case 36
                poseDeg = [45 60 60 60 60];         % Four finger grasp
            case 37
                poseDeg = [50 55 55 55 55];         % Stick grasp
            case 38
                poseDeg = [50 65 65 15 15];         % Writing tripod
            case 39
                poseDeg = [55 65 65 65 65];         % Power sphere
            case 40
                poseDeg = [50 60 60 15 15];         % Three finger sphere
            case 41
                poseDeg = [45 55 55 10 10];         % Precision sphere
            case 42
                poseDeg = [50 65 65 10 10];         % Tripod
            case 43
                poseDeg = [55 50 50 5 5];           % Prismatic pinch
            case 44
                poseDeg = [65 35 35 5 5];            % Tip pinch
            case 45
                poseDeg = [55 55 55 55 5];          % Quadpod
            case 46
                poseDeg = [60 35 35 35 5];          % Lateral grasp
            case 47
                poseDeg = [0 5 5 5 5];              % Parallel extension
            case 48
                poseDeg = [15 10 10 10 10];         % Extension type
            case 49
                poseDeg = [50 60 60 60 60];         % Power disk
            case 50
                poseDeg = [40 45 45 45 45];         % Open bottle
            case 51
                poseDeg = [35 40 40 40 40];         % Turn screw
            case 52
                poseDeg = [50 60 60 60 60];         % Cut with knife
            otherwise
                poseDeg = [0 0 0 0 0];
        end

        pose = deg2rad(poseDeg);
    end

%% ==================================================================
% DB1 GESTURE NAMES
% ==================================================================

    function names = gestureNamesDB1()
        names = { ...
            'Rest'
            'Index Flexion'
            'Index Extension'
            'Middle Flexion'
            'Middle Extension'
            'Ring Flexion'
            'Ring Extension'
            'Little Finger Flexion'
            'Little Finger Extension'
            'Thumb Adduction'
            'Thumb Abduction'
            'Thumb Flexion'
            'Thumb Extension'
            'Thumb Up'
            'Index + Middle Extension'
            'Ring + Little Flexion'
            'Thumb Opposing Little Finger'
            'All Fingers Abduction'
            'Fist'
            'Pointing Index'
            'Extended Fingers Adduction'
            'Wrist Supination'
            'Wrist Pronation'
            'Wrist Supination - Little Finger Axis'
            'Wrist Pronation - Little Finger Axis'
            'Wrist Flexion'
            'Wrist Extension'
            'Wrist Radial Deviation'
            'Wrist Ulnar Deviation'
            'Wrist Extension Closed Hand'
            'Large Diameter Grasp'
            'Small Diameter Grasp'
            'Fixed Hook Grasp'
            'Index Finger Extension Grasp'
            'Medium Wrap Grasp'
            'Ring Grasp'
            'Prismatic Four Finger Grasp'
            'Stick Grasp'
            'Writing Tripod Grasp'
            'Power Sphere Grasp'
            'Three Finger Sphere Grasp'
            'Precision Sphere Grasp'
            'Tripod Grasp'
            'Prismatic Pinch Grasp'
            'Tip Pinch Grasp'
            'Quadpod Grasp'
            'Lateral Grasp'
            'Parallel Extension Grasp'
            'Extension Type Grasp'
            'Power Disk Grasp'
            'Open Bottle'
            'Turn Screw'
            'Cut with Knife'};
    end

%% ==================================================================
% CLOSE
% ==================================================================

    function closeFigure(~,~)
        isPlaying = false;

        try
            if ~isempty(timerObj) && isvalid(timerObj)
                stop(timerObj);
                delete(timerObj);
            end
        catch
        end

        if isvalidFigure(fig)
            delete(fig);
        end
    end

end