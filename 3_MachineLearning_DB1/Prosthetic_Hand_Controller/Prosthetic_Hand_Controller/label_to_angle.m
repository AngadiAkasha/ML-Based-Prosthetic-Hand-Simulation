function angles = label_to_angle(label)
%LABEL_TO_ANGLE  Embedded MATLAB Function block: gesture label -> finger angles.
%
%   angles = label_to_angle(label)
%
%   Converts one discrete Random-Forest predicted gesture label (Ninapro
%   DB1 convention, classes 0-23 exactly as trained in trainRandomForest.m
%   / stored in RF_Model.mat) into a 5-element vector of finger joint
%   angle setpoints, in RADIANS, ordered:
%
%       [Thumb  Index  Middle  Ring  Little]
%
%   This table is IDENTICAL to gestureToPose() inside your existing
%   visualizeRandomForest.m, so the controller's desired-angle trajectory
%   and the 3-D visualizer always agree on what each class looks like.
%   Drop this straight into a Simulink "MATLAB Function" block (Fig. 6 of
%   the paper) between the "From Workspace" (predicted labels) block and
%   the PID controller.
%
%#codegen

    poseDeg = zeros(1,5);
    idx = round(label);

    switch idx
        case 0,  poseDeg = [0  0  0  0  0];    % Rest
        case 1,  poseDeg = [0  65 0  0  0];    % Index flexion
        case 2,  poseDeg = [0  5  0  0  0];    % Index extension
        case 3,  poseDeg = [0  0  65 0  0];    % Middle flexion
        case 4,  poseDeg = [0  0  5  0  0];    % Middle extension
        case 5,  poseDeg = [0  0  0  65 0];    % Ring flexion
        case 6,  poseDeg = [0  0  0  5  0];    % Ring extension
        case 7,  poseDeg = [0  0  0  0  65];   % Little flexion
        case 8,  poseDeg = [0  0  0  0  5];    % Little extension
        case 9,  poseDeg = [35 0  0  0  0];    % Thumb adduction
        case 10, poseDeg = [0  0  0  0  0];    % Thumb abduction
        case 11, poseDeg = [65 0  0  0  0];    % Thumb flexion
        case 12, poseDeg = [5  0  0  0  0];    % Thumb extension
        case 13, poseDeg = [15 0  0  0  0];    % Thumb up
        case 14, poseDeg = [0  5  5  0  0];    % Index + middle extension
        case 15, poseDeg = [0  0  0  65 65];   % Ring + little flexion
        case 16, poseDeg = [65 0  0  0  65];   % Thumb opposing little finger
        case 17, poseDeg = [0  0  0  0  0];    % All fingers abduction (open)
        case 18, poseDeg = [65 70 70 70 70];   % Fist
        case 19, poseDeg = [45 5  70 70 70];   % Pointing index
        case 20, poseDeg = [0  5  5  5  5];    % Extended fingers adduction
        case 21, poseDeg = [0  0  0  0  0];    % Wrist supination
        case 22, poseDeg = [0  0  0  0  0];    % Wrist pronation
        case 23, poseDeg = [0  0  0  0  0];    % Wrist supination - little finger axis
        otherwise, poseDeg = [0 0 0 0 0];      % unseen label -> hold rest pose
    end

    angles = deg2rad(poseDeg);
end
